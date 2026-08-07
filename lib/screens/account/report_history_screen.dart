import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../analytics/adapters/assessment_series_adapter.dart';
import '../../analytics/models/assessment_point.dart';
import '../../analytics/services/analytics_cache.dart';
import '../../analytics/widgets/analytics_empty_state.dart';
import '../../analytics/widgets/category_evolution_list.dart';
import '../../analytics/widgets/insight_list.dart';
import '../../analytics/widgets/trend_graph.dart';
import '../../models/pet_info.dart';
import '../../models/score_band.dart';
import '../../models/score_result.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import '../../widgets/photo_slot.dart';

/// Screen 32 — Report history (the Report tab).
class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final history = quiz.assessmentHistory;
    // select, not watch: the timeline needs the pet's name and photo, and
    // `activePet` is the same instance until the selection or the record
    // changes, so this rebuilds when it should and not otherwise.
    final pet = context.select<PetInfoProvider, PetInfo?>(
      (pets) => pets.activePet,
    );

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('Report history', style: context.t.h2),
            ),
            Expanded(
              child: history.isEmpty
                  // Into the questionnaire, not back through consent — see
                  // the dashboard's retake action.
                  ? _Empty(onStart: () => context.push(AppRoutes.quiz))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                      children: [
                        // The analytics module hosted here rather than on a
                        // screen of its own: navigation stays in one place
                        // and the widgets stay reusable elsewhere.
                        _TrendSection(
                          history: history,
                          petId: pet?.id ?? '',
                          onOpenReport: (pointId) =>
                              _openReport(context, history, pointId),
                        ),
                        const SizedBox(height: 18),
                        for (final group in groupHistory(history)) ...[
                          _GroupHeading(label: group.bucket.label),
                          const SizedBox(height: 10),
                          for (final entry in group.entries) ...[
                            _HistoryRow(
                              entry: entry,
                              pet: pet,
                              // The entry carries its position in the flat
                              // newest-first list, which is what the route
                              // indexes. Using the position within a group
                              // would open the wrong report for every group
                              // after the first.
                              onTap: () => context.push(
                                AppRoutes.pastReport(entry.index),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 8),
                        ],
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                          child: Text(
                            'Retake every 3 months to keep the trend '
                            'meaningful.',
                            style: AppTheme.font(
                              size: 12.5,
                              color: context.c.muted,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How recently an assessment was taken, coarsely enough to group by.
///
/// Rolling windows counted back from today, not calendar periods: a report
/// taken on the 31st should not jump from "This month" to "Older" overnight
/// merely because the month rolled over.
enum HistoryBucket {
  today('Today'),
  yesterday('Yesterday'),
  lastSevenDays('Last 7 days'),
  thisMonth('This month'),
  older('Older');

  const HistoryBucket(this.label);

  final String label;
}

/// One assessment, with its position in the flat newest-first history.
///
/// The index travels with the result because it is what
/// [AppRoutes.pastReport] addresses — grouping must not renumber it.
typedef HistoryEntry = ({int index, ScoreResult result});

typedef HistoryGroup = ({HistoryBucket bucket, List<HistoryEntry> entries});

/// Which bucket [when] falls into, relative to [now].
///
/// A future timestamp buckets as today rather than falling off the scale:
/// records sync from other handsets whose clocks disagree, and a report
/// filed under "Older" because a phone was an hour fast would be worse
/// than a day of imprecision.
@visibleForTesting
HistoryBucket bucketFor(DateTime when, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(when.toLocal())).inDays;

  if (days <= 0) return HistoryBucket.today;
  if (days == 1) return HistoryBucket.yesterday;
  if (days < 7) return HistoryBucket.lastSevenDays;
  if (days < 30) return HistoryBucket.thisMonth;
  return HistoryBucket.older;
}

/// [history] split into buckets, newest first, preserving each report's
/// original index.
///
/// Empty buckets are dropped rather than rendered as bare headings, and the
/// input order is kept as given — QuizProvider already hands this back
/// newest first, and re-sorting here would be a second opinion about
/// ordering that could disagree with the provider's.
@visibleForTesting
List<HistoryGroup> groupHistory(List<ScoreResult> history, {DateTime? now}) {
  final groups = <HistoryGroup>[];

  for (var i = 0; i < history.length; i++) {
    final bucket = bucketFor(history[i].completedAt, now: now);
    final entry = (index: i, result: history[i]);

    if (groups.isNotEmpty && groups.last.bucket == bucket) {
      groups.last.entries.add(entry);
    } else {
      groups.add((bucket: bucket, entries: [entry]));
    }
  }

  return groups;
}

/// The human-scale age of a report, for the row's own line.
///
/// Coarser than the bucket it sits under, and deliberately its own thing:
/// under an "Earlier" heading, "3 months ago" is the part that carries
/// information.
@visibleForTesting
String relativeReportDate(DateTime when, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(when.toLocal())).inDays;

  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  if (days < 14) return 'Last week';
  if (days < 30) return '${days ~/ 7} weeks ago';
  if (days < 60) return 'Last month';
  if (days < 365) return '${days ~/ 30} months ago';
  return 'Over a year ago';
}

/// The calendar date, spelled out so a timeline entry is unambiguous.
@visibleForTesting
String exactReportDate(DateTime when) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = when.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class _GroupHeading extends StatelessWidget {
  final String label;

  const _GroupHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label.toUpperCase(), style: context.t.overline),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onStart;

  const _Empty({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignImage(AppAssets.emoQuestion, width: 120, height: 120),
            const SizedBox(height: 14),
            Text('No reports yet', style: context.t.h2),
            const SizedBox(height: 10),
            Text(
              'Complete the assessment and your report cards will collect '
              'here so you can watch the trend.',
              textAlign: TextAlign.center,
              style: context.t.bodyText,
            ),
            const SizedBox(height: 22),
            AppButton(label: 'Start the assessment', onPressed: onStart),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final HistoryEntry entry;

  /// How many reports are retained, so the entry can be numbered.
  /// The pet these reports belong to. Null only in the window before the
  /// pet record has been read.
  final PetInfo? pet;

  final VoidCallback? onTap;

  const _HistoryRow({
    required this.entry,
    required this.pet,
    this.onTap,
  });

  bool get _isCurrent => entry.index == 0;

  @override
  Widget build(BuildContext context) {
    final result = entry.result;
    final band = result.category;
    final petName = pet?.name.trim() ?? '';

    return Semantics(
      button: onTap != null,
      label: [
        if (petName.isNotEmpty) petName,
        '${result.percentageScore} percent',
        band.label,
        relativeReportDate(result.completedAt),
      ].join(', '),
      container: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: _isCurrent ? band.bandLine(context.c) : context.c.border,
              width: _isCurrent ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: band.bandTint(context.c),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.percentageScore}',
                      style: AppTheme.font(
                        size: 18,
                        weight: FontWeight.w800,
                        color: band.bandColor(context.c),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Icon(
                      band.bandGlyph,
                      size: 12,
                      color: band.bandColor(context.c),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Whose report this is. Skipped entirely before the pet
                    // record has been read, so the row never renders an
                    // orphaned avatar next to an empty name.
                    if (petName.isNotEmpty) ...[
                      Row(
                        children: [
                          PhotoAvatar(photoPath: pet!.photoPath, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              petName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.font(
                                size: 14,
                                weight: FontWeight.w800,
                                color: context.c.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            band.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: band.bandColor(context.c),
                            ),
                          ),
                        ),
                        // On the band line rather than beside the name, so
                        // the marker survives a row that has no pet on it.
                        if (_isCurrent) ...[
                          const SizedBox(width: 6),
                          _CurrentPill(band: band),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${relativeReportDate(result.completedAt)} · '
                      '${exactReportDate(result.completedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(size: 12, color: context.c.muted),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.c.faint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks the newest report, which is the one the rest of the app treats as
/// the pet's current standing.
class _CurrentPill extends StatelessWidget {
  final HealthCategory band;

  const _CurrentPill({required this.band});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: band.bandTint(context.c),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Current',
        style: AppTheme.font(
          size: 10,
          weight: FontWeight.w800,
          color: band.bandColor(context.c),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// The analytics trend, or an honest reason there isn't one.
///
/// A stateful host purely to hold the snapshot cache: analysis is cheap for
/// five observations and is not for five hundred, and this screen rebuilds
/// whenever the quiz provider notifies.
class _TrendSection extends StatefulWidget {
  final List<ScoreResult> history;
  final String petId;
  final ValueChanged<String> onOpenReport;

  const _TrendSection({
    required this.history,
    required this.petId,
    required this.onOpenReport,
  });

  @override
  State<_TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends State<_TrendSection> {
  static const _adapter = AssessmentSeriesAdapter();
  final _cache = AnalyticsCache();

  @override
  Widget build(BuildContext context) {
    // One observation is a starting point, not a direction. Drawing a graph
    // through a single dot would look like a flat line, which is a claim the
    // record does not support.
    if (widget.history.length < 2) {
      return AnalyticsEmptyState.needsSecondAssessment(
        onStart: () => context.push(AppRoutes.quiz),
      );
    }

    final series = _adapter.fromResults(
      subjectId: widget.petId,
      results: widget.history,
    );

    final snapshot = _cache.snapshotOf(series);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrendGraph(
          snapshot: snapshot,
          onOpenReport: widget.onOpenReport,
        ),
        // Three windows on the same history, each answering a different
        // question: the graph covers the recorded history, the insights the
        // most recent change, the category cards first recorded to latest.
        if (snapshot.insights.isNotEmpty) ...[
          const SizedBox(height: 22),
          InsightList(insights: snapshot.insights),
        ],
        // Analysis above the record: the graph says where the pet is going,
        // the categories say which areas are taking it there, and the
        // timeline below is what actually happened.
        if (snapshot.categoryTrends.isNotEmpty) ...[
          const SizedBox(height: 22),
          CategoryEvolutionList(trends: snapshot.categoryTrends),
        ],
      ],
    );
  }
}

/// Opens the report a chart point belongs to.
///
/// The point carries a stable id; the route takes a position in the current
/// history. Resolving the two here, at the moment of the tap, is what keeps
/// analytics free of list indexes — and means a history that changed since
/// the chart was drawn cannot open the wrong report. A point whose report
/// has since been trimmed away simply does nothing.
void _openReport(
  BuildContext context,
  List<ScoreResult> history,
  String pointId,
) {
  for (var i = 0; i < history.length; i++) {
    final id = AssessmentPoint.idFor(
      history[i].petId ?? '',
      history[i].completedAt,
    );
    if (id == pointId) {
      context.push(AppRoutes.pastReport(i));
      return;
    }
  }
}
