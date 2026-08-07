import '../models/health_insight.dart';

/// Turns a structured finding into readable text.
///
/// Separate from both the domain and the widgets because words are their own
/// concern: a notification, an email digest, a PDF and a veterinarian's queue
/// all want the sentence and none of them want a widget. Feature 1 kept
/// insights as data precisely so this layer could exist without the
/// calculation knowing English.
///
/// **Flutter-free**, and the architecture test enforces it — a formatter that
/// reached for a `BuildContext` could not serve a background job or a
/// server-rendered report.
///
/// Subclass to change the voice. A clinical formatter for a veterinary
/// portal, or a localised one taking an already-resolved translation object,
/// changes nothing in the domain and nothing in the widgets.
abstract class InsightFormatter {
  const InsightFormatter();

  /// A phrase describing [insight].
  ///
  /// Returns a phrase, not a sentence: no trailing full stop, so a caller
  /// can punctuate it for its own context — a bullet, a notification title,
  /// a clause in a longer summary.
  String format(HealthInsight insight);
}

/// The app's own voice: plain, specific, and never overstating a movement.
class DefaultInsightFormatter extends InsightFormatter {
  const DefaultInsightFormatter();

  @override
  String format(HealthInsight insight) {
    final magnitude = (insight.deltaPoints ?? 0).abs();
    final subject = insight.subject ?? 'That area';

    // No default arm: adding a kind without teaching this method is a
    // compile error rather than a blank card in production.
    return switch (insight.kind) {
      InsightKind.overallImproved =>
        'Overall health improved by ${_points(magnitude)} '
            'since the last assessment',
      InsightKind.overallDeclined =>
        'Overall health declined by ${_points(magnitude)} '
            'since the last assessment',
      InsightKind.overallStable =>
        'Overall health held steady since the last assessment',
      InsightKind.categoryImprovedMost =>
        '$subject improved the most, up ${_points(magnitude)}',
      InsightKind.categoryDeclinedMost =>
        '$subject declined the most, down ${_points(magnitude)}',
      InsightKind.categoryImproved =>
        '$subject improved by ${_points(magnitude)}',
      InsightKind.categoryDeclined =>
        '$subject declined by ${_points(magnitude)}',
      InsightKind.firstAssessmentRecorded =>
        'First assessment recorded. Complete another to see what changes',
    };
  }

  /// "Points", not "per cent".
  ///
  /// A score moving from 60 to 72 has gained twelve points of a
  /// hundred-point scale. Calling that "12%" invites reading it as twelve
  /// per cent *of* sixty, which is a different and smaller number — and the
  /// category cards already show a bare "+12", so points keeps the two
  /// surfaces speaking the same language.
  String _points(int magnitude) =>
      magnitude == 1 ? '1 point' : '$magnitude points';
}
