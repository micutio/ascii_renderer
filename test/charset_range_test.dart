import 'package:ascii_renderer/src/charset_range.dart';
import 'package:test/test.dart';

void main() {
  group('CharsetRange', () {
    test('stores start and end correctly', () {
      final range = CharsetRange(32, 128);
      expect(range.start, 32);
      expect(range.end, 128);
    });

    test('handles zero and negative values', () {
      final range = CharsetRange(0, 0);
      expect(range.start, 0);
      expect(range.end, 0);
    });
  });
}
