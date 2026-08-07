import 'trend_direction.dart';

/// One category's score at one instant.
class CategoryPoint {
  /// The id of the observation this came from, so a UI can navigate back to
  /// the report a value belongs to.
  final String pointId;
  final DateTime takenAt;
  final double score;

  const CategoryPoint({
    required this.pointId,
    required this.takenAt,
    required this.score,
  });

  @override
  bool operator ==(Object other) =>
      other is CategoryPoint &&
      other.pointId == pointId &&
      other.takenAt == takenAt &&
      other.score == score;

  @override
  int get hashCode => Object.hash(pointId, takenAt, score);
}

/// How one area of health has moved across a subject's history.
///
/// Carries the whole series, not just the ends: a per-category sparkline, a
/// vet asking "when did this start slipping", and the simple 42 → 67 headline
/// are all the same data read at different depths.
class CategoryTrend {
  final String name;

  /// Oldest first, and only the observations that actually scored this
  /// category — a category absent from an older report leaves no point
  /// rather than a zero, because "not measured" is not "measured as nought".
  final List<CategoryPoint> points;

  const CategoryTrend({required this.name, required this.points});

  double? get first => points.isEmpty ? null : points.first.score;

  double? get latest => points.isEmpty ? null : points.last.score;

  /// Points gained or lost across the recorded history of this category.
  /// Null when it has been measured fewer than twice.
  int? get delta {
    if (points.length < 2) return null;
    return points.last.score.round() - points.first.score.round();
  }

  TrendDirection direction({int stableBand = kDefaultStableBand}) {
    final change = delta;
    if (change == null) return TrendDirection.unknown;
    return directionForDelta(change, stableBand: stableBand);
  }

  bool get hasTrend => points.length >= 2;

  @override
  bool operator ==(Object other) =>
      other is CategoryTrend &&
      other.name == name &&
      other.points.length == points.length &&
      _same(other.points, points);

  @override
  int get hashCode => Object.hash(name, points.length, latest);

  @override
  String toString() => 'CategoryTrend($name, ${points.length} points)';
}

bool _same(List<CategoryPoint> a, List<CategoryPoint> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
