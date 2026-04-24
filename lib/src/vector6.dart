/// Represents a 6-dimensional shape vector
class Vector6 {
  double v0 = 0, v1 = 0, v2 = 0, v3 = 0, v4 = 0, v5 = 0;

  double distanceSquared(Vector6 other) {
    double d0 = v0 - other.v0, d1 = v1 - other.v1, d2 = v2 - other.v2;
    double d3 = v3 - other.v3, d4 = v4 - other.v4, d5 = v5 - other.v5;
    return d0 * d0 + d1 * d1 + d2 * d2 + d3 * d3 + d4 * d4 + d5 * d5;
  }

  double operator [](int index) {
    switch (index) {
      case 0:
        return v0;
      case 1:
        return v1;
      case 2:
        return v2;
      case 3:
        return v3;
      case 4:
        return v4;
      case 5:
        return v5;
      default:
        return 0;
    }
  }

  void operator []=(int index, double value) {
    switch (index) {
      case 0:
        v0 = value;
        break;
      case 1:
        v1 = value;
        break;
      case 2:
        v2 = value;
        break;
      case 3:
        v3 = value;
        break;
      case 4:
        v4 = value;
        break;
      case 5:
        v5 = value;
        break;
    }
  }
}
