# ASCII Renderer

A command line application to convert an image to ASCII art.

## Usage

From the project directory:

```
dart run bin/ascii_renderer.dart --input input.jpg --output output.txt
```

`--input` defaults to `input.jpg`, `--output` defaults to `output.txt`, and `--font` defaults to `font/iosevka.png`. `--help` prints the same options.

## TODO List

- [ ] Fix font used for classification (arial does not fully support CP437)
- [ ] Generate native executable.
- [x] Add command line flags to provide input and output paths at runtime.
- [ ] Add command line flags to customize ASCII characters to use.
