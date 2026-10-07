import 'package:ascii_renderer/src/vector6.dart';

class KdNode<T> {
  final Vector6 point;
  final T data; // e.g. CharacterShape
  KdNode<T>? left;
  KdNode<T>? right;

  KdNode({required this.point, required this.data});
}

class KdTree6D<T> {
  KdNode<T>? root;

  KdTree6D(List<MapEntry<Vector6, T>> items) {
    root = _buildTree(items, 0);
  }

  KdNode<T>? _buildTree(List<MapEntry<Vector6, T>> items, int depth) {
    if (items.isEmpty) return null;

    final int axis = depth % 6;

    // Sort items along the current axis to find median
    items.sort((a, b) => a.key[axis].compareTo(b.key[axis]));

    final int medianIndex = items.length ~/ 2;
    final KdNode<T> node = KdNode<T>(
      point: items[medianIndex].key,
      data: items[medianIndex].value,
    );

    node.left = _buildTree(items.sublist(0, medianIndex), depth + 1);
    node.right = _buildTree(items.sublist(medianIndex + 1), depth + 1);

    return node;
  }

  /// returns the closest item data to the target vector.
  T findNearest(Vector6 target) {
    if (root == null) throw StateError("Tree is empty");

    var bestNode = root!;
    var bestDistanceSq = root!.point.distanceSquared(target);

    void search(KdNode<T>? node, int depth) {
      if (node == null) return;

      final distSq = node.point.distanceSquared(target);
      if (distSq < bestDistanceSq) {
        bestDistanceSq = distSq;
        bestNode = node;
      }

      final axis = depth % 6;
      final axisDelta = target[axis] - node.point[axis];

      // Determine primary and secondary search subtrees.
      final nearChild = axisDelta < 0 ? node.left : node.right;
      final farChild = axisDelta < 0 ? node.right : node.left;

      // Traverse down the near side
      search(nearChild, depth + 1);

      // Backtrack to far side ONLY of the plane boundary is closer than best
      // distance.
      if ((axisDelta * axisDelta) < bestDistanceSq) {
        search(farChild, depth + 1);
      }
    }

    search(root, 0);
    return bestNode.data;
  }
}
