import 'package:ascii_renderer/src/character_shape.dart';
import 'package:ascii_renderer/src/vector6.dart';
import 'package:test/test.dart';

void main() {
  group('CharacterShape', () {
    test('stores character and shapeVector correctly', () {
      final vector = Vector6()
        ..v0 = 1.0
        ..v1 = 2.0
        ..v2 = 3.0;
      final shape = CharacterShape('A', vector);

      expect(shape.character, 'A');
      expect(shape.shapeVector, vector);
    });

    test('allows modification of character', () {
      final vector = Vector6();
      final shape = CharacterShape('A', vector);

      shape.character = 'B';
      expect(shape.character, 'B');
    });

    test('allows modification of shapeVector components', () {
      final vector = Vector6();
      final shape = CharacterShape('A', vector);

      shape.shapeVector.v0 = 5.0;
      shape.shapeVector.v1 = 10.0;

      expect(shape.shapeVector.v0, 5.0);
      expect(shape.shapeVector.v1, 10.0);
    });

    test('handles special characters', () {
      final vector = Vector6();
      final shape = CharacterShape(' ', vector);
      expect(shape.character, ' ');

      shape.character = '@';
      expect(shape.character, '@');
    });

    test('handles unicode characters', () {
      final vector = Vector6();
      final shape = CharacterShape('α', vector);
      expect(shape.character, 'α');
    });

    test('works with zero vector', () {
      final vector = Vector6();
      final shape = CharacterShape('X', vector);

      expect(shape.shapeVector.v0, 0.0);
      expect(shape.shapeVector.v1, 0.0);
      expect(shape.shapeVector.v2, 0.0);
      expect(shape.shapeVector.v3, 0.0);
      expect(shape.shapeVector.v4, 0.0);
      expect(shape.shapeVector.v5, 0.0);
    });
  });
}
