import 'dart:io';

import 'package:image/image.dart' as img;

import 'package:ascii_renderer/ascii_renderer.dart';

const _usage = '''
Render an image as ASCII art.

Usage: ascii_renderer [options]

Options:
  --input <path>   Image to render. Defaults to input.jpg.
  --output <path>  File to write. Defaults to output.txt.
  --font <path>    Font bitmap. Defaults to font/iosevka.png.
  -h, --help       Show this help.
''';

void main(List<String> args) {
  final _Options options;
  try {
    options = _Options.parse(args);
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

  const int targetColumns = 240;
  const double contrastExponent = 10.0; // 1.0 = normal, > 1.0 = sharper edges

  final File file = File(options.imagePath);
  if (!file.existsSync()) {
    stderr.writeln(
      "Error: Please ensure '${options.imagePath}' exists in the application directory.",
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Loading image...');
  final img.Image? targetImage = img.decodeImage(file.readAsBytesSync());
  if (targetImage == null) {
    stderr.writeln('Failed to decode image.');
    exitCode = 1;
    return;
  }

  final File fontFile = File(options.fontPath);
  if (!fontFile.existsSync()) {
    stderr.writeln("Error: Font bitmap '${options.fontPath}' was not found.");
    exitCode = 1;
    return;
  }

  stdout.writeln('Initializing renderer (computing 6D shape vectors)...');
  final AsciiRenderer renderer = AsciiRenderer();
  renderer.initializeFromBitmap(options.fontPath);

  // Calculate rows to maintain the image's aspect ratio.
  // Monospace characters are roughly twice as tall as they are wide (1:2 ratio).
  final double imageAspectRatio = targetImage.width / targetImage.height;
  final int targetRows = ((targetColumns / imageAspectRatio) * 0.5).toInt();

  stdout.writeln('Rendering ASCII at ${targetColumns}x$targetRows...');
  final stopwatch = Stopwatch()..start();

  final String asciiArt = renderer.render(
    targetImage,
    targetColumns,
    targetRows,
    contrastExponent,
  );

  stopwatch.stop();
  stdout.writeln('Render completed in ${stopwatch.elapsedMilliseconds} ms.');

  File(options.outputPath).writeAsStringSync(asciiArt);
  stdout.writeln(
    "Success! Open '${options.outputPath}' in a text editor (zoom out and turn off word wrap!).",
  );
}

class _Options {
  const _Options({
    required this.imagePath,
    required this.outputPath,
    required this.fontPath,
    required this.help,
  });

  final String imagePath;
  final String outputPath;
  final String fontPath;
  final bool help;

  static _Options parse(List<String> args) {
    var imagePath = 'input.jpg';
    var outputPath = 'output.txt';
    var fontPath = 'font/iosevka.png';
    var help = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '-h':
        case '--help':
          help = true;
        case '--input':
          imagePath = _value(args, ++i, arg);
        case '--output':
          outputPath = _value(args, ++i, arg);
        case '--font':
          fontPath = _value(args, ++i, arg);
        default:
          if (arg.startsWith('--input=')) {
            imagePath = arg.substring('--input='.length);
          } else if (arg.startsWith('--output=')) {
            outputPath = arg.substring('--output='.length);
          } else if (arg.startsWith('--font=')) {
            fontPath = arg.substring('--font='.length);
          } else {
            throw FormatException('Unknown argument: $arg');
          }
      }
    }

    return _Options(
      imagePath: imagePath,
      outputPath: outputPath,
      fontPath: fontPath,
      help: help,
    );
  }

  static String _value(List<String> args, int index, String flag) {
    if (index >= args.length || args[index].startsWith('-')) {
      throw FormatException('Missing value for $flag');
    }
    return args[index];
  }
}
