import 'package:ascii_renderer/src/charset_range.dart';
import 'package:test/test.dart';

void main() {
  group('CharsetRange', () {
    test('stores start and end correctly', () {
      final range = CharsetRange(32, 128);
      expect(range.start, 32);
      expect(range.end, 128);
    });

    test('allows updating start and end', () {
      final range = CharsetRange(0, 256);
      range.start = 10;
      range.end = 200;
      expect(range.start, 10);
      expect(range.end, 200);
    });

    test('handles zero and negative values', () {
      final range = CharsetRange(0, 0);
      expect(range.start, 0);
      expect(range.end, 0);
    });
  });
}
