import 'package:test/test.dart';

import '../bin/src/option.dart';

void main() {
  group('CharsetOption', () {
    group('tryParse', () {
      test('parses "ascii" case-insensitively', () {
        expect(CharsetOption.tryParse('ascii'), CharsetOption.ascii);
        expect(CharsetOption.tryParse('ASCII'), CharsetOption.ascii);
        expect(CharsetOption.tryParse('Ascii'), CharsetOption.ascii);
      });

      test('parses "extended" and "ascii_extended"', () {
        expect(CharsetOption.tryParse('extended'), CharsetOption.asciiExtended);
        expect(CharsetOption.tryParse('EXTENDED'), CharsetOption.asciiExtended);
        expect(
          CharsetOption.tryParse('ascii_extended'),
          CharsetOption.asciiExtended,
        );
        expect(
          CharsetOption.tryParse('ASCII_EXTENDED'),
          CharsetOption.asciiExtended,
        );
      });

      test('parses "cp437" case-insensitively', () {
        expect(CharsetOption.tryParse('cp437'), CharsetOption.cp437);
        expect(CharsetOption.tryParse('CP437'), CharsetOption.cp437);
      });

      test('returns null for unknown charset options', () {
        expect(CharsetOption.tryParse(''), isNull);
        expect(CharsetOption.tryParse('unknown'), isNull);
        expect(CharsetOption.tryParse('utf8'), isNull);
        expect(CharsetOption.tryParse('latin1'), isNull);
      });
    });

    group('getRange', () {
      test('ascii range is 32 to 128', () {
        final range = CharsetOption.ascii.range;
        expect(range.start, 32);
        expect(range.end, 128);
      });

      test('asciiExtended range is 32 to 256', () {
        final range = CharsetOption.asciiExtended.range;
        expect(range.start, 32);
        expect(range.end, 256);
      });

      test('cp437 range is 0 to 256', () {
        final range = CharsetOption.cp437.range;
        expect(range.start, 0);
        expect(range.end, 256);
      });
    });
  });

  group('Options', () {
    group('parse defaults', () {
      test('uses expected default values when no arguments are passed', () {
        final options = Options.parse([]);
        expect(options.imagePath, 'input.jpg');
        expect(options.outputPath, 'output.txt');
        expect(options.fontPath, 'assets/font/iosevka.png');
        expect(options.fontCharWidth, 1);
        expect(options.fontCharHeight, 2);
        expect(options.cols, 240);
        expect(options.contrast, 1.0);
        expect(options.charset, CharsetOption.ascii);
        expect(options.help, false);
      });
    });

    group('parse individual flags', () {
      test('parses -h and --help', () {
        expect(Options.parse(['-h']).help, true);
        expect(Options.parse(['--help']).help, true);
      });

      test('parses --input', () {
        final options = Options.parse(['--input', 'photo.png']);
        expect(options.imagePath, 'photo.png');
      });

      test('parses --output', () {
        final options = Options.parse(['--output', 'result.txt']);
        expect(options.outputPath, 'result.txt');
      });

      test('parses --font', () {
        final options = Options.parse(['--font', 'assets/font/courier.png']);
        expect(options.fontPath, 'assets/font/courier.png');
      });

      test('parses --char_ratio', () {
        final options = Options.parse(['--char_ratio', '3', '4']);
        expect(options.fontCharWidth, 3);
        expect(options.fontCharHeight, 4);
      });

      test('parses --char_ratio with delimiters (1x2, 1:2, 1,2)', () {
        final optX = Options.parse(['--char_ratio', '3x4']);
        expect(optX.fontCharWidth, 3);
        expect(optX.fontCharHeight, 4);

        final optColon = Options.parse(['--char_ratio', '2:5']);
        expect(optColon.fontCharWidth, 2);
        expect(optColon.fontCharHeight, 5);

        final optComma = Options.parse(['--char_ratio=1,3']);
        expect(optComma.fontCharWidth, 1);
        expect(optComma.fontCharHeight, 3);
      });

      test('supports Options.fromArgResults', () {
        final results = Options.parser.parse([
          '--cols',
          '100',
          '--contrast',
          '2.0',
        ]);
        final options = Options.fromArgResults(results);
        expect(options.cols, 100);
        expect(options.contrast, 2.0);
      });

      test('parses --cols', () {
        final options = Options.parse(['--cols', '80']);
        expect(options.cols, 80);
      });

      test('parses --contrast', () {
        final options = Options.parse(['--contrast', '1.8']);
        expect(options.contrast, 1.8);
      });

      test('parses --charset with various supported options', () {
        expect(
          Options.parse(['--charset', 'ascii']).charset,
          CharsetOption.ascii,
        );
        expect(
          Options.parse(['--charset', 'extended']).charset,
          CharsetOption.asciiExtended,
        );
        expect(
          Options.parse(['--charset', 'ascii_extended']).charset,
          CharsetOption.asciiExtended,
        );
        expect(
          Options.parse(['--charset', 'cp437']).charset,
          CharsetOption.cp437,
        );
      });
    });

    group('parse combined arguments', () {
      test('parses full set of arguments correctly', () {
        final options = Options.parse([
          '--input',
          'source.jpg',
          '--output',
          'dest.txt',
          '--font',
          'assets/font/courier.png',
          '--char_ratio',
          '2',
          '3',
          '--cols',
          '120',
          '--contrast',
          '1.5',
          '--charset',
          'cp437',
        ]);

        expect(options.imagePath, 'source.jpg');
        expect(options.outputPath, 'dest.txt');
        expect(options.fontPath, 'assets/font/courier.png');
        expect(options.fontCharWidth, 2);
        expect(options.fontCharHeight, 3);
        expect(options.cols, 120);
        expect(options.contrast, 1.5);
        expect(options.charset, CharsetOption.cp437);
        expect(options.help, false);
      });
    });

    group('error handling', () {
      test('throws FormatException for unknown argument', () {
        expect(() => Options.parse(['--unknown']), throwsFormatException);
        expect(() => Options.parse(['-x']), throwsFormatException);
      });

      test('throws FormatException for missing argument values', () {
        expect(() => Options.parse(['--input']), throwsFormatException);
        expect(() => Options.parse(['--output']), throwsFormatException);
        expect(() => Options.parse(['--font']), throwsFormatException);
        expect(() => Options.parse(['--cols']), throwsFormatException);
        expect(() => Options.parse(['--contrast']), throwsFormatException);
        expect(() => Options.parse(['--charset']), throwsFormatException);
        expect(() => Options.parse(['--char_ratio']), throwsFormatException);
        expect(
          () => Options.parse(['--char_ratio', '1']),
          throwsFormatException,
        );
      });

      test('throws FormatException when next argument is another flag', () {
        expect(
          () => Options.parse(['--input', '--output', 'out.txt']),
          throwsFormatException,
        );
        expect(
          () => Options.parse(['--char_ratio', '1', '--cols', '80']),
          throwsFormatException,
        );
      });

      test('throws FormatException for invalid number formats', () {
        expect(
          () => Options.parse(['--cols', 'not_a_number']),
          throwsFormatException,
        );
        expect(
          () => Options.parse(['--contrast', 'abc']),
          throwsFormatException,
        );
        expect(
          () => Options.parse(['--char_ratio', 'a', '2']),
          throwsFormatException,
        );
        expect(
          () => Options.parse(['--char_ratio', '1', 'b']),
          throwsFormatException,
        );
      });

      test('throws FormatException for unknown charset', () {
        expect(
          () => Options.parse(['--charset', 'invalid_charset']),
          throwsFormatException,
        );
      });
    });
  });
}
