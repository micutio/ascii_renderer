# ASCII Renderer

A command line application to convert an image to ASCII art.

## Usage

From the project directory:

```
dart run bin/ascii_renderer.dart --input input.jpg --output output.txt --cols 80 --contrast 1.0
```

- `--input` defaults to `input.jpg`
- `--output` defaults to `output.txt`
- `--font` defaults to `assets/font/iosevka.png`
- `--char_ratio` defaults to `1 2` (1x2 width by height ratio of the font characters)
- `--cols` defaults to `240`
- `--contrast` defaults to `1.0` (1.0 is normal, >1.0 = sharper edges)
- `--charset` defaults to `ascii` (possible values: `ascii`, `extended`, `cp437`)
- `--help` prints the same options.

## Character matching

Glyph and image-cell vectors use absolute sampled luminance from `0.0` to `1.0`; the selected charset does not rescale those values. Matching combines mean-density error (weight `0.35`) with the total-variation distance between normalized six-region shapes (weight `0.65`). These weights are fixed internally.

`--contrast` raises each sampled image-region luminance to the specified exponent before matching. The default `1.0` leaves samples unchanged; values above `1.0` emphasize brighter regions and sharpen the matched structure.

## TODO List

- [x] Fix font used for classification (arial does not fully support CP437)
- [x] Generate native executable.
- [x] Add command line flags to provide input and output paths at runtime.
- [x] Add command line flags to customize ASCII character sets to use: basic, extended, cp437.
- [ ] Decide whether to add color output
- [ ] Check out Dart argument parsing libraries to use
- [ ] Option for no file output
