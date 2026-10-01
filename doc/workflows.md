# Current CI and Dependabot setup

This report describes the GitHub Actions workflow and Dependabot configuration as they exist today. It is a snapshot for future Dart work in this repository. The files analyzed are [`.github/workflows/dart.yml`](../.github/workflows/dart.yml) and [`.github/dependabot.yml`](../.github/dependabot.yml).

## Project context

[`pubspec.yaml`](../pubspec.yaml) is a pure Dart command-line application:

- Package name: `ascii_renderer`
- Version: `1.0.0`
- SDK constraint: `^3.13.4` (lockfile `>=3.13.4 <4.0.0`)
- Runtime dependencies: `image`, `path`
- Dev dependencies: `lints`, `test`
- Lint config: [`analysis_options.yaml`](../analysis_options.yaml) includes `package:lints/recommended.yaml`

The entrypoint [`bin/ascii_renderer.dart`](../bin/ascii_renderer.dart) imports `dart:io` and reads a local image. A local artifact at `build/cli/windows_x64/bundle/bin/ascii_renderer.exe` matches the bundle layout of `dart build cli` (available since Dart 3.9). The workflow does not produce that artifact.

## Workflow: Dart

File: [`.github/workflows/dart.yml`](../.github/workflows/dart.yml)

Name: `Dart`

The file header notes that `dart-lang/setup-dart` is a third-party action.

### Triggers

The workflow runs on `push` and `pull_request` when the branch is one of:

- `main`
- `feature/**`
- `bugfix/**`

There is no `workflow_dispatch`, tag trigger, or `schedule`. A pull request into `main` runs the workflow. A push of a release tag does not.

### Jobs

There is a single job, `build`. The name describes a compile step. The steps that actually run are dependency install, format check, static analysis, and tests.

```yaml
strategy:
  fail-fast: false
  matrix:
    dart: [stable]
    os: [ubuntu-latest, windows-latest, macos-latest]
runs-on: ${{ matrix.os }}
```

| Matrix key | Values | Effect |
| --- | --- | --- |
| `os` | `ubuntu-latest`, `windows-latest`, `macos-latest` | Each combination is a separate runner. One OS failing does not cancel the others (`fail-fast: false`). |
| `dart` | `stable` | Declared only. No step reads `matrix.dart`. |

`dart-lang/setup-dart` is invoked without a `with:` block, so it installs its default SDK (the latest stable). The `dart` matrix entry does not select that SDK. Adding `beta` to the matrix would still install stable until a step passes `sdk: ${{ matrix.dart }}`.

The job has no `permissions`, `concurrency`, or `timeout-minutes`. On a repository that still uses the default `GITHUB_TOKEN` permissions, the token is broader than this job needs. A new push to the same branch does not cancel the previous run.

### Steps

Every matrix cell runs the same sequence:

1. `actions/checkout@v4` checks out the ref. This is a moving major tag.
2. `dart-lang/setup-dart@9a04e6d73cca37bd455e0608d7e5092f881fd603` installs the Dart SDK. The pin is a full commit SHA, which is the stronger form of pin. The step has no trailing version comment (for example `# v1.7.0`), so a reader cannot see which release that SHA came from. A commented alternative, `dart-lang/setup-dart@v1`, sits above the live step and is not used.
3. `dart pub get` resolves dependencies from [`pubspec.lock`](../pubspec.lock). The pub cache is not restored from a previous run.
4. `dart format --output=none --set-exit-if-changed .` fails the job when any Dart file differs from `dart format`. The comment above the step still says "Uncomment this step", but the step is already active.
5. `dart analyze --fatal-infos` fails on analyzer errors, warnings, and infos. The comment above the step still says "Consider passing `--fatal-infos`", but the flag is already present. Rules come from `package:lints/recommended.yaml`.
6. `dart test` runs the suites under `test/`. The project depends on `package:test`, so this step is valid. The comment about switching to `flutter test` does not apply to this package.

Format and analyze are SDK-level checks. They run once per operating system, so each push or pull request pays for three identical format runs and three identical analyze runs. Test runs on three operating systems are useful, because path handling and `dart:io` behavior differ by OS. There is no compile step, so the workflow never exercises `dart build cli` or `dart compile exe`, and it uploads no artifacts.

### Gaps relative to a reference CLI pipeline

- The `dart` matrix axis is unused.
- Format and analysis are repeated on Windows and macOS.
- Nothing compiles a native executable or bundle.
- Nothing caches `dart pub get`.
- Third-party actions are mixed: `setup-dart` is SHA-pinned without a version comment; `checkout` floats on `@v4`.
- Template comments describe steps as optional or suggested after those steps were turned on.
- No explicit token permissions, concurrency cancellation, or job timeout.

## Dependabot

File: [`.github/dependabot.yml`](../.github/dependabot.yml)

Config version: `2`

Two update entries, both rooted at `/` and both on a weekly schedule:

| Ecosystem | Manifest it watches | Schedule |
| --- | --- | --- |
| `pub` | [`pubspec.yaml`](../pubspec.yaml) | weekly |
| `github-actions` | workflow `uses:` references | weekly |

What this already covers:

- Pub hosted dependencies, including direct packages (`image`, `path`, `lints`, `test`) and the transitive graph recorded in the lockfile.
- GitHub Actions used by the workflow. Dependabot can move a commit SHA pin forward. It can also bump the moving `actions/checkout@v4` tag when a newer major is something it proposes separately from in-place v4 updates.

What the file leaves at Dependabot defaults:

- No `groups`, so each pub package and each action can open its own pull request.
- No `labels`.
- No `reviewers` or `assignees`.
- No `commit-message` prefix, so automated commits do not follow a project convention.
- No `open-pull-requests-limit` (Dependabot's own default is 5 per ecosystem).
- No `ignore` rules and no `allow` rules. Major, minor, and patch updates are all eligible.
- No `cooldown`.

Security updates are separate from this version-update file. They are controlled in the repository's GitHub security settings, not in `dependabot.yml`.

## Summary

The current pipeline installs the latest stable Dart SDK and runs format, `dart analyze --fatal-infos`, and `dart test` on Ubuntu, Windows, and macOS. That is a sound default smoke check for a small Dart package. For a CLI reference project it still treats compilation as out of band, repeats platform-independent checks, and leaves the SDK matrix, token permissions, caching, and Dependabot pull-request hygiene unset.
