import '../models/assessment_series.dart';
import '../models/trend_direction.dart';

/// The overall movement of a subject's score.
class TrendCalculator {
  final int stableBand;

  const TrendCalculator({this.stableBand = kDefaultStableBand});

  /// Points gained or lost since the previous observation, or null when
  /// there is nothing to compare against.
  int? changeSincePrevious(AssessmentSeries series) {
    if (!series.hasTrend) return null;
    return series.latest!.score - series.previous!.score;
  }

  /// Points gained or lost across the whole recorded history.
  int? changeSinceFirst(AssessmentSeries series) {
    if (!series.hasTrend) return null;
    return series.latest!.score - series.first!.score;
  }

  /// Which way the most recent observation moved.
  ///
  /// Against the previous observation rather than the first: "is my pet
  /// improving" is a question about the latest change, and a subject who
  /// climbed for a year then fell sharply is not improving today.
  TrendDirection direction(AssessmentSeries series) {
    final change = changeSincePrevious(series);
    if (change == null) return TrendDirection.unknown;
    return directionForDelta(change, stableBand: stableBand);
  }

  /// How many observations in a row improved, counting back from the latest.
  ///
  /// Strictly greater each time — a flat result breaks the run, because a
  /// streak is a claim about consecutive progress.
  int improvementStreak(AssessmentSeries series) {
    if (!series.hasTrend) return 0;

    var streak = 0;
    for (var i = series.length - 1; i > 0; i--) {
      if (series.points[i].score > series.points[i - 1].score) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
