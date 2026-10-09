import 'package:ascii_renderer/src/charset_range.dart';
import 'package:test/test.dart';

void main() {
  group('CharsetRange', () {
    test('stores start and end correctly', () {
      const range = CharsetRange(32, 128);
      expect(range.start, 32);
      expect(range.end, 128);
    });

    test('handles zero values', () {
      const range = CharsetRange(0, 0);
      expect(range.start, 0);
      expect(range.end, 0);
    });

    test('implements value equality and hashCode', () {
      const range1 = CharsetRange(32, 128);
      const range2 = CharsetRange(32, 128);
      const range3 = CharsetRange(32, 256);

      expect(range1, equals(range2));
      expect(range1.hashCode, equals(range2.hashCode));
      expect(range1, isNot(equals(range3)));
    });

    test('preset constants have correct ranges', () {
      expect(CharsetRange.ascii, const CharsetRange(32, 128));
      expect(CharsetRange.asciiExtended, const CharsetRange(32, 256));
      expect(CharsetRange.cp437, const CharsetRange(0, 256));
    });
  });
}
