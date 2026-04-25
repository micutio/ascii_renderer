import 'package:ascii_renderer/src/vector6.dart';
import 'package:test/test.dart';

void main() {
  group('Vector6', () {
    test('default constructor initializes all components to 0', () {
      final v = Vector6();
      expect(v.v0, 0.0);
      expect(v.v1, 0.0);
      expect(v.v2, 0.0);
      expect(v.v3, 0.0);
      expect(v.v4, 0.0);
      expect(v.v5, 0.0);
    });

    test('indexed getter returns correct component values', () {
      final v = Vector6()
        ..v0 = 1.0
        ..v1 = 2.0
        ..v2 = 3.0
        ..v3 = 4.0
        ..v4 = 5.0
        ..v5 = 6.0;

      expect(v[0], 1.0);
      expect(v[1], 2.0);
      expect(v[2], 3.0);
      expect(v[3], 4.0);
      expect(v[4], 5.0);
      expect(v[5], 6.0);
    });

    test('indexed getter returns 0 for out-of-bounds index', () {
      final v = Vector6();
      expect(v[-1], 0.0);
      expect(v[6], 0.0);
      expect(v[100], 0.0);
    });

    test('indexed setter updates correct component values', () {
      final v = Vector6();
      v[0] = 10.0;
      v[1] = 20.0;
      v[2] = 30.0;
      v[3] = 40.0;
      v[4] = 50.0;
      v[5] = 60.0;

      expect(v.v0, 10.0);
      expect(v.v1, 20.0);
      expect(v.v2, 30.0);
      expect(v.v3, 40.0);
      expect(v.v4, 50.0);
      expect(v.v5, 60.0);
    });

    test('indexed setter does nothing for out-of-bounds index', () {
      final v = Vector6()..v0 = 5.0;
      v[-1] = 100.0;
      v[6] = 200.0;
      expect(v.v0, 5.0); // Should remain unchanged
    });

    group('distanceSquared', () {
      test('returns 0 for identical vectors', () {
        final v1 = Vector6()
          ..v0 = 1.0
          ..v1 = 2.0
          ..v2 = 3.0;
        final v2 = Vector6()
          ..v0 = 1.0
          ..v1 = 2.0
          ..v2 = 3.0;

        expect(v1.distanceSquared(v2), 0.0);
      });

      test('calculates correct squared Euclidean distance', () {
        final v1 = Vector6()
          ..v0 = 0.0
          ..v1 = 0.0
          ..v2 = 0.0
          ..v3 = 0.0
          ..v4 = 0.0
          ..v5 = 0.0;
        final v2 = Vector6()
          ..v0 = 3.0
          ..v1 = 4.0
          ..v2 = 0.0
          ..v3 = 0.0
          ..v4 = 0.0
          ..v5 = 0.0;

        // 3^2 + 4^2 = 9 + 16 = 25
        expect(v1.distanceSquared(v2), 25.0);
      });

      test('is symmetric (distance from A to B equals B to A)', () {
        final v1 = Vector6()
          ..v0 = 1.0
          ..v1 = 2.0
          ..v2 = 3.0
          ..v3 = 4.0
          ..v4 = 5.0
          ..v5 = 6.0;
        final v2 = Vector6()
          ..v0 = 4.0
          ..v1 = 3.0
          ..v2 = 2.0
          ..v3 = 1.0
          ..v4 = 0.0
          ..v5 = -1.0;

        expect(v1.distanceSquared(v2), v2.distanceSquared(v1));
      });

      test('handles negative component differences', () {
        final v1 = Vector6()..v0 = -3.0;
        final v2 = Vector6()..v0 = 3.0;

        // (-3 - 3)^2 = (-6)^2 = 36
        expect(v1.distanceSquared(v2), 36.0);
      });

      test('returns large value when comparing to zero vector', () {
        final v1 = Vector6()
          ..v0 = 100.0
          ..v1 = 100.0
          ..v2 = 100.0
          ..v3 = 100.0
          ..v4 = 100.0
          ..v5 = 100.0;
        final v2 = Vector6();

        // 6 * 100^2 = 60000
        expect(v1.distanceSquared(v2), 60000.0);
      });
    });
  });
}
