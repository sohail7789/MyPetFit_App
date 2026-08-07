import '../../models/score_result.dart' show HealthCategory;

/// One health observation, as analytics sees it.
///
/// Deliberately not a [ScoreResult]. A stored assessment is what feeds this
/// today, but a smart collar reading, a vet's recorded examination or a
/// nutrition log are the same shape to a trend: an instant, a score, a band
/// and a per-area breakdown. Keeping analytics on its own input type means a
/// new source writes an adapter rather than the whole module changing.
///
/// [HealthCategory] is reused rather than mirrored — it is the product's
/// health vocabulary, and a parallel enum would need mapping forever.
class AssessmentPoint {
  /// Stable across rebuilds, reloads and reorderings.
  ///
  /// Never a list position. Sprint 2 established why: history is bound to
  /// the active pet and trimmed as it grows, so an index addresses a
  /// different record depending on when you look. Derived from the subject
  /// and the instant, which together identify an observation — nobody
  /// completes two assessments in the same millisecond.
  final String id;

  /// When the observation was made, in UTC.
  final DateTime takenAt;

  /// The overall score, 0–100, exactly as it was stored.
  final int score;

  /// The band stored with the observation.
  ///
  /// Carried rather than re-derived from [score]: a historical record must
  /// read the way it was filed, even if the band cutoffs ever move.
  final HealthCategory band;

  /// Per-area scores, keyed by category name, exactly as stored.
  final Map<String, double> categoryScores;

  const AssessmentPoint({
    required this.id,
    required this.takenAt,
    required this.score,
    required this.band,
    this.categoryScores = const {},
  });

  /// Builds the identity for a subject's observation at an instant.
  static String idFor(String subjectId, DateTime takenAt) =>
      '$subjectId@${takenAt.toUtc().toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      other is AssessmentPoint &&
      other.id == id &&
      other.takenAt == takenAt &&
      other.score == score &&
      other.band == band &&
      _sameScores(other.categoryScores, categoryScores);

  @override
  int get hashCode => Object.hash(id, takenAt, score, band);

  @override
  String toString() => 'AssessmentPoint($id, $score, ${band.name})';
}

bool _sameScores(Map<String, double> a, Map<String, double> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
