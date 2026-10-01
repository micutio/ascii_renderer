# Further CI improvements

Items 1 through 6 below are applied on top of the job split in [enhanced_workflow.md](enhanced_workflow.md). The smoke test in item 7 is still skipped: the entrypoint does not accept input and output paths, so a CI run cannot point the binary at a generated one-pixel image. `font/iosevka.png` is already in the repo. Item 8 remains optional.

Apply them in the order below. Each item names the file to change and why it belongs in a reference project.

## 1. Least privilege, cancellation, and timeouts

File: [`.github/workflows/dart.yml`](../.github/workflows/dart.yml)

The workflow never sets `permissions`, so the job token keeps the repository default. CI only needs to read the checkout and upload artifacts.

```yaml
permissions:
  contents: read

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

Put `timeout-minutes: 15` on `format`, `analyze`, `test`, and `build`. A hung `dart test` or a stuck pub download then fails the job instead of holding a runner until the GitHub limit.

`contents: read` still allows `actions/upload-artifact`, which uses the separate Actions artifact API. The release workflow is the job that needs `contents: write`, and that permission stays on the publish job only. See [release_workflow.md](release_workflow.md).

## 2. An SDK axis that the setup step actually uses

The split already passes `sdk` into `dart-lang/setup-dart`. Keep the required pull-request checks on a single channel:

- `stable`, or
- `3.13`, which tracks the `^3.13.4` constraint in [`pubspec.yaml`](../pubspec.yaml)

Add a second workflow, or a second job guarded by `if: github.event_name == 'schedule'`, that installs `sdk: beta`. Schedule it weekly. Beta failures should not block merges. They show that the next stable SDK is about to break the package while there is still time to fix it.

```yaml
on:
  schedule:
    - cron: "0 6 * * 1"
```

Do not add `beta` to the matrix that pull requests require. A red beta job on every pull request trains people to ignore required checks.

Applied as [`.github/workflows/dart-beta.yml`](../.github/workflows/dart-beta.yml). Pull-request checks stay on `sdk: stable`. The beta workflow runs format, analyze, test, and build on Ubuntu every Monday at 06:00 UTC. Job names are suffixed `(beta)` so they stay distinct from the required stable checks.

## 3. Cache the pub cache

`dart pub get` currently downloads the graph on every job and every OS. Cache the pub cache and key it by OS and lockfile:

```yaml
- name: Cache pub dependencies
  uses: actions/cache@v4
  with:
    path: ~/.pub-cache
    key: pub-${{ runner.os }}-${{ hashFiles('pubspec.lock') }}
    restore-keys: pub-${{ runner.os }}-
```

On Windows the pub cache lives under the user profile, not `~/.pub-cache`. Use a small matrix include, or:

```yaml
path: ${{ runner.os == 'Windows' && '~\\AppData\\Local\\Pub\\Cache' || '~/.pub-cache' }}
```

A local Windows run confirmed the pub cache at `%LOCALAPPDATA%\Pub\Cache` (`~/AppData/Local/Pub/Cache`). The workflow uses that path on Windows and `~/.pub-cache` elsewhere. A wrong path is a cache miss, and the job still succeeds via `dart pub get`.

Commit [`pubspec.lock`](../pubspec.lock) (it is already in the tree) so the cache key is stable and CI resolves the same versions as local development.

## 4. Pin actions to a SHA and leave a version comment

`dart-lang/setup-dart` is already pinned to `9a04e6d73cca37bd455e0608d7e5092f881fd603`. Add the release tag in a comment on that line so reviewers can see what moved when Dependabot updates the SHA:

```yaml
- uses: dart-lang/setup-dart@9a04e6d73cca37bd455e0608d7e5092f881fd603 # v1.0.0
```

That commit is the `v1.0.0` tag. `actions/checkout` is pinned to `v4.4.0`, `actions/upload-artifact` to `v4.6.2`, and `actions/cache` to `v4.3.0`.

Pin `actions/checkout` and `actions/upload-artifact` the same way. A floating `@v4` tag moves when the maintainer retags it. Dependabot's `github-actions` ecosystem updates SHA pins, which is why the comment matters: the pull request diff shows both the new SHA and the new version.

## 5. Make Dependabot pull requests reviewable

File: [`.github/dependabot.yml`](../.github/dependabot.yml)

Keep both ecosystems (`pub` and `github-actions`) and the weekly schedule. Add grouping, labels, a commit prefix, and an open-PR cap.

Group pub patch and minor updates into one pull request. Leave major updates ungrouped so each breaking bump has its own diff and changelog link.

```yaml
version: 2
updates:
  - package-ecosystem: pub
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
    labels:
      - dependencies
    commit-message:
      prefix: "chore"
      include: scope
    groups:
      pub-minor-and-patch:
        update-types:
          - minor
          - patch

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
    labels:
      - dependencies
    commit-message:
      prefix: "chore"
      include: scope
    groups:
      github-actions:
        patterns:
          - "*"
