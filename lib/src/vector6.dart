/// Represents a 6-dimensional shape vector
class Vector6 {
  Vector6([
    this.v0 = 0.0,
    this.v1 = 0.0,
    this.v2 = 0.0,
    this.v3 = 0.0,
    this.v4 = 0.0,
    this.v5 = 0.0,
  ]);

  Vector6.zero() : this();

  @Deprecated('Use Vector6.zero() instead')
  Vector6.origin() : this();
  double v0;
  double v1;
  double v2;
  double v3;
  double v4;
  double v5;

  double distanceSquared(Vector6 other) {
    final d0 = v0 - other.v0;
    final d1 = v1 - other.v1;
    final d2 = v2 - other.v2;
    final d3 = v3 - other.v3;
    final d4 = v4 - other.v4;
    final d5 = v5 - other.v5;
    return d0 * d0 + d1 * d1 + d2 * d2 + d3 * d3 + d4 * d4 + d5 * d5;
  }

  double operator [](int index) => switch (index) {
    0 => v0,
    1 => v1,
    2 => v2,
    3 => v3,
    4 => v4,
    5 => v5,
    _ => 0.0,
  };

  void operator []=(int index, double value) {
    switch (index) {
      case 0:
        v0 = value;
      case 1:
        v1 = value;
      case 2:
        v2 = value;
      case 3:
        v3 = value;
      case 4:
        v4 = value;
      case 5:
        v5 = value;
    }
  }

  @override
  String toString() => 'Vector6($v0, $v1, $v2, $v3, $v4, $v5)';
}
