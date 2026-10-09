import 'dart:io';

import 'package:ascii_renderer/ascii_renderer.dart';
import 'package:image/image.dart' as img;

import 'src/option.dart';

const _usage = '''
Render an image as ASCII art.

Usage: ascii_renderer [options]

Options:
  --input <path>       Image to render. Defaults to input.jpg.
  --output <path>      File to write. Defaults to output.txt.
  --font <path>        Font bitmap. Defaults to assets/font/iosevka.png.
  --char_ratio <w> <h> Width by height ratio of the font characters. Defaults to 1x2.
  --cols <value>       Target number of columns per image. Defaults to 240.
  --contrast <value>   Target contrast, 1.0 is normal, >1.0 = sharper edges.
  --charset <value>    Character set to choose from. Possible values: ascii, extended, cp437. Defaults to ascii.
  -h, --help           Show this help.
''';

void main(List<String> args) {
  final Options options;
  try {
    options = Options.parse(args);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  if (options.help) {
    stdout.write(_usage);
    return;
  }

  final file = File(options.imagePath);
  if (!file.existsSync()) {
    stderr.writeln(
      "Error: Please ensure '${options.imagePath}' exists in the application directory.",
    );
    exitCode = 1;
    return;
  }

  final fontFile = File(options.fontPath);
  if (!fontFile.existsSync()) {
    stderr.writeln("Error: Font bitmap '${options.fontPath}' was not found.");
    exitCode = 1;
    return;
  }

  stdout.writeln('Initializing renderer (computing 6D shape vectors)...');
  final renderer = AsciiRenderer();
  final fontSheet = img.decodeImage(fontFile.readAsBytesSync());
  if (fontSheet == null) {
    stdout.writeln("Unable to load image ${options.fontPath}");
    return;
  }

  final charsetRange = options.charset.range;

  renderer.initializeFromFontSheet(
    fontSheet,
    charsetRange,
    options.fontCharWidth,
    options.fontCharHeight,
  );

  stdout.writeln('Loading image...');
  final targetImage = img.decodeImage(file.readAsBytesSync());
  if (targetImage == null) {
    stderr.writeln('Failed to decode image.');
    exitCode = 1;
    return;
  }

  // Calculate rows to maintain the image's aspect ratio.
  // Monospace characters are roughly twice as tall as they are wide (1:2 ratio).
  final imageAspectRatio = targetImage.width / targetImage.height;
  final targetRows = ((options.cols / imageAspectRatio) * 0.5).toInt();

  stdout.writeln('Rendering ASCII at ${options.cols}x$targetRows...');
  final stopwatch = Stopwatch()..start();

  final asciiArt = renderer.render(
    targetImage,
    options.cols,
    targetRows,
    options.contrast,
  );

  stopwatch.stop();
  stdout.writeln(asciiArt);
  stdout.writeln('Render completed in ${stopwatch.elapsedMilliseconds} ms.');

  File(options.outputPath).writeAsStringSync(asciiArt);
  stdout.writeln(
    "Success! Open '${options.outputPath}' in a text editor (zoom out and turn off word wrap!).",
  );
}
