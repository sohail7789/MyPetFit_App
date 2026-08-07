/// What a milestone is about.
///
/// Describes the product we want, not what today's history window happens to
/// be able to demonstrate. Assessment retention is capped for now, so the
/// longer-horizon milestones cannot always be reached — that is the
/// adapter's limitation to fix, and when it is these begin working with no
/// change here.
enum MilestoneKind {
  firstAssessment,
  threeAssessments,
  tenAssessments,
  excellentHealth,

  /// Two assessments in a row at Good or better. Maintenance is the actual
  /// clinical goal, and nothing else here rewards holding steady.
  sustainedHealthy,

  /// Climbed from below Good into Good or better — the most memorable thing
  /// that can happen to a pet's record.
  recoveredToHealthy,

  tenPointImprovement,
  fiveConsecutiveImprovements,
}

/// What a milestone is evidence of.
///
/// Intrinsic to the kind rather than computed from data, and owned by the
/// domain so a dashboard, a portal and a digest group them identically
/// instead of each inventing a taxonomy.
enum MilestoneGroup {
  /// Monitoring is happening.
  consistency,

  /// A health outcome was reached or held.
  health,

  /// The record moved in the right direction.
  improvement,
}

extension MilestoneKindGroup on MilestoneKind {
  MilestoneGroup get group => switch (this) {
        MilestoneKind.firstAssessment ||
        MilestoneKind.threeAssessments ||
        MilestoneKind.tenAssessments =>
          MilestoneGroup.consistency,
        MilestoneKind.excellentHealth ||
        MilestoneKind.sustainedHealthy ||
        MilestoneKind.recoveredToHealthy =>
          MilestoneGroup.health,
        MilestoneKind.tenPointImprovement ||
        MilestoneKind.fiveConsecutiveImprovements =>
          MilestoneGroup.improvement,
      };
}

/// A health milestone a subject's record has reached.
///
/// Derived from stored history every time rather than recorded anywhere: no
/// Firestore field, no migration, and no way for a milestone to disagree
/// with the data behind it. The cost is that one can be un-earned if history
/// is removed, which is honest for a user deleting reports — and is the
/// reason durable milestones will eventually want persisting rather than
/// recomputing.
class Milestone {
  final MilestoneKind kind;

  /// The instant of the observation that first satisfied it.
  ///
  /// First, never most recent: a milestone records when something was
  /// achieved, and re-dating it every time the condition holds again would
  /// make a year-old achievement look like today's news.
  final DateTime earnedAt;

  const Milestone({required this.kind, required this.earnedAt});

  MilestoneGroup get group => kind.group;

  @override
  bool operator ==(Object other) =>
      other is Milestone && other.kind == kind && other.earnedAt == earnedAt;

  @override
  int get hashCode => Object.hash(kind, earnedAt);

  @override
  String toString() => 'Milestone(${kind.name} at $earnedAt)';
}
