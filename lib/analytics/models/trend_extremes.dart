import 'assessment_point.dart';
import 'assessment_series.dart';

/// The observations a trend surface calls out.
///
/// One value rather than a scatter of ids: a graph marking the peak, the
/// trough and the current standing wants all three together, and a caller
/// that has to assemble them from separate fields will eventually assemble
/// them inconsistently.
///
/// Carries the points themselves, not references to them, so a consumer can
/// label a marker with a date and a band without another lookup.
class TrendExtremes {
  /// The highest-scoring observation. On a tie, the earliest — a peak is
  /// marked when it was first reached, matching how milestones are dated.
  final AssessmentPoint best;

  /// The lowest-scoring observation, earliest on a tie.
  final AssessmentPoint worst;

  /// The most recent observation, which is the pet's current standing.
  final AssessmentPoint latest;

  const TrendExtremes({
    required this.best,
    required this.worst,
    required this.latest,
  });

  /// Null for an empty history — there is no peak in no data.
  static TrendExtremes? of(AssessmentSeries series) {
    if (series.isEmpty) return null;

    var best = series.points.first;
    var worst = series.points.first;

    for (final point in series.points) {
      // Strictly greater / less, so the earliest of equal scores wins.
      if (point.score > best.score) best = point;
      if (point.score < worst.score) worst = point;
    }

    return TrendExtremes(best: best, worst: worst, latest: series.latest!);
  }

  /// True when one observation is doing more than one job — a single-point
  /// history is its own best, worst and latest, and a surface that draws
  /// three markers on one dot looks broken.
  bool get areDistinct =>
      best.id != worst.id && best.id != latest.id && worst.id != latest.id;

  /// Whether [pointId] is worth marking at all.
  bool marks(String pointId) =>
      pointId == best.id || pointId == worst.id || pointId == latest.id;

  @override
  bool operator ==(Object other) =>
      other is TrendExtremes &&
      other.best == best &&
      other.worst == worst &&
      other.latest == latest;

  @override
  int get hashCode => Object.hash(best, worst, latest);
}
