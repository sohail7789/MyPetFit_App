/// What an insight is about.
///
/// A closed set so every consumer can render all of them — a switch with no
/// default is what makes an unhandled kind a compile error rather than a
/// blank card in production.
enum InsightKind {
  overallImproved,
  overallDeclined,
  overallStable,
  categoryImprovedMost,
  categoryDeclinedMost,
  categoryImproved,
  categoryDeclined,
  firstAssessmentRecorded,
}

/// A single deterministic finding about a subject's history.
///
/// **Data, not a sentence.** The wording lives in the presentation layer for
/// three reasons: Hindi and Marathi are already pending in LocaleProvider and
/// an English string baked in here would have to be torn out; a veterinary
/// portal wants clinical phrasing from the identical computation a consumer
/// app phrases warmly; and a test asserts a value rather than matching prose.
class HealthInsight {
  final InsightKind kind;

  /// The category this concerns, or null for whole-pet findings.
  final String? subject;

  /// Points gained or lost, signed. Null where the kind carries no movement.
  final int? deltaPoints;

  /// Ordering hint, highest first. Derived from the size of the movement, so
  /// a screen showing only the top few shows the ones that matter most.
  final int weight;

  const HealthInsight({
    required this.kind,
    this.subject,
    this.deltaPoints,
    this.weight = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is HealthInsight &&
      other.kind == kind &&
      other.subject == subject &&
      other.deltaPoints == deltaPoints &&
      other.weight == weight;

  @override
  int get hashCode => Object.hash(kind, subject, deltaPoints, weight);

  @override
  String toString() =>
      'HealthInsight(${kind.name}, $subject, $deltaPoints)';
}
