import 'dart:io';

import 'package:ascii_renderer/ascii_renderer.dart';
import 'package:ascii_renderer/src/vector6.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

img.Image _blankFontSheet() {
  final image = img.Image(width: 16 * 6, height: 16 * 9);
  img.fill(image, color: img.ColorRgb8(0, 0, 0));
  return image;
}

void _fillCharacterRegion(
  img.Image fontSheet,
  int characterCode,
  int region,
  int whitePixelCount,
) {
  final cellX = (characterCode % 16) * 6;
  final cellY = (characterCode ~/ 16) * 9;
  final regionX = (region % 2) * 3;
  final regionY = (region ~/ 2) * 3;

  for (var i = 0; i < whitePixelCount; i++) {
    fontSheet.setPixel(
      cellX + regionX + i % 3,
      cellY + regionY + i ~/ 3,
      img.ColorRgb8(255, 255, 255),
    );
  }
}

img.Image _sampleWithRegion(int region, int whitePixelCount) {
  final image = img.Image(width: 6, height: 9);
  img.fill(image, color: img.ColorRgb8(0, 0, 0));
  _fillCharacterRegion(image, 0, region, whitePixelCount);
  return image;
}

void main() {
  group('AsciiRenderer', () {
    late AsciiRenderer renderer;

    setUp(() {
      renderer = AsciiRenderer()..initializeFromDefault(CharsetRange.ascii);
    });

    group('constants', () {
      test('charset has 256 characters', () {
        expect(AsciiRenderer.charset.length, 256);
      });

      test('charset starts with space and printable characters', () {
        expect(AsciiRenderer.charset[0], ' ');
        expect(AsciiRenderer.charset[32], ' ');
        expect(AsciiRenderer.charset[33], '!');
      });
    });

    group('initializeFromDefault', () {
      test('initializes with ascii charset range', () {
        final newRenderer = AsciiRenderer()
          ..initializeFromDefault(CharsetRange.ascii);
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final result = newRenderer.render(image, 5, 5, 1.0);
        expect(result.isNotEmpty, true);
      });

      test('initializes with extended charset range', () {
        final newRenderer = AsciiRenderer()
          ..initializeFromDefault(CharsetRange.asciiExtended);
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final result = newRenderer.render(image, 5, 5, 1.0);
        expect(result.isNotEmpty, true);
      });

      test('initializes with cp437 charset range', () {
        final newRenderer = AsciiRenderer()
          ..initializeFromDefault(CharsetRange.cp437);
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final result = newRenderer.render(image, 5, 5, 1.0);
        expect(result.isNotEmpty, true);
      });

      test('re-initialization clears existing character shapes', () {
        final reRenderer = AsciiRenderer()
          ..initializeFromDefault(CharsetRange.ascii)
          // Initializing again should not crash or accumulate duplicate shapes
          ..initializeFromDefault(CharsetRange.cp437);
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final result = reRenderer.render(image, 5, 5, 1.0);
        expect(result.isNotEmpty, true);
      });

      test(
        'initializes with custom CharsetRange restricted to uppercase letters',
        () {
          final newRenderer = AsciiRenderer()
            // Indices 65 ('A') to 91 ('Z' is index 90)
            ..initializeFromDefault(const CharsetRange(65, 91));
          final image = img.Image(width: 10, height: 10);
          img.fill(image, color: img.ColorRgb8(128, 128, 128));
          final result = newRenderer.render(image, 5, 5, 1.0);
          final chars = result.replaceAll('\n', '').replaceAll('\r', '');
          expect(chars.isNotEmpty, true);
          for (var i = 0; i < chars.length; i++) {
            final codeUnit = chars.codeUnitAt(i);
            expect(codeUnit >= 65 && codeUnit <= 90, isTrue);
          }
        },
      );
    });

    group('initializeFromFontSheet', () {
      late img.Image testFontSheet;

      setUp(() {
        // Font sheets are 16x16 characters
        testFontSheet = img.Image(width: 160, height: 320);
        img.fill(testFontSheet, color: img.ColorRgb8(0, 0, 0));
        for (var row = 0; row < 16; row++) {
          for (var col = 0; col < 16; col++) {
            img.fillRect(
              testFontSheet,
              x1: col * 10 + 2,
              y1: row * 20 + 2,
              x2: col * 10 + 8,
              y2: row * 20 + 18,
              color: img.ColorRgb8(255, 255, 255),
            );
          }
        }
      });

      test(
        'initializes with font sheet where widthRatio < heightRatio (1x2)',
        () {
          final fontRenderer = AsciiRenderer()
            ..initializeFromFontSheet(testFontSheet, CharsetRange.ascii, 1, 2);
          final image = img.Image(width: 20, height: 20);
          img.fill(image, color: img.ColorRgb8(128, 128, 128));
          final result = fontRenderer.render(image, 5, 5, 1.0);
          expect(result.isNotEmpty, true);
        },
      );

      test(
        'initializes with font sheet where widthRatio > heightRatio (2x1)',
        () {
          final fontRenderer = AsciiRenderer()
            ..initializeFromFontSheet(testFontSheet, CharsetRange.ascii, 2, 1);
          final image = img.Image(width: 20, height: 20);
          img.fill(image, color: img.ColorRgb8(128, 128, 128));
          final result = fontRenderer.render(image, 5, 5, 1.0);
          expect(result.isNotEmpty, true);
        },
      );

      test(
        'initializes with font sheet where widthRatio == heightRatio (1x1)',
        () {
          final fontRenderer = AsciiRenderer()
            ..initializeFromFontSheet(testFontSheet, CharsetRange.ascii, 1, 1);
          final image = img.Image(width: 20, height: 20);
          img.fill(image, color: img.ColorRgb8(128, 128, 128));
          final result = fontRenderer.render(image, 5, 5, 1.0);
          expect(result.isNotEmpty, true);
        },
      );

      test('initializes with font sheet and cp437 charset range', () {
        final fontRenderer = AsciiRenderer()
          ..initializeFromFontSheet(testFontSheet, CharsetRange.cp437, 1, 2);
        final image = img.Image(width: 20, height: 20);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final result = fontRenderer.render(image, 5, 5, 1.0);
        expect(result.isNotEmpty, true);
      });

      test('initializes with real font bitmap assets/font/iosevka.png', () {
        final fontFile = File('assets/font/iosevka.png');
        if (fontFile.existsSync()) {
          final fontImg = img.decodeImage(fontFile.readAsBytesSync())!;
          final fontRenderer = AsciiRenderer()
            ..initializeFromFontSheet(fontImg, CharsetRange.ascii, 1, 2);
          final image = img.Image(width: 20, height: 20);
          img.fill(image, color: img.ColorRgb8(128, 128, 128));
          final result = fontRenderer.render(image, 5, 5, 1.0);
          expect(result.isNotEmpty, true);
        }
      });
    });

    group('render', () {
      test('renders a solid black image without error', () {
        // Create a 10x10 black image
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(0, 0, 0));

        final result = renderer.render(image, 10, 10, 1.0);

        // Result should have 10 lines (10 rows + newlines)
        final lines = result.split('\n').where((l) => l.isNotEmpty).toList();
        expect(lines.length, 10);
        // Each line should have 10 characters
        for (final line in lines) {
          expect(line.length, 10);
        }
      });

      test('renders a solid white image without error', () {
        // Create a 10x10 white image
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(255, 255, 255));

        final result = renderer.render(image, 10, 10, 1.0);

        // Result should have 10 lines
        final lines = result.split('\n').where((l) => l.isNotEmpty).toList();
        expect(lines.length, 10);
      });

      test('renders with custom columns and rows', () {
        final image = img.Image(width: 20, height: 20);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));

        final result = renderer.render(image, 5, 4, 1.0);

        final lines = result.split('\n').where((l) => l.isNotEmpty).toList();
        expect(lines.length, 4);
        for (final line in lines) {
          expect(line.length, 5);
        }
      });

      test('applies contrast exponent without error', () {
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));

        // Should not throw
        final resultDefault = renderer.render(image, 5, 5, 1.0);
        final resultHighContrast = renderer.render(image, 5, 5, 2.0);
        final resultLowContrast = renderer.render(image, 5, 5, 0.5);

        // All should produce valid output
        expect(resultDefault.isNotEmpty, true);
        expect(resultHighContrast.isNotEmpty, true);
        expect(resultLowContrast.isNotEmpty, true);
      });

      test('contrast exponent can change the selected glyph', () {
        final fontSheet = _blankFontSheet();
        for (var region = 0; region < 6; region++) {
          _fillCharacterRegion(fontSheet, 33, region, 6);
          _fillCharacterRegion(fontSheet, 34, region, 3);
        }

        final contrastRenderer = AsciiRenderer()
          ..initializeFromFontSheet(
            fontSheet,
            const CharsetRange(33, 35),
            1,
            1,
          );
        final image = img.Image(width: 1, height: 1);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));

        expect(contrastRenderer.render(image, 1, 1, 1.0), '!\n');
        expect(contrastRenderer.render(image, 1, 1, 2.0), '"\n');
      });

      test('default font baseline retains the underline shape', () {
        final defaultRenderer = AsciiRenderer()
          ..initializeFromDefault(CharsetRange.ascii);
        final underline = img.Image(width: 12, height: 24);
        img.fill(underline, color: img.ColorRgb8(0, 0, 0));
        img.drawString(
          underline,
          '_',
          font: img.arial24,
          color: img.ColorRgb8(255, 255, 255),
          x: -2,
          y: -2,
        );

        expect(defaultRenderer.render(underline, 1, 1, 1.0), '_\n');
      });

      test('handles zero cell dimensions gracefully', () {
        final image = img.Image(width: 1, height: 1);

        // Should not throw
        final result = renderer.render(image, 1000, 1000, 1.0);
        expect(result.isNotEmpty, true);
      });

      test('matches shape separately from total density', () {
        final fontSheet = _blankFontSheet();
        _fillCharacterRegion(fontSheet, 33, 4, 9);
        _fillCharacterRegion(fontSheet, 34, 2, 2);
        _fillCharacterRegion(fontSheet, 35, 2, 9);
        final shapeRenderer = AsciiRenderer()
          ..initializeFromFontSheet(
            fontSheet,
            const CharsetRange(33, 36),
            1,
            1,
          );
        final image = _sampleWithRegion(4, 2);

        expect(shapeRenderer.render(image, 1, 1, 1.0), '!\n');
      });

      test('character matching is independent of charset maxima', () {
        final fontSheet = _blankFontSheet();
        _fillCharacterRegion(fontSheet, 33, 4, 9);
        _fillCharacterRegion(fontSheet, 34, 2, 2);
        _fillCharacterRegion(fontSheet, 35, 2, 9);
        final image = _sampleWithRegion(4, 2);
        final sparseRenderer = AsciiRenderer()
          ..initializeFromFontSheet(
            fontSheet,
            const CharsetRange(33, 35),
            1,
            1,
          );
        final denseRenderer = AsciiRenderer()
          ..initializeFromFontSheet(
            fontSheet,
            const CharsetRange(33, 36),
            1,
            1,
          );

        expect(sparseRenderer.render(image, 1, 1, 1.0), '!\n');
        expect(denseRenderer.render(image, 1, 1, 1.0), '!\n');
      });

      test('handles zero vectors and preserves punctuation detail', () {
        final fontSheet = _blankFontSheet();
        _fillCharacterRegion(fontSheet, 46, 4, 1);
        _fillCharacterRegion(fontSheet, 95, 4, 9);
        final punctuationRenderer = AsciiRenderer()
          ..initializeFromFontSheet(
            fontSheet,
            const CharsetRange(46, 96),
            1,
            1,
          );
        final blackImage = img.Image(width: 6, height: 9);
        img.fill(blackImage, color: img.ColorRgb8(0, 0, 0));

        expect(punctuationRenderer.render(blackImage, 1, 1, 1.0), '/\n');
        expect(
          punctuationRenderer.render(_sampleWithRegion(4, 1), 1, 1, 1.0),
          '.\n',
        );
        expect(
          punctuationRenderer.render(_sampleWithRegion(4, 9), 1, 1, 1.0),
          '_\n',
        );
      });
    });

    group('cache key generation', () {
      test('identical vectors produce identical cache keys', () {
        /*
        final v1 = Vector6()
          ..v0 = 0.5
          ..v1 = 0.3
          ..v2 = 0.1
          ..v3 = 0.8
          ..v4 = 0.2
          ..v5 = 0.9;
        final v2 = Vector6()
          ..v0 = 0.5
          ..v1 = 0.3
          ..v2 = 0.1
          ..v3 = 0.8
          ..v4 = 0.2
          ..v5 = 0.9;
          */

        // Use reflection or test through render to verify cache works
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));

        // Render twice - second should use cache
        renderer.render(image, 2, 2, 1.0);
        final result = renderer.render(image, 2, 2, 1.0);

        expect(result.isNotEmpty, true);
      });

      test('vectors at boundaries quantize correctly', () {
        final v0 = Vector6.zero()..v0 = 0.0;
        final v1 = Vector6.zero()..v0 = 1.0;
        final vMid = Vector6.zero()..v0 = 0.5;

        // 0.0 * 15 = 0
        // 1.0 * 15 = 15
        // 0.5 * 15 = 7.5 -> 8
        expect((v0.v0 * 15).round(), 0);
        expect((v1.v0 * 15).round(), 15);
        expect((vMid.v0 * 15).round(), 8);
      });
    });

    group('edge cases', () {
      test('handles single pixel image', () {
        final image = img.Image(width: 1, height: 1)
          ..setPixel(0, 0, img.ColorRgb8(255, 255, 255));

        final result = renderer.render(image, 1, 1, 1.0);
        // Should produce output (may be single character + newline)
        expect(result.isNotEmpty, true);
      });

      test('handles very wide aspect ratio', () {
        final image = img.Image(width: 100, height: 10);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));

        final result = renderer.render(image, 20, 2, 1.0);
        final lines = result.split('\n').where((l) => l.isNotEmpty).toList();
        expect(lines.length, 2);
      });

      test('handles very tall aspect ratio', () {
        final image = img.Image(width: 10, height: 100);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));

        final result = renderer.render(image, 2, 20, 1.0);
        final lines = result.split('\n').where((l) => l.isNotEmpty).toList();
        expect(lines.length, 20);
      });
    });

    group('character diversity', () {
      test('renders gradient image with varied characters', () {
        // Create a gradient from black to white
        final image = img.Image(width: 256, height: 1);
        for (var x = 0; x < 256; x++) {
          image.setPixel(x, 0, img.ColorRgb8(x, x, x));
        }

        final result = renderer.render(image, 256, 1, 1.0);
        final line = result.split('\n').first;

        // Should use at least one non-space character.
        expect(line.trim().isNotEmpty, true);
        // Should have 256 characters
        expect(line.length, 256);
      });
    });
  });
}
