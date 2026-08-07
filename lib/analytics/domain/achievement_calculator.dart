import '../models/achievement.dart';
import '../models/assessment_series.dart';
import '../../models/score_result.dart' show HealthCategory;
import 'trend_calculator.dart';

/// Milestones earned by a subject's history.
///
/// Recomputed from the record every time rather than stored anywhere: no
/// Firestore field, no migration, and no way for a badge to outlive the data
/// that justified it. Each milestone reports the observation that earned it,
/// so a UI can say when.
class AchievementCalculator {
  final TrendCalculator trend;

  const AchievementCalculator({this.trend = const TrendCalculator()});

  /// Earned milestones, oldest first.
  List<Achievement> call(AssessmentSeries series) {
    if (series.isEmpty) return const [];

    final earned = <Achievement>[];
    final points = series.points;

    earned.add(
      Achievement(
        kind: AchievementKind.firstAssessment,
        earnedAt: points.first.takenAt,
      ),
    );

    if (points.length >= 3) {
      earned.add(
        Achievement(
          kind: AchievementKind.threeAssessments,
          earnedAt: points[2].takenAt,
        ),
      );
    }

    if (points.length >= 10) {
      earned.add(
        Achievement(
          kind: AchievementKind.tenAssessments,
          earnedAt: points[9].takenAt,
        ),
      );
    }

    // The first time the band was reached, not the most recent — a milestone
    // records when something was achieved.
    for (final point in points) {
      if (point.band == HealthCategory.excellent) {
        earned.add(
          Achievement(
            kind: AchievementKind.excellentHealth,
            earnedAt: point.takenAt,
          ),
        );
        break;
      }
    }

    final firstScore = points.first.score;
    for (final point in points) {
      if (point.score - firstScore >= 10) {
        earned.add(
          Achievement(
            kind: AchievementKind.tenPercentImprovement,
            earnedAt: point.takenAt,
          ),
        );
        break;
      }
    }

    if (trend.improvementStreak(series) >= 5) {
      earned.add(
        Achievement(
          kind: AchievementKind.fiveConsecutiveImprovements,
          earnedAt: points.last.takenAt,
        ),
      );
    }

    earned.sort((a, b) {
      final byTime = a.earnedAt.compareTo(b.earnedAt);
      // Two milestones can land on the same observation; kind order keeps
      // the list from shuffling between reads.
      return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
    });

    return earned;
  }
}
