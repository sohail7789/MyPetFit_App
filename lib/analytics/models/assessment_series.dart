import 'assessment_point.dart';

/// Everything analytics knows about one subject, in time order.
///
/// **Points run oldest first.** Every calculation here reads a history
/// left-to-right — a trend, a streak, an evolution — and one stated
/// direction is what stops a sign error hiding in a comparison. The app's
/// providers hand back newest-first; reversing them is the adapter's job,
/// once, at the boundary.
///
/// The subject is a pet today. It is a plain id so the same series can later
/// describe a household, a clinic's patient, or anything else worth trending
/// without the type changing.
class AssessmentSeries {
  final String subjectId;

  /// Oldest first. Never mutate — construct a new series instead.
  final List<AssessmentPoint> points;

  const AssessmentSeries({required this.subjectId, required this.points});

  /// A subject with nothing recorded yet.
  const AssessmentSeries.empty(this.subjectId) : points = const [];

  int get length => points.length;

  bool get isEmpty => points.isEmpty;

  bool get isNotEmpty => points.isNotEmpty;

  /// True once there is something to compare against.
  ///
  /// Guards every derived trend: one observation is a reading, not a
  /// direction, and inventing one from a single point is the fabrication
  /// this module is built to avoid.
  bool get hasTrend => points.length >= 2;

  AssessmentPoint? get first => points.isEmpty ? null : points.first;

  AssessmentPoint? get latest => points.isEmpty ? null : points.last;

  /// The observation before [latest], when there is one.
  AssessmentPoint? get previous =>
      points.length < 2 ? null : points[points.length - 2];

  /// Every category name seen anywhere in the series, in first-seen order.
  ///
  /// Union rather than intersection: a category added to the questionnaire
  /// after an old assessment, or dropped from a later one, still belongs to
  /// the subject's history. Dropping it would quietly rewrite the past.
  List<String> get categoryNames {
    final seen = <String>[];
    for (final point in points) {
      for (final name in point.categoryScores.keys) {
        if (!seen.contains(name)) seen.add(name);
      }
    }
    return seen;
  }

  /// A cheap value that changes whenever the series does.
  ///
  /// Used to decide whether a cached computation is still valid. Length and
  /// the newest instant together cover every way this list moves in practice
  /// — an assessment added, history restored, the subject switched — without
  /// walking every point on each frame.
  String get identity =>
      '$subjectId/${points.length}/${latest?.takenAt.toUtc().toIso8601String() ?? '-'}';

  @override
  bool operator ==(Object other) =>
      other is AssessmentSeries &&
      other.subjectId == subjectId &&
      other.points.length == points.length &&
      _samePoints(other.points, points);

  @override
  int get hashCode => Object.hash(subjectId, points.length, latest?.id);

  @override
  String toString() => 'AssessmentSeries($subjectId, ${points.length} points)';
}

bool _samePoints(List<AssessmentPoint> a, List<AssessmentPoint> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
