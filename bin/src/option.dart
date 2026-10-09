import 'package:args/args.dart';
import 'package:ascii_renderer/ascii_renderer.dart';

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

  factory Options.fromArgResults(ArgResults results) {
    final help = results['help'] as bool;
    final imagePath = results['input'] as String;
    final outputPath = results['output'] as String;
    final fontPath = results['font'] as String;

    final colsStr = results['cols'] as String;
    final cols = int.tryParse(colsStr);
    if (cols == null) {
      throw FormatException('Invalid integer for --cols: $colsStr');
    }

    final contrastStr = results['contrast'] as String;
    final contrast = double.tryParse(contrastStr);
    if (contrast == null) {
      throw FormatException('Invalid number for --contrast: $contrastStr');
    }

    final charsetStr = results['charset'] as String;
    final charset = CharsetOption.tryParse(charsetStr);
    if (charset == null) {
      throw FormatException('Unknown charset option: $charsetStr');
    }

    final charRatioList = results['char_ratio'] as List<String>;
    if (charRatioList.length != 2) {
      throw FormatException(
        'Expected two values for --char_ratio, got ${charRatioList.length}',
      );
    }
    final fontCharWidth = int.tryParse(charRatioList[0]);
    if (fontCharWidth == null) {
      throw FormatException(
        'Invalid integer for --char_ratio width: ${charRatioList[0]}',
      );
    }
    final fontCharHeight = int.tryParse(charRatioList[1]);
    if (fontCharHeight == null) {
      throw FormatException(
        'Invalid integer for --char_ratio height: ${charRatioList[1]}',
      );
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

  final String imagePath;
  final String outputPath;
  final String fontPath;
  final int fontCharWidth;
  final int fontCharHeight;
  final int cols;
  final double contrast;
  final CharsetOption charset;
  final bool help;

  static ArgParser get parser => ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.')
    ..addOption(
      'input',
      defaultsTo: 'input.jpg',
      help: 'Image to render.',
      valueHelp: 'path',
    )
    ..addOption(
      'output',
      defaultsTo: 'output.txt',
      help: 'File to write.',
      valueHelp: 'path',
    )
    ..addOption(
      'font',
      defaultsTo: 'assets/font/iosevka.png',
      help: 'Font bitmap.',
      valueHelp: 'path',
    )
    ..addMultiOption(
      'char_ratio',
      defaultsTo: ['1', '2'],
      help: 'Width by height ratio of the font characters.',
      valueHelp: '<w> <h>',
    )
    ..addOption(
      'cols',
      defaultsTo: '240',
      help: 'Target number of columns per image.',
      valueHelp: 'value',
    )
    ..addOption(
      'contrast',
      defaultsTo: '1.0',
      help: 'Target contrast, 1.0 is normal, >1.0 = sharper edges.',
      valueHelp: 'value',
    )
    ..addOption(
      'charset',
      defaultsTo: 'ascii',
      allowed: ['ascii', 'extended', 'ascii_extended', 'cp437'],
      help: 'Character set to choose from.',
      valueHelp: 'value',
    );

  static String get usage =>
      '''
Render an image as ASCII art.

Usage: ascii_renderer [options]

${parser.usage}
''';

  static Options parse(List<String> args) {
    final preprocessed = _preprocessArgs(args);
    final results = parser.parse(preprocessed);
    return Options.fromArgResults(results);
  }

  static List<String> _preprocessArgs(List<String> args) {
    const singleValueOptions = {
      '--input',
      '--output',
      '--font',
      '--cols',
      '--contrast',
      '--charset',
    };

    final normalized = <String>[];
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (singleValueOptions.contains(arg)) {
        if (i + 1 >= args.length || args[i + 1].startsWith('-')) {
          throw FormatException('Missing value for $arg');
        }

        normalized
          ..add(arg)
          ..add(args[++i]);
      } else if (arg == '--char_ratio') {
        if (i + 1 >= args.length || args[i + 1].startsWith('-')) {
          throw FormatException('Missing value for $arg');
        }

        final next = args[i + 1];
        final match = RegExp(r'^(\d+)[x:,](\d+)$').firstMatch(next);
        if (match != null) {
          normalized
            ..add('--char_ratio')
            ..add('${match.group(1)},${match.group(2)}');
          i += 1;
        } else {
          if (i + 2 >= args.length || args[i + 2].startsWith('-')) {
            throw FormatException('Missing value for $arg');
          }

          normalized
            ..add('--char_ratio')
            ..add('${args[i + 1]},${args[i + 2]}');
          i += 2;
        }
      } else if (arg.startsWith('--char_ratio=')) {
        final val = arg.substring('--char_ratio='.length);
        final match = RegExp(r'^(\d+)[x:,](\d+)$').firstMatch(val);
        if (match != null) {
          normalized.add('--char_ratio=${match.group(1)},${match.group(2)}');
        } else {
          normalized.add(arg);
        }
      } else {
        normalized.add(arg);
      }
    }
    return normalized;
  }
}
