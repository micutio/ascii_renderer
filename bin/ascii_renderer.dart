import 'dart:io';

import 'package:image/image.dart' as img;

import 'package:ascii_renderer/ascii_renderer.dart';

// TODO: Explore other ways of argument parsing.
const _usage = '''
Render an image as ASCII art.

Usage: ascii_renderer [options]

Options:
  --input <path>     Image to render. Defaults to input.jpg.
  --output <path>    File to write. Defaults to output.txt.
  --font <path>      Font bitmap. Defaults to assets/font/iosevka.png.
  --cols <value>     Target number of columns per image. Defaults to 240.
  --contrast <value> Target contrast, 1.0 is normal, >1.0 = sharper edges.
  -h, --help         Show this help.
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
  img.Image? fontSheet = img.decodeImage(fontFile.readAsBytesSync());
  if (fontSheet == null) {
    stdout.writeln("Unable to load image ${options.fontPath}");
    return;
  }

  renderer.initializeFromFontSheet(fontSheet);

  // Calculate rows to maintain the image's aspect ratio.
  // Monospace characters are roughly twice as tall as they are wide (1:2 ratio).
  final double imageAspectRatio = targetImage.width / targetImage.height;
  final int targetRows = ((options.cols / imageAspectRatio) * 0.5).toInt();

  stdout.writeln('Rendering ASCII at ${options.cols}x$targetRows...');
  final stopwatch = Stopwatch()..start();

  final String asciiArt = renderer.render(
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

class _Options {
  const _Options({
    required this.imagePath,
    required this.outputPath,
    required this.fontPath,
    required this.cols,
    required this.contrast,
    required this.help,
  });

  final String imagePath;
  final String outputPath;
  final String fontPath;
  final int cols;
  final double contrast;
  final bool help;

  static _Options parse(List<String> args) {
    var imagePath = 'input.jpg';
    var outputPath = 'output.txt';
    var fontPath = 'assets/font/iosevka.png';
    var cols = 240;
    var contrast = 1.0;
    var help = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '-h':
        case '--help':
          help = true;
        case '--input':
          imagePath = _valueToStr(args, ++i, arg);
        case '--output':
          outputPath = _valueToStr(args, ++i, arg);
        case '--font':
          fontPath = _valueToStr(args, ++i, arg);
        case '--cols':
          cols = _valueToInt(args, ++i, arg);
        case '--contrast':
          contrast = _valueToDouble(args, ++i, arg);
        default:
          if (arg.startsWith('--input=')) {
            imagePath = arg.substring('--input='.length);
          } else if (arg.startsWith('--output=')) {
            outputPath = arg.substring('--output='.length);
          } else if (arg.startsWith('--font=')) {
            fontPath = arg.substring('--font='.length);
          } else if (arg.startsWith('--cols=')) {
            cols = int.parse(arg.substring('--cols'.length));
          } else if (arg.startsWith('--contrast=')) {
            contrast = double.parse(arg.substring('--contrast'.length));
          } else {
            throw FormatException('Unknown argument: $arg');
          }
      }
    }

    return _Options(
      imagePath: imagePath,
      outputPath: outputPath,
      fontPath: fontPath,
      cols: cols,
      contrast: contrast,
      help: help,
    );
  }

  /// Parses an argument into a string.
  ///
  /// Throws a [FormatException] if the argument is missing or
  /// not a valid string.
  static String _valueToStr(List<String> args, int index, String flag) {
    if (index >= args.length || args[index].startsWith('-')) {
      throw FormatException('Missing value for $flag');
    }
    return args[index];
  }

  /// Parses an argument into an integer.
  ///
  /// Throws a [FormatException] if the argument is missing or not a valid int.
  static int _valueToInt(List<String> args, int index, String flag) {
    if (index >= args.length || args[index].startsWith('-')) {
      throw FormatException('Missing value for $flag');
    }

    return int.parse(args[index]);
  }

  /// Parses an argument into a double.
  ///
  /// Throws a [FormatException] if the argument is missing or not a valid
  /// floating point number.
  static double _valueToDouble(List<String> args, int index, String flag) {
    if (index >= args.length || args[index].startsWith('-')) {
      throw FormatException('Missing value for $flag');
    }

    return double.parse(args[index]);
  }
}
