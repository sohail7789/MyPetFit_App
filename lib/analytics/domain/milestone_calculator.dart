import '../../models/score_result.dart' show HealthCategory;
import '../models/assessment_series.dart';
import '../models/milestone.dart';

/// Whether a band counts as healthy.
///
/// `ScoreBand.isPositive` says the same thing, but lives behind a Flutter
/// import and so cannot be used from the domain. Stated here rather than
/// reached for, with a test asserting the two agree for every band so they
/// cannot drift.
bool isHealthyBand(HealthCategory band) =>
    band == HealthCategory.good || band == HealthCategory.excellent;

/// Health milestones earned by a subject's record.
///
/// Recomputed from the record every time rather than stored: no Firestore
/// field, no migration, and no way for a milestone to outlive the data that
/// justified it. Each reports the observation that *first* satisfied it, so
/// a UI can say when.
class MilestoneCalculator {
  /// Consecutive improvements needed for the streak milestone.
  final int streakLength;

  /// Points gained over the first recorded score for the improvement
  /// milestone.
  final int improvementPoints;

  const MilestoneCalculator({
    this.streakLength = 5,
    this.improvementPoints = 10,
  });

  /// Earned milestones, oldest first.
  List<Milestone> call(AssessmentSeries series) {
    if (series.isEmpty) return const [];

    final points = series.points;
    final earned = <Milestone>[
      Milestone(
        kind: MilestoneKind.firstAssessment,
        earnedAt: points.first.takenAt,
      ),
      if (points.length >= 3)
        Milestone(
          kind: MilestoneKind.threeAssessments,
          earnedAt: points[2].takenAt,
        ),
      if (points.length >= 10)
        Milestone(
          kind: MilestoneKind.tenAssessments,
          earnedAt: points[9].takenAt,
        ),
      ?_firstWhere(series, MilestoneKind.excellentHealth,
          (i) => points[i].band == HealthCategory.excellent),
      ?_firstWhere(
        series,
        MilestoneKind.sustainedHealthy,
        (i) =>
            i > 0 &&
            isHealthyBand(points[i].band) &&
            isHealthyBand(points[i - 1].band),
      ),
      ?_firstWhere(
        series,
        MilestoneKind.recoveredToHealthy,
        // The transition itself, not merely being healthy at some point
        // after a bad one — "recovered" describes the moment it turned.
        (i) =>
            i > 0 &&
            isHealthyBand(points[i].band) &&
            !isHealthyBand(points[i - 1].band),
      ),
      ?_firstWhere(
        series,
        MilestoneKind.tenPointImprovement,
        (i) => points[i].score - points.first.score >= improvementPoints,
      ),
      ?_streak(series),
    ];

    earned.sort((a, b) {
      final byTime = a.earnedAt.compareTo(b.earnedAt);
      // Two milestones can land on the same observation; kind order keeps
      // the list from shuffling between reads.
      return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
    });

    return earned;
  }

  /// The first observation satisfying [test], as a milestone of [kind].
  Milestone? _firstWhere(
    AssessmentSeries series,
    MilestoneKind kind,
    bool Function(int index) test,
  ) {
    for (var i = 0; i < series.length; i++) {
      if (test(i)) {
        return Milestone(kind: kind, earnedAt: series.points[i].takenAt);
      }
    }
    return null;
  }

  /// Dated at the observation completing the run, not at the newest one.
  ///
  /// A streak of seven earned this five assessments ago; reporting today's
  /// date would claim the achievement is new.
  Milestone? _streak(AssessmentSeries series) {
    var run = 0;

    for (var i = 1; i < series.length; i++) {
      run = series.points[i].score > series.points[i - 1].score ? run + 1 : 0;

      if (run >= streakLength) {
        return Milestone(
          kind: MilestoneKind.fiveConsecutiveImprovements,
          earnedAt: series.points[i].takenAt,
        );
      }
    }
    return null;
  }
}
