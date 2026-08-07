/// A milestone a subject's history has reached.
enum AchievementKind {
  firstAssessment,
  threeAssessments,
  tenAssessments,
  excellentHealth,
  tenPercentImprovement,
  fiveConsecutiveImprovements,
}

/// An earned milestone.
///
/// Derived from stored history every time rather than recorded anywhere: no
/// Firestore field, no migration, and no way for a badge to disagree with the
/// data behind it. The cost is that a milestone can be un-earned if history
/// is deleted, which is the honest behaviour.
class Achievement {
  final AchievementKind kind;

  /// The instant of the observation that satisfied it.
  final DateTime earnedAt;

  const Achievement({required this.kind, required this.earnedAt});

  @override
  bool operator ==(Object other) =>
      other is Achievement &&
      other.kind == kind &&
      other.earnedAt == earnedAt;

  @override
  int get hashCode => Object.hash(kind, earnedAt);

  @override
  String toString() => 'Achievement(${kind.name} at $earnedAt)';
}
