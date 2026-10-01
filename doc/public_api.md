# A stable public API for ascii_renderer

This report describes the library contract to settle before `dart pub publish`. It is a design note, not a change to the code. The binary release in [release_workflow.md](release_workflow.md) does not need this work. A pub.dev release does, because version `1.0.0` in [`pubspec.yaml`](../pubspec.yaml) means other packages may depend on the signatures below.

The package today is a command-line application that happens to keep its implementation in `lib/`. Publishing it makes that implementation a supported API.

## What counts as public

A caller writes:

```dart
import 'package:ascii_renderer/ascii_renderer.dart';
```

Everything that import can name is the public API. That is the file [`lib/ascii_renderer.dart`](../lib/ascii_renderer.dart) and anything it `export`s. This package exports nothing else. [`lib/src/vector6.dart`](../lib/src/vector6.dart) and [`lib/src/character_shape.dart`](../lib/src/character_shape.dart) are implementation files.

Dart privacy is per library, not per folder. A name that starts with `_` is visible only inside the library that declares it. `lib/src/` is a convention. The analyzer does not stop another package from importing `package:ascii_renderer/src/vector6.dart`. The tests already do:

| File | Imports |
| --- | --- |
| [`test/ascii_renderer_test.dart`](../test/ascii_renderer_test.dart) | the public library and `src/vector6.dart` |
| [`test/vector6_test.dart`](../test/vector6_test.dart) | `src/vector6.dart` only |
| [`test/character_shape_test.dart`](../test/character_shape_test.dart) | `src/character_shape.dart` and `src/vector6.dart` |
| [`bin/ascii_renderer.dart`](../bin/ascii_renderer.dart) | the public library only |

After publication, those `src` imports are still possible. They are not part of the contract. The readme, the dartdoc, and the changelog should describe only the public library. A breaking change inside `src/` is a patch or minor release as long as the public signatures and their observable results stay the same.

## Current public surface

[`AsciiRenderer`](../lib/ascii_renderer.dart) is the only public type. These members have no `_` prefix, so they are public:

| Member | Role today |
| --- | --- |
| `AsciiRenderer()` | Empty object. Rendering before a setup call has no character shapes to match against. |
| `quantizationSteps` | Cache-key resolution. A public constant, so changing `15` is a breaking change if anyone reads it. |
| `charset` | The 256 CP437 characters the matcher uses. |
| `initialize()` | Builds shapes from `charset` with `package:image`'s built-in Arial 24 font. |
| `initializeFromBitmap(String pathToFontPng)` | Builds shapes from a 16×16 font sheet on disk. Uses `dart:io`. Returns normally when the file cannot be decoded. |
| `render(Image image, int columns, int rows, double contrastExponent)` | Returns one ASCII line per row, each line ending in a newline. |

`render` and `initializeFromBitmap` have no `///` docs. `initialize` and the two constants do. Undocumented public members are still public.

`bin/ascii_renderer.dart` is not part of the library API. Its flags, default paths, and exit codes can change without a major library bump.

## Why this surface is not ready to freeze

Publishing `1.0.0` as it stands promises all of the following.

**Setup is a second step.** Callers can construct an `AsciiRenderer` and call `render` without `initialize` or `initializeFromBitmap`. They can also call both setup methods. A stable API finishes setup in the constructor so a value of the type is ready to render.

**Two setup methods are two contracts.** `initialize` uses Arial 24 and ignores glyphs that font cannot draw. The README still lists that as unfinished. `initializeFromBitmap` reads a PNG through `dart:io`. Supporting both means a web or Wasm package cannot import this library, and dropping either method later is a major bump.

**Algorithm knobs look like features.** `charset` and `quantizationSteps` are how the matcher is tuned. The README still has an open item for choosing characters from the command line. Until that is a product feature, exposing `charset` forces a major bump for a character-list change. `quantizationSteps` is a cache detail. Callers should not read it.

**`render` takes a `package:image` `Image`.** Every dependent also depends on `image`. A breaking change in that type is a breaking change here. That coupling is reasonable if image-in, text-out is the product. It should be an explicit choice, written down next to the `image` version constraint, not an accident of the current import.

**`initializeFromBitmap` hides failure.** A missing file throws from `File.readAsBytesSync`. An undecodable file returns and leaves the renderer empty. Callers cannot tell those outcomes apart from success except by rendering and inspecting the string. A stable method either throws a documented exception or returns a fully initialized object.

**`rows` is required even when the CLI derives it.** The binary computes row count from the image aspect ratio. Library callers must repeat that arithmetic. If aspect-correct output is part of the promise, the library should offer it. If callers always pass both dimensions, document that `columns` and `rows` are the cell grid, not the image size in pixels.

## Proposed contract

One type, constructed already set up, with one render operation.

