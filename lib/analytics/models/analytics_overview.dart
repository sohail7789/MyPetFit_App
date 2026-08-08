import '../../models/score_result.dart' show HealthCategory;
import 'assessment_cadence.dart';
import 'category_trend.dart';
import 'health_insight.dart';
import 'milestone.dart';
import 'recommendation_focus.dart';
import 'trend_direction.dart';

/// The executive summary of a subject's health record.
///
/// Nine answers, each of which a reader should be able to take in within a
/// few seconds: where the pet stands, which way it is going, what changed,
/// what is working, what is not, what has been achieved, what to support, and
/// when the record was last and next brought up to date.
///
/// **Selected from an [AnalyticsSnapshot], never recomputed.** Every field
/// here is a value the snapshot already holds. That is what makes it
/// impossible for this summary to contradict the detailed sections rendered
/// beneath it — not care, not review, but the absence of a second
/// calculation that could disagree.
///
/// **Nothing is inferred to fill a gap.** Six of these can legitimately be
/// unknown, and every one of them is nullable for that reason. A pet with one
/// assessment has a score and a band but no direction; saying "stable" there
/// would be a claim about a comparison that was never made.
///
/// Flutter-free and provider-free, so a dashboard, a veterinarian portal, a
/// web client, a PDF cover page and an email digest can all be handed the
/// same value.
class AnalyticsOverview {
  /// The most recent overall score.
  final int? score;

  /// The band that score was filed under.
  final HealthCategory? band;

  /// Movement into the latest assessment.
  ///
  /// [TrendDirection.unknown] until there are two to compare — never
  /// [TrendDirection.stable], which would claim nothing changed.
  final TrendDirection direction;

  /// Points gained or lost since the previous assessment.
  final int? changeSincePrevious;

  /// The finding that carried the most weight.
  final HealthInsight? topInsight;

  /// The area that has risen most across the recorded history, past the point
  /// where a movement is distinguishable from noise.
  final CategoryTrend? biggestImprovement;

  /// The area that has fallen most across the recorded history.
  ///
  /// "Concern" rather than "problem": the assessment is a screening aid, and
  /// a falling area is something to look at, not a diagnosis.
  final CategoryTrend? biggestConcern;

  /// The most recently earned milestone.
  final Milestone? latestMilestone;

  /// How many have been earned in total, so a summary can say "and 4 more"
  /// without being handed the list.
  final int milestoneCount;

  /// The area worth supporting next, as a category name.
  final RecommendationFocus? focus;

  /// When the most recent assessment was completed.
  final DateTime? lastAssessmentAt;

  /// Where the record stands against the retake cadence.
  ///
  /// The one field here that depends on a clock, which is why an overview is
  /// derived at the moment it is shown rather than cached inside a snapshot.
  final AssessmentDue? nextAssessment;

  /// How many assessments the *recorded history* holds.
  ///
  /// Recorded, not lifetime: retention is capped per pet today, so this
  /// counts what analytics can see rather than everything that ever happened.
  final int assessmentCount;

  const AnalyticsOverview({
    this.score,
    this.band,
    this.direction = TrendDirection.unknown,
    this.changeSincePrevious,
    this.topInsight,
    this.biggestImprovement,
    this.biggestConcern,
    this.latestMilestone,
    this.milestoneCount = 0,
    this.focus,
    this.lastAssessmentAt,
    this.nextAssessment,
    this.assessmentCount = 0,
  });

  /// A subject with nothing recorded. Every answer absent, none invented.
  static const AnalyticsOverview none = AnalyticsOverview();

  bool get hasHistory => assessmentCount > 0;

  /// True once a direction can honestly be claimed.
  bool get hasTrend => direction != TrendDirection.unknown;

  /// Whether there is anything at all worth rendering.
  bool get isEmpty => !hasHistory;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsOverview &&
      other.score == score &&
      other.band == band &&
      other.direction == direction &&
      other.changeSincePrevious == changeSincePrevious &&
      other.topInsight == topInsight &&
      other.biggestImprovement == biggestImprovement &&
      other.biggestConcern == biggestConcern &&
      other.latestMilestone == latestMilestone &&
      other.milestoneCount == milestoneCount &&
      other.focus == focus &&
      other.lastAssessmentAt == lastAssessmentAt &&
      other.nextAssessment == nextAssessment &&
      other.assessmentCount == assessmentCount;

  @override
  int get hashCode => Object.hash(
        score,
        band,
        direction,
        changeSincePrevious,
        topInsight,
        biggestImprovement,
        biggestConcern,
        latestMilestone,
        milestoneCount,
        focus,
        lastAssessmentAt,
        nextAssessment,
        assessmentCount,
      );
}
