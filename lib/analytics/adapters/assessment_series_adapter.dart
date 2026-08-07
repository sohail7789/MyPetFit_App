import '../../models/score_result.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../models/assessment_point.dart';
import '../models/assessment_series.dart';

/// The only place analytics knows the rest of the app exists.
///
/// Everything under `analytics/models`, `analytics/domain` and
/// `analytics/services` is pure Dart over [AssessmentSeries]. This file is
/// the seam that fills one from the app's providers, and it is the single
/// file that changes when the source does:
///
/// * raising the assessment retention cap — see the note on [fromQuiz]
/// * reading history from a paged Firestore query instead of memory
/// * folding in smart collar readings, vet notes or nutrition logs
/// * serving a veterinarian portal from a different backend entirely
///
/// None of those reach the domain, the widgets or the screens.
class AssessmentSeriesAdapter {
  const AssessmentSeriesAdapter();

  /// Builds the active pet's history from the app's providers.
  ///
  /// Returns an empty series when there is no active pet, rather than null:
  /// a subject with nothing recorded is a state analytics renders, and a
  /// null would push that decision into every caller.
  ///
  /// **Known limitation, deliberately not solved here.**
  /// [QuizProvider.maxHistory] caps the retained history at five per pet, and
  /// the cap is applied when a new assessment is scored but not after a cloud
  /// restore — so the window this reads is not a fixed size. Firestore holds
  /// the complete record. Analytics therefore describes "the assessments on
  /// this device", which is honest but is not the ten-year history the module
  /// is built for. Raising the cap is a product decision about storage and
  /// sync, tracked separately; when it lands, this method is what changes.
  AssessmentSeries fromQuiz({
    required QuizProvider quiz,
    required PetInfoProvider pets,
  }) {
    final pet = pets.activePet;
    if (pet == null) return const AssessmentSeries.empty('');

    return fromResults(subjectId: pet.id, results: quiz.historyFor(pet.id));
  }

  /// Converts stored assessments into a series.
  ///
  /// Separate from [fromQuiz] so the conversion is testable without standing
  /// up providers, and so any future source can reuse it.
  ///
  /// [results] arrives newest first, which is how the app's history reads
  /// everywhere else. The series is chronological, so this is the one place
  /// the order flips — stated once, here, rather than assumed in every
  /// calculation.
  AssessmentSeries fromResults({
    required String subjectId,
    required List<ScoreResult> results,
  }) {
    final ordered = [...results]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    return AssessmentSeries(
      subjectId: subjectId,
      points: [
        for (final result in ordered)
          AssessmentPoint(
            id: AssessmentPoint.idFor(subjectId, result.completedAt),
            takenAt: result.completedAt,
            score: result.percentageScore,
            // Both read straight off the record. Re-deriving the band from
            // the score, or the score from the raw answers, would let a
            // historical report drift from what it said when it was filed.
            band: result.category,
            categoryScores: Map.unmodifiable(result.categoryScores),
          ),
      ],
    );
  }
}
