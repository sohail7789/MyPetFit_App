import '../models/analytics_overview.dart';
import '../models/analytics_snapshot.dart';
import '../models/assessment_cadence.dart';
import '../models/category_trend.dart';
import '../models/trend_direction.dart';
import 'focus_calculator.dart';

/// Builds the executive summary from an already-computed snapshot.
///
/// **Selection, not calculation.** Every figure it reports is lifted from the
/// snapshot: the score and band from the summary, the leading finding from
/// the insights, the milestone count from the milestones. Nothing is derived
/// a second time, which is what guarantees the overview and the detailed
/// sections beneath it tell the same story — and keeps the work to one pass
/// over the category trends the snapshot already holds, with everything else
/// constant time.
///
/// **The clock is a parameter.** [now] is required and never defaulted: the
/// domain reads no clock, so a test can hand it any day and a cached snapshot
/// can be re-read at a later instant to move a countdown on. It is also why
/// the overview is not part of [AnalyticsSnapshot] — a snapshot is cached and
/// immutable, and a due date baked into one would freeze.
class OverviewCalculator {
  final FocusCalculator focus;
  final AssessmentCadence cadence;

  /// Movement smaller than this is not reported as an improvement or a
  /// concern. Matched to the questionnaire's resolution — see
  /// [kDefaultStableBand].
  final int stableBand;

  const OverviewCalculator({
    this.focus = const FocusCalculator(),
    this.cadence = AssessmentCadence.standard,
    this.stableBand = kDefaultStableBand,
  });

  AnalyticsOverview call(AnalyticsSnapshot snapshot, {required DateTime now}) {
    if (!snapshot.hasHistory) return AnalyticsOverview.none;

    final summary = snapshot.summary;
    final statistics = summary.statistics;
    final (improvement, concern) = _extremeMovements(snapshot.categoryTrends);

    return AnalyticsOverview(
      score: statistics.latestScore,
      band: summary.currentBand,
      direction: summary.direction,
      changeSincePrevious: summary.changeSincePrevious,
      // The calculator already weighted and capped these; the leading one is
      // the leading one, and re-ranking here would be a second opinion.
      topInsight: snapshot.insights.isEmpty ? null : snapshot.insights.first,
      biggestImprovement: improvement,
      biggestConcern: concern,
      // Milestones arrive oldest first, so the most recent is the last.
      latestMilestone:
          snapshot.milestones.isEmpty ? null : snapshot.milestones.last,
      milestoneCount: snapshot.milestones.length,
      focus: focus(snapshot),
      lastAssessmentAt: statistics.latestAssessmentAt,
      nextAssessment: cadence.dueFrom(statistics.latestAssessmentAt, now: now),
      assessmentCount: statistics.assessmentCount,
    );
  }

  /// The largest rise and the largest fall across the recorded history.
  ///
  /// One pass, and only over trends the snapshot already computed. Movements
  /// inside the stable band are excluded rather than reported as small ones:
  /// a two-point drift is not the pet's biggest concern, it is noise, and
  /// naming it as such would send an owner after nothing.
  ///
  /// Categories measured once carry no delta and are skipped — "not compared"
  /// is not "did not move".
  (CategoryTrend?, CategoryTrend?) _extremeMovements(
    List<CategoryTrend> trends,
  ) {
    CategoryTrend? improvement;
    CategoryTrend? concern;

    for (final trend in trends) {
      final delta = trend.delta;
      if (delta == null || delta.abs() <= stableBand) continue;

      if (delta > 0) {
        // Ties break on the name so an unchanged record always summarises
        // the same way.
        if (improvement == null ||
            delta > improvement.delta! ||
            (delta == improvement.delta! &&
                trend.name.compareTo(improvement.name) < 0)) {
          improvement = trend;
        }
      } else {
        if (concern == null ||
            delta < concern.delta! ||
            (delta == concern.delta! &&
                trend.name.compareTo(concern.name) < 0)) {
          concern = trend;
        }
      }
    }

    return (improvement, concern);
  }
}
