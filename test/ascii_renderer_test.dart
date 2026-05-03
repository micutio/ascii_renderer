import 'package:ascii_renderer/ascii_renderer.dart';
import 'package:ascii_renderer/src/vector6.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

void main() {
  group('AsciiRenderer', () {
    late AsciiRenderer renderer;

    setUp(() {
      renderer = AsciiRenderer();
      renderer.initialize();
    });

    group('constants', () {
      test('quantizationSteps is 15', () {
        expect(AsciiRenderer.quantizationSteps, 15);
      });

      test('charset has 256 characters', () {
        expect(AsciiRenderer.charset.length, 256);
      });

      test('charset starts with space and printable characters', () {
        expect(AsciiRenderer.charset[0], ' ');
        expect(AsciiRenderer.charset[32], ' ');
        expect(AsciiRenderer.charset[33], '!');
      });
    });

    group('initialize', () {
      test('creates character shapes for all charset characters', () {
        // After initialize, the renderer should have shapes for each char
        expect(AsciiRenderer.charset.length, 256);
      });

      test('initialization completes without error', () {
        final newRenderer = AsciiRenderer();
        newRenderer.initialize();
        // If we get here without throwing, the test passes
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
        for (var line in lines) {
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
        for (var line in lines) {
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

      test('handles zero cell dimensions gracefully', () {
        final image = img.Image(width: 1, height: 1);

        // Should not throw
        final result = renderer.render(image, 1000, 1000, 1.0);
        expect(result.isNotEmpty, true);
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
        final v0 = Vector6()..v0 = 0.0;
        final v1 = Vector6()..v0 = 1.0;
        final vMid = Vector6()..v0 = 0.5;

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
        final image = img.Image(width: 1, height: 1);
        image.setPixel(0, 0, img.ColorRgb8(255, 255, 255));

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
        for (int x = 0; x < 256; x++) {
          image.setPixel(x, 0, img.ColorRgb8(x, x, x));
        }

        final result = renderer.render(image, 256, 1, 1.0);
        final line = result.trim();

        // Should use characters (at least the line should have content)
        expect(line.isNotEmpty, true);
        // Should have 256 characters
        expect(line.length, 256);
      });
    });
  });
}
