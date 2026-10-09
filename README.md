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

## TODO List

- [x] Fix font used for classification (arial does not fully support CP437)
- [x] Generate native executable.
- [x] Add command line flags to provide input and output paths at runtime.
- [x] Add command line flags to customize ASCII character sets to use: basic, extended, cp437.
- [ ] Decide whether to add color output
- [ ] Check out Dart argument parsing libraries to use
- [ ] Option for no file output
