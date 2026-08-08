import '../models/analytics_snapshot.dart';
import '../models/recommendation_focus.dart';
import '../models/trend_direction.dart';

/// Picks the area of health worth supporting next.
///
/// **The weakest area on the most recent assessment**, which is the rule the
/// dashboard's recommendation card has always used. Stated here so the two
/// surfaces cannot drift apart, with a test asserting they still agree.
///
/// A steeper decline elsewhere does not move the choice — the overview
/// already reports that as its biggest concern. If a decline could override
/// the selection, the dashboard and the report history would recommend
/// different products for the same pet on the same day.
///
/// Reads only what the snapshot already computed: the latest observation's
/// category scores and, for the reason, the category trends. No second walk
/// of the history.
class FocusCalculator {
  /// Movement smaller than this is not treated as a decline.
  final int stableBand;

  const FocusCalculator({this.stableBand = kDefaultStableBand});

  /// The focus area, or null when there is nothing to choose from.
  ///
  /// Null with no history, and also when the latest assessment carries no
  /// category breakdown — records written before `categoryScores` existed
  /// decode to an empty map, and picking a focus from nothing would be
  /// inventing one. The dashboard falls back the same way.
  RecommendationFocus? call(AnalyticsSnapshot snapshot) {
    final latest = snapshot.series.latest;
    if (latest == null || latest.categoryScores.isEmpty) return null;

    // Ties break on the name, so two areas scoring the same cannot shuffle
    // the recommendation between two reads of an unchanged record.
    MapEntry<String, double>? weakest;
    for (final entry in latest.categoryScores.entries) {
      if (weakest == null ||
          entry.value < weakest.value ||
          (entry.value == weakest.value && entry.key.compareTo(weakest.key) < 0)) {
        weakest = entry;
      }
    }

    return RecommendationFocus(
      categoryName: weakest!.key,
      score: weakest.value,
      reason: _falling(snapshot, weakest.key)
          ? FocusReason.weakestAndDeclining
          : FocusReason.weakestArea,
    );
  }

  /// Whether [name] has fallen across its recorded history by more than the
  /// questionnaire can resolve.
  ///
  /// Read from the snapshot's own trends rather than recomputed, so the
  /// reason given here agrees with the direction the category card shows.
  bool _falling(AnalyticsSnapshot snapshot, String name) {
    for (final trend in snapshot.categoryTrends) {
      if (trend.name != name) continue;
      return trend.direction(stableBand: stableBand) == TrendDirection.declining;
    }
    return false;
  }
}
