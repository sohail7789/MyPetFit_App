/// Why an area is the one to work on.
///
/// Both values name the *weakest current area* — the reason describes what
/// else is true of it, never a different selection. See [RecommendationFocus]
/// for why the choice cannot be allowed to vary.
enum FocusReason {
  /// The lowest-scoring area, holding steady or improving.
  weakestArea,

  /// The lowest-scoring area, and still falling.
  weakestAndDeclining,
}

/// The area of health worth supporting next.
///
/// **A category name, never a product.** `Product` is a Firestore-backed type,
/// and a domain that returned one would drag cloud dependencies into every
/// context this module exists to serve — a veterinarian portal's backend, a
/// server-rendered PDF, a digest job. Analytics says *which area*; whichever
/// surface owns a catalog resolves that to merchandise.
///
/// **Always the weakest current area.** A steeper decline elsewhere is real
/// news, and the overview carries it in its own right as the biggest concern
/// — but it must not move this, because the dashboard already recommends
/// against the weakest area and two surfaces recommending different products
/// for the same pet on the same day is the inconsistency this feature was
/// built to prevent.
class RecommendationFocus {
  /// The category name, exactly as the questionnaire spells it — it is what
  /// a product's `recommendedFor` is matched against.
  final String categoryName;

  /// The area's score on the most recent assessment.
  final double score;

  final FocusReason reason;

  const RecommendationFocus({
    required this.categoryName,
    required this.score,
    required this.reason,
  });

  @override
  bool operator ==(Object other) =>
      other is RecommendationFocus &&
      other.categoryName == categoryName &&
      other.score == score &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(categoryName, score, reason);

  @override
  String toString() => 'RecommendationFocus($categoryName, ${reason.name})';
}
