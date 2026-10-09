import 'package:ascii_renderer/src/charset_range.dart';

enum CharsetOption {
  ascii,
  asciiExtended,
  cp437;

  static CharsetOption? tryParse(String label) {
    return switch (label.toLowerCase()) {
      'ascii' => CharsetOption.ascii,
      'ascii_extended' || 'extended' => CharsetOption.asciiExtended,
      'cp437' => CharsetOption.cp437,
      _ => null,
    };
  }

  CharsetRange get range => switch (this) {
    CharsetOption.ascii => CharsetRange.ascii,
    CharsetOption.asciiExtended => CharsetRange.asciiExtended,
    CharsetOption.cp437 => CharsetRange.cp437,
  };
}

class Options {
  const Options({
    required this.imagePath,
    required this.outputPath,
    required this.fontPath,
    required this.fontCharWidth,
    required this.fontCharHeight,
    required this.cols,
    required this.contrast,
    required this.charset,
    required this.help,
  });

  final String imagePath;
  final String outputPath;
  final String fontPath;
  final int fontCharWidth;
  final int fontCharHeight;
  final int cols;
  final double contrast;
  final CharsetOption charset;
  final bool help;

  static Options parse(List<String> args) {
    var imagePath = 'input.jpg';
    var outputPath = 'output.txt';
    var fontPath = 'assets/font/iosevka.png';
    var fontCharWidth = 1;
    var fontCharHeight = 2;
    var cols = 240;
    var contrast = 1.0;
    var charset = CharsetOption.ascii;
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
        case '--char_ratio':
          fontCharWidth = _valueToInt(args, ++i, arg);
          fontCharHeight = _valueToInt(args, ++i, arg);
        case '--cols':
          cols = _valueToInt(args, ++i, arg);
        case '--contrast':
          contrast = _valueToDouble(args, ++i, arg);
        case '--charset':
          final charsetOptStr = _valueToStr(args, ++i, arg);
          final charsetOpt = CharsetOption.tryParse(charsetOptStr);
          if (charsetOpt == null) {
            throw FormatException('Unknown charset option: $charsetOptStr');
          }
          charset = charsetOpt;
        default:
          throw FormatException('Unknown argument: $arg');
      }
    }

    return Options(
      imagePath: imagePath,
      outputPath: outputPath,
      fontPath: fontPath,
      fontCharWidth: fontCharWidth,
      fontCharHeight: fontCharHeight,
      cols: cols,
      contrast: contrast,
      charset: charset,
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
