import '../../models/score_result.dart' show HealthCategory;
import '../models/analytics_overview.dart';
import '../models/assessment_cadence.dart';
import '../models/category_trend.dart';
import '../models/health_insight.dart';
import '../models/milestone.dart';
import '../models/recommendation_focus.dart';
import '../models/trend_direction.dart';
import 'insight_formatter.dart';
import 'milestone_formatter.dart';

/// Turns an executive summary into readable text.
///
/// Flutter-free, like the formatters it composes, so an email digest, a PDF
/// cover page or a server-rendered portal can produce the same summary with
/// no widget involved.
///
/// Every heading is a method rather than a constant, because a veterinarian
/// portal calling it "Presenting concern" and a consumer app calling it
/// "Biggest concern" should be one subclass apart. Extend
/// [DefaultOverviewFormatter] to change only part of the voice.
abstract class OverviewFormatter {
  const OverviewFormatter();

  String get title;
  String get subtitle;

  String get scoreLabel;
  String get insightLabel;
  String get improvementLabel;
  String get concernLabel;
  String get milestoneLabel;
  String get focusLabel;
  String get lastAssessedLabel;
  String get nextAssessmentLabel;

  /// The band's own name.
  String band(HealthCategory band);

  /// Which way the pet is going, or null when nothing can be claimed.
  String? trend(TrendDirection direction);

  /// The movement behind that direction, or null when there is none.
  String? change(int? points);

  /// The leading finding, in words.
  String insight(HealthInsight insight);

  /// An area and how far it has moved.
  String movement(CategoryTrend trend);

  /// The most recent milestone, and how many there are in total.
  String milestones(Milestone latest, int total);

  /// The area to support next.
  String focus(RecommendationFocus focus);

  /// Why that area was chosen.
  String focusReason(FocusReason reason);

  /// How long ago the record was last brought up to date.
  String lastAssessed(DateTime when, {required DateTime now});

  /// When the next assessment falls due.
  String nextAssessment(AssessmentDue due);

  /// The whole summary as one passage, for a screen reader.
  ///
  /// A reader arriving at this card should hear what their pet's record says,
  /// not nine disconnected labels they must assemble themselves.
  String spoken(AnalyticsOverview overview, {required DateTime now});
}

/// The app's own voice: plain, specific, and never overstating a movement.
class DefaultOverviewFormatter extends OverviewFormatter {
  /// Composed rather than restated, so the summary's wording for a finding is
  /// the wording the detailed section below it already used.
  final InsightFormatter insights;
  final MilestoneFormatter milestoneNames;

  const DefaultOverviewFormatter({
    this.insights = const DefaultInsightFormatter(),
    this.milestoneNames = const DefaultMilestoneFormatter(),
  });

  @override
  String get title => 'Health overview';

  @override
  String get subtitle => 'Your pet’s recorded history at a glance.';

  @override
  String get scoreLabel => 'Overall health score';

  @override
  String get insightLabel => 'Top insight';

  @override
  String get improvementLabel => 'Biggest improvement';

  @override
  String get concernLabel => 'Biggest concern';

  @override
  String get milestoneLabel => 'Health milestones';

  @override
  String get focusLabel => 'Focus area';

  @override
  String get lastAssessedLabel => 'Last assessed';

  @override
  String get nextAssessmentLabel => 'Next assessment';

  @override
  String band(HealthCategory band) => band.label;

  @override
  String? trend(TrendDirection direction) => switch (direction) {
        TrendDirection.improving => 'Improving',
        TrendDirection.declining => 'Declining',
        TrendDirection.stable => 'Holding steady',
        // Nothing to compare against. A dash or a "—" would still occupy the
        // line as though something were being said.
        TrendDirection.unknown => null,
      };

  @override
  String? change(int? points) {
    if (points == null) return null;
    if (points == 0) return 'No change since your previous assessment';

    final direction = points > 0 ? 'up' : 'down';
    return '$direction ${_points(points.abs())} '
        'since your previous assessment';
  }

  @override
  String insight(HealthInsight insight) => insights.format(insight);

  @override
  String movement(CategoryTrend trend) {
    final delta = trend.delta;
    if (delta == null) return trend.name;

    final direction = delta > 0 ? 'Up' : 'Down';
    // "Recorded history", not "since you started": retention is capped, and
    // this is honest about the window analytics can actually see.
    return '$direction ${_points(delta.abs())} across your recorded history';
  }

