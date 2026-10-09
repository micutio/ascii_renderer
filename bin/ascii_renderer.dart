import 'dart:io';
import 'dart:math' as math;

import 'package:ascii_renderer/ascii_renderer.dart';
import 'package:image/image.dart' as img;

import 'src/option.dart';

void main(List<String> args) {
  final Options options;
  try {
    options = Options.parse(args);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(Options.usage);
    exitCode = 64;
    return;
  }

  if (options.help) {
    stdout.write(Options.usage);
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
    stderr.writeln(
      "Error: Failed to decode font bitmap '${options.fontPath}'.",
    );
    exitCode = 1;
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

  // Calculate rows to maintain the image's aspect ratio based on the font character ratio.
  final imageAspectRatio = targetImage.width / targetImage.height;
  final fontAspectRatio = options.fontCharWidth / options.fontCharHeight;
  final targetRows = math.max(
    1,
    ((options.cols / imageAspectRatio) * fontAspectRatio).toInt(),
  );

  stdout.writeln('Rendering ASCII at ${options.cols}x$targetRows...');
  final stopwatch = Stopwatch()..start();

  final asciiArt = renderer.render(
    targetImage,
    options.cols,
    targetRows,
    options.contrast,
  );

  stopwatch.stop();
  stdout
    ..writeln(asciiArt)
    ..writeln('Render completed in ${stopwatch.elapsedMilliseconds} ms.');

  File(options.outputPath).writeAsStringSync(asciiArt);
  stdout.writeln(
    "Success! Open '${options.outputPath}' in a text editor (zoom out and turn off word wrap!).",
  );
}