```

Major pub updates still open as individual pull requests because they are outside `pub-minor-and-patch`. Add `reviewers` only after the repository has a person or team that should be on every dependency pull request.

## 6. Ignore build output and name the executable

[`.gitignore`](../.gitignore) ignores `.dart_tool/` and does not ignore `build/`. `dart build cli` writes `build/cli/<target>/bundle/`. Add:

```
build/
```

That keeps compiled bundles out of commits. CI uploads them as artifacts instead.

[`pubspec.yaml`](../pubspec.yaml) has no `executables` map, so `dart install ascii_renderer` has no command name to put on `PATH`. Add:

```yaml
executables:
  ascii_renderer: ascii_renderer
```

The key is the command users type. The value is the file `bin/ascii_renderer.dart` without the extension. This matches the distribution story in the Dart CLI docs (`dart install` calls `dart build cli`). It does not change the GitHub Release archives planned in [release_workflow.md](release_workflow.md).

## 7. Smoke-test the binary after the font asset exists

`dart build cli` proves the compiler accepts the program. It does not prove the bundle starts.

The entrypoint loads `./font/iosevka.png` (already tracked, next to `font/courier.png`) and returns immediately when `input.jpg` is missing. After `dart build cli`, run the bundle with `--help` or a tiny fixture image.

Until the entrypoint accepts input and output paths (already listed in the README TODO), the smoke test has to run with the working directory set to a fixture folder that contains both the font and a sample image. Skip the smoke step rather than checking in a multi-megabyte `input.jpg` solely to satisfy CI. A one-pixel JPEG generated in the job is enough once paths are configurable.

## 8. Optional follow-ups

These are useful once the items above are in place. They are not required for the first reference pipeline.

### Coverage

`dart test --coverage=coverage` writes a coverage directory. A later step can convert it with `dart pub global run coverage:format_coverage` and upload an `lcov` artifact from the Ubuntu test job only. One OS is enough; line coverage does not change across Windows and macOS for this package.

### Dependency review on pull requests

`actions/dependency-review-action` comments on pull requests that change [`pubspec.yaml`](../pubspec.yaml) or the lockfile. It needs Dependency graph enabled on the repository. It complements Dependabot: Dependabot opens update pull requests, and dependency review inspects any pull request that bumps versions.

### Reuse CI from the release workflow

After the job split is stable, add `workflow_call` to `dart.yml` (or extract the test and build jobs into a reusable workflow). [release_workflow.md](release_workflow.md) then calls that workflow instead of copying `dart test` and `dart build cli`. One definition of "tested on three operating systems" stays in force for both pull requests and tags.

### Branch protection

On `main`, require the four check names from the split (`Format`, `Analyze`, `Test` for each OS, `Build` for each OS) and require Dependabot pull requests to pass the same checks. Tag pushes that publish a release should run the release workflow described in the release plan, which re-runs tests before it uploads binaries.