```dart
import 'package:image/image.dart';

/// Renders an image as ASCII text using a fixed CP437 character set.
///
/// The library reads font bitmaps from disk and is not available on web or Wasm.
class AsciiRenderer {
  /// Shapes taken from the built-in Arial 24 font.
  AsciiRenderer();

  /// Shapes taken from a 16×16 CP437 font sheet at [fontBitmapPath].
  ///
  /// Throws [FileSystemException] when the file is missing and
  /// [FormatException] when it is not a decodable image.
  AsciiRenderer.fromFontBitmap(String fontBitmapPath);

  /// Render [image] into [columns] of ASCII.
  ///
  /// When [rows] is omitted, the row count keeps the image aspect ratio
  /// for a monospace cell that is twice as tall as it is wide.
  /// [contrast] is `1.0` for the sampled darkness and higher to sharpen edges.
  ///
  /// The result is [rows] lines separated by `\n`, including a trailing newline.
  String render(
    Image image, {
    required int columns,
    int? rows,
    double contrast = 1.0,
  });
}
```

That is the whole promise:

- Callers receive a ready renderer. There is no `initialize` step.
- `charset` and `quantizationSteps` stay inside the library. A constructor argument for a custom character set waits until the CLI flag for that exists and the tests describe its behavior.
- `rows == null` matches what the CLI already does. Passing `rows` remains available for a fixed grid.
- `contrast` defaults to `1.0`. The CLI may keep passing `10.0`; that default is a program choice, not a library one.
- Font-sheet layout (16×16, index order matching the private character table) is part of `fromFontBitmap` and must be documented on that constructor.
- The return value is a `String` of lines. Changing the trailing newline, the line ending, or the column count is a breaking change.

`Vector6` and `CharacterShape` stay in `lib/src/`. They are not exported. Fields and helpers that are not in the sketch above get a `_` prefix or move into `src/`.

## Platform and dependencies

State this in the library doc comment and in the pubspec description:

- The package uses `dart:io` because `fromFontBitmap` reads a file. It is a native library. Web and Wasm importers are out of scope.
- The render input is `package:image`'s `Image`. The pubspec constraint on `image` is part of the public contract. Widen or bump it only when the `Image` type this method needs is still the one callers pass.

`bin/` may keep parsing flags and calling this API. Publishing does not require the CLI flags to stay stable, but the changelog should still mention user-visible CLI changes so binary releases and library releases stay understandable under the same version number.

## Documentation and tests

Every public member needs a `///` comment that states what the caller observes: arguments, units, thrown exceptions, and the shape of the returned string. Dartdoc on pub.dev is generated from those comments. Comments that only describe the current implementation (`quantizationSteps`, the cache map) belong on private members.

Tests that protect the contract import only `package:ascii_renderer/ascii_renderer.dart`. They should cover:

- `AsciiRenderer()` renders a known small image to a stable string, or at least to the expected line count and line width.
- `AsciiRenderer.fromFontBitmap` throws when the path is missing and when the bytes are not an image.
- `render` with explicit `rows` returns that many lines.
- `render` without `rows` picks a positive row count from the aspect ratio.
- `contrast` does not change the dimensions of the result.

Tests for `Vector6` and `CharacterShape` can keep importing `src/`. They guard the implementation. They do not define the version promise. New tests for the public behavior should not need those imports.

## Versioning

Use the major version for breaks to the contract above.

| Change | Version bump |
| --- | --- |
| Rename `render`, remove `fromFontBitmap`, change the thrown type, drop the trailing newline, or change which characters can appear | Major |
| Add an optional named argument, or a new constructor, without changing existing calls | Minor |
| Fix a crash or a wrong character while keeping dimensions and the documented character set | Patch |
| Rename `Vector6`, retune the 6D sample, or change `quantizationSteps` while public output stays within the documented contract | Patch |
| Change `--input` / `--output` behavior in the CLI | Not a library break. Mention it in the changelog. |

Do not publish the current `1.0.0` and then immediately reshape the constructors. Ship the first pub.dev release only after the public file matches the contract. Until then the changelog can keep `1.0.0` as the application version used by GitHub Release binaries.

## Checklist before `dart pub publish`

1. Replace the two-step setup with the constructors in the sketch, and make failed font loads throw.
2. Move `charset` and `quantizationSteps` out of the public library, unless a custom character set is accepted as a documented feature.
3. Write `///` docs for the class and `render`.
4. Add contract tests that import only the public library.
5. Set `description` to the library's purpose, and set `repository` (it is still commented out in the pubspec).
6. Add a `LICENSE` file. pub.dev rejects a package without one.
7. Note in the changelog that `1.x` is the first supported library API, separate from earlier CLI-only tags if those tags were already published as binaries.

The binary workflow can ship before this list is done. The library job should wait until the list is done, then publish the same `v*.*.*` tag.
