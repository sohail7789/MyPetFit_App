import '../models/milestone.dart';

/// Turns a milestone into readable text.
///
/// Flutter-free, and the architecture test enforces it — a digest email or a
/// server-rendered summary wants these words with no widget involved.
///
/// Subclass to change the voice. A veterinary portal wanting clinical
/// phrasing changes nothing in the domain and nothing in the widgets.
abstract class MilestoneFormatter {
  const MilestoneFormatter();

  /// A short name for the milestone.
  String title(MilestoneKind kind);

  /// What it means, in one phrase.
  ///
  /// A phrase, not a sentence: no trailing full stop, so a caller punctuates
  /// for its own context.
  String description(MilestoneKind kind);

  /// A name for a group of milestones.
  String groupTitle(MilestoneGroup group);
}

/// The app's own voice: warm, specific, and about the pet rather than the
/// app.
///
/// Deliberately not congratulatory boilerplate. These describe things that
/// happened to an animal's health record — a badge that reads like a game
/// reward would cheapen a record an owner may be taking to a vet.
class DefaultMilestoneFormatter extends MilestoneFormatter {
  const DefaultMilestoneFormatter();

  @override
  String title(MilestoneKind kind) => switch (kind) {
        MilestoneKind.firstAssessment => 'First assessment',
        MilestoneKind.threeAssessments => 'Three assessments',
        MilestoneKind.tenAssessments => 'Ten assessments',
        MilestoneKind.excellentHealth => 'Excellent health',
        MilestoneKind.sustainedHealthy => 'Sustained healthy',
        MilestoneKind.recoveredToHealthy => 'Back to healthy',
        MilestoneKind.tenPointImprovement => 'Ten points gained',
        MilestoneKind.fiveConsecutiveImprovements => 'Five in a row',
      };

  @override
  String description(MilestoneKind kind) => switch (kind) {
        MilestoneKind.firstAssessment =>
          'A baseline everything else is measured against',
        MilestoneKind.threeAssessments =>
          'Checking in regularly enough to see a pattern',
        MilestoneKind.tenAssessments =>
          'A long record, and the clearest picture of how things change',
        MilestoneKind.excellentHealth =>
          'Reached the highest band on the assessment',
        MilestoneKind.sustainedHealthy =>
          'Held Good or better across two assessments in a row',
        MilestoneKind.recoveredToHealthy =>
          'Came back up into Good after scoring below it',
        MilestoneKind.tenPointImprovement =>
          'Ten points above the first recorded score',
        MilestoneKind.fiveConsecutiveImprovements =>
          'Five assessments in a row, each better than the last',
      };

  @override
  String groupTitle(MilestoneGroup group) => switch (group) {
        MilestoneGroup.consistency => 'Keeping track',
        MilestoneGroup.health => 'Health reached',
        MilestoneGroup.improvement => 'Progress made',
      };
}
