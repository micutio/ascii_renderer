/// Indicates the range of a character set.
/// [start] is inclusive, [end] is exclusive.
class CharsetRange {
  const CharsetRange(this.start, this.end)
    : assert(start >= 0, 'start must be non-negative'),
      assert(end >= start, 'end must be greater than or equal to start');

  final int start;
  final int end;

  static const ascii = CharsetRange(32, 128);
  static const asciiExtended = CharsetRange(32, 256);
  static const cp437 = CharsetRange(0, 256);

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharsetRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'CharsetRange($start, $end)';
}