  @override
  String milestones(Milestone latest, int total) {
    final name = milestoneNames.title(latest.kind);
    return total <= 1 ? name : '$name, and ${total - 1} more';
  }

  @override
  String focus(RecommendationFocus focus) => focus.categoryName;

  @override
  String focusReason(FocusReason reason) => switch (reason) {
        FocusReason.weakestArea => 'The lowest-scoring area on the last '
            'assessment',
        FocusReason.weakestAndDeclining => 'The lowest-scoring area, and '
            'still falling',
      };

  /// Coarsens as it recedes: exact days for the first week, then weeks, then
  /// months. Whether the record is current is what matters here, not that it
  /// was brought up to date forty-three days ago.
  ///
  /// A future date reads as today. Handsets sync records to each other and
  /// their clocks disagree; a day of imprecision beats "in -1 days".
  @override
  String lastAssessed(DateTime when, {required DateTime now}) {
    final days = _daysBetween(when, now);

    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 14) return 'Last week';
    if (days < 30) return '${days ~/ 7} weeks ago';
    if (days < 60) return 'Last month';
    if (days < 365) return '${days ~/ 30} months ago';
    return 'Over a year ago';
  }

  /// Plain and unhurried. An overdue assessment is a prompt, not an alarm —
  /// the assessment is a screening aid, and language that frightens an owner
  /// about a date is language they will learn to dismiss.
  @override
  String nextAssessment(AssessmentDue due) => switch (due.state) {
        AssessmentDueState.dueToday => 'Due today',
        AssessmentDueState.upcoming =>
          due.days == 1 ? 'Due tomorrow' : 'Due in ${due.days} days',
        AssessmentDueState.overdue => due.days == 1
            ? 'Overdue by 1 day'
            : 'Overdue by ${due.days} days',
      };

  @override
  String spoken(AnalyticsOverview overview, {required DateTime now}) {
    final parts = <String>[];

    final score = overview.score;
    final band = overview.band;
    if (score != null) {
      parts.add(band == null
          ? '$scoreLabel $score'
          : '$scoreLabel $score, ${this.band(band)}');
    }

    final direction = trend(overview.direction);
    final movement = change(overview.changeSincePrevious);
    if (direction != null) {
      parts.add(movement == null ? direction : '$direction, $movement');
    }

    final insight = overview.topInsight;
    if (insight != null) parts.add('$insightLabel: ${this.insight(insight)}');

    final improvement = overview.biggestImprovement;
    if (improvement != null) {
      parts.add('$improvementLabel: ${improvement.name}, '
          '${this.movement(improvement).toLowerCase()}');
    }

    final concern = overview.biggestConcern;
    if (concern != null) {
      parts.add('$concernLabel: ${concern.name}, '
          '${this.movement(concern).toLowerCase()}');
    }

    final milestone = overview.latestMilestone;
    if (milestone != null) {
      parts.add('$milestoneLabel: '
          '${milestones(milestone, overview.milestoneCount)}');
    }

    final focus = overview.focus;
    if (focus != null) {
      parts.add('$focusLabel: ${this.focus(focus)}, '
          '${focusReason(focus.reason).toLowerCase()}');
    }

    final last = overview.lastAssessmentAt;
    if (last != null) {
      parts.add('$lastAssessedLabel ${lastAssessed(last, now: now).toLowerCase()}');
    }

    final due = overview.nextAssessment;
    if (due != null) {
      parts.add('$nextAssessmentLabel ${nextAssessment(due).toLowerCase()}');
    }

    return parts.isEmpty ? title : '$title. ${parts.join('. ')}';
  }

  /// "Points", not "per cent" — the same reasoning as the insight formatter's.
  String _points(int magnitude) =>
      magnitude == 1 ? '1 point' : '$magnitude points';
}

/// Whole days from [when] to [now], counted in local calendar days.
///
/// A UTC anchor on each local date, so a daylight-saving transition cannot
/// make a difference of one day arrive an hour short.
int _daysBetween(DateTime when, DateTime now) {
  final from = when.toLocal();
  final to = now.toLocal();

  return DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;
}
