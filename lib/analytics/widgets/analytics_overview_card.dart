import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/score_band.dart';
import '../models/analytics_overview.dart';
import '../models/category_trend.dart';
import '../models/trend_direction.dart';
import '../presentation/overview_formatter.dart';

/// The executive summary of a pet's health record.
///
/// **Presentation only.** Every figure arrives on the [AnalyticsOverview];
/// this widget selects nothing, compares nothing and computes nothing. It is
/// provider-free by design — no `ProductProvider`, no `QuizProvider`, no
/// Firestore — so a veterinarian portal or a web dashboard can render the
/// identical component from its own source of data.
///
/// **Absent facts leave no trace.** A row whose value is unknown is not
/// rendered at all: no empty box, no placeholder dash, and above all no
/// neutral-sounding claim like "stable" standing in for a comparison that was
/// never made.
///
/// Merchandising arrives through [recommendation] rather than being looked up
/// here. The domain names a category; whichever surface owns a catalog turns
/// that into a product and passes the finished widget in.
class AnalyticsOverviewCard extends StatelessWidget {
  final AnalyticsOverview overview;

  /// The instant to judge the retake cadence against.
  ///
  /// Injected rather than read here, so a countdown is testable and a caller
  /// that rebuilds on a timer can move it on.
  final DateTime now;

  final OverviewFormatter formatter;

  /// An optional product suggestion for [AnalyticsOverview.focus].
  ///
  /// Outside the summary's merged semantics, so a screen reader meets it as
  /// its own thing rather than as a clause in a health passage.
  final Widget? recommendation;

  const AnalyticsOverviewCard({
    super.key,
    required this.overview,
    required this.now,
    this.formatter = const DefaultOverviewFormatter(),
    this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    // Nothing recorded is not an empty summary — it is no summary. The
    // surface above decides what to invite instead.
    if (overview.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[
      if (overview.topInsight != null)
        _DetailRow(
          icon: Icons.lightbulb_outline_rounded,
          label: formatter.insightLabel,
          value: formatter.insight(overview.topInsight!),
        ),
      if (overview.biggestImprovement != null)
        _MovementRow(
          icon: Icons.trending_up_rounded,
          label: formatter.improvementLabel,
          trend: overview.biggestImprovement!,
          formatter: formatter,
          tone: _Tone.positive,
        ),
      if (overview.biggestConcern != null)
        _MovementRow(
          icon: Icons.trending_down_rounded,
          label: formatter.concernLabel,
          trend: overview.biggestConcern!,
          formatter: formatter,
          tone: _Tone.caution,
        ),
      if (overview.latestMilestone != null)
        _DetailRow(
          icon: Icons.emoji_events_outlined,
          label: formatter.milestoneLabel,
          value: formatter.milestones(
            overview.latestMilestone!,
            overview.milestoneCount,
          ),
        ),
      if (overview.focus != null)
        _DetailRow(
          icon: Icons.center_focus_strong_outlined,
          label: formatter.focusLabel,
          value: formatter.focus(overview.focus!),
          supporting: formatter.focusReason(overview.focus!.reason),
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: context.c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One passage, not nine labels: a reader arriving here should hear
          // what the record says without assembling it themselves.
          Semantics(
            container: true,
            excludeSemantics: true,
            label: formatter.spoken(overview, now: now),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Heading(formatter: formatter),
                const SizedBox(height: 13),
                _Hero(overview: overview, formatter: formatter),
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1, thickness: 1, color: context.c.divider),
                  const SizedBox(height: 12),
                  for (var i = 0; i < rows.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == rows.length - 1 ? 0 : 11,
                      ),
                      child: rows[i],
                    ),
                ],
                if (overview.lastAssessmentAt != null ||
                    overview.nextAssessment != null) ...[
                  const SizedBox(height: 14),
                  _CadencePanel(
                    overview: overview,
                    now: now,
                    formatter: formatter,
                  ),
                ],
              ],
            ),
          ),
          if (recommendation != null) ...[
            const SizedBox(height: 13),
            recommendation!,
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final OverviewFormatter formatter;

  const _Heading({required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.title,
          style: AppTheme.font(
            size: 16,
            weight: FontWeight.w800,
            color: context.c.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          formatter.subtitle,
          style: AppTheme.font(
            size: 12.5,
            color: context.c.muted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// The score, its band and the direction of travel.
///
/// A [Wrap] rather than a [Row]: at 320 points with large text the figure and
/// the band chip will not sit side by side, and a summary that overflows is
/// worse than one that takes a second line.
class _Hero extends StatelessWidget {
  final AnalyticsOverview overview;
  final OverviewFormatter formatter;

  const _Hero({required this.overview, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final band = overview.band;
    final accent = band?.bandColor(context.c) ?? context.c.actionText;
    final trend = formatter.trend(overview.direction);
    final change = formatter.change(overview.changeSincePrevious);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.scoreLabel,
          style: AppTheme.font(
            size: 11.5,
            weight: FontWeight.w700,
            color: context.c.muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            if (overview.score != null)
              Text(
                '${overview.score}',
                style: AppTheme.font(
                  size: 38,
                  weight: FontWeight.w800,
                  color: accent,
                  height: 1,
                  letterSpacing: -1.2,
                ),
              ),
            if (band != null)
              Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                decoration: BoxDecoration(
                  color: band.bandTint(context.c),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: band.bandLine(context.c)),
                ),
                child: Text(
                  formatter.band(band),
                  style: AppTheme.font(
                    size: 12,
                    weight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
          ],
        ),
        // Omitted entirely with one assessment. There is no direction to
        // report, and reporting none is not the same as reporting calm.
        if (trend != null) ...[
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  _trendGlyph(overview.direction),
                  size: 15,
                  color: _trendColour(context, overview.direction),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  change == null ? trend : '$trend · $change',
                  style: AppTheme.font(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: context.c.bodyStrong,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

IconData _trendGlyph(TrendDirection direction) => switch (direction) {
      TrendDirection.improving => Icons.trending_up_rounded,
      TrendDirection.declining => Icons.trending_down_rounded,
      TrendDirection.stable => Icons.trending_flat_rounded,
      TrendDirection.unknown => Icons.help_outline_rounded,
    };

Color _trendColour(BuildContext context, TrendDirection direction) =>
    switch (direction) {
      TrendDirection.improving => context.c.successText,
      TrendDirection.declining => context.c.warningText,
      _ => context.c.muted,
    };

enum _Tone { positive, caution, neutral }

/// One labelled fact.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? supporting;
  final _Tone tone;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.supporting,
    this.tone = _Tone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colour = switch (tone) {
      _Tone.positive => context.c.successText,
      _Tone.caution => context.c.warningText,
      _Tone.neutral => context.c.actionText,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: colour),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.font(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: context.c.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.font(
                  size: 13,
                  weight: FontWeight.w700,
                  color: context.c.ink,
                  height: 1.35,
                ),
              ),
              if (supporting != null) ...[
                const SizedBox(height: 2),
                Text(
                  supporting!,
                  style: AppTheme.font(
                    size: 12,
                    color: context.c.body,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// An area, named, with how far it has moved.
class _MovementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final CategoryTrend trend;
  final OverviewFormatter formatter;
  final _Tone tone;

  const _MovementRow({
    required this.icon,
    required this.label,
    required this.trend,
    required this.formatter,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) => _DetailRow(
        icon: icon,
        label: label,
        value: trend.name,
        supporting: formatter.movement(trend),
        tone: tone,
      );
}

/// Where the record stands on cadence.
///
/// The two dates share one panel because they are one thought: how current
/// the record is, and when it stops being. Split across the card they would
/// read as unrelated facts.
class _CadencePanel extends StatelessWidget {
  final AnalyticsOverview overview;
  final DateTime now;
  final OverviewFormatter formatter;

  const _CadencePanel({
    required this.overview,
    required this.now,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final last = overview.lastAssessmentAt;
    final due = overview.nextAssessment;

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: context.c.surfaceInset,
        borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
      ),
      child: Wrap(
        spacing: 26,
        runSpacing: 11,
        children: [
          if (last != null)
            _CadenceEntry(
              label: formatter.lastAssessedLabel,
              value: formatter.lastAssessed(last, now: now),
              colour: context.c.ink,
            ),
          if (due != null)
            _CadenceEntry(
              label: formatter.nextAssessmentLabel,
              value: formatter.nextAssessment(due),
              // A due assessment is worth noticing, not worth alarming over.
              colour: due.isDue ? context.c.warningText : context.c.ink,
            ),
        ],
      ),
    );
  }
}

class _CadenceEntry extends StatelessWidget {
  final String label;
  final String value;
  final Color colour;

  const _CadenceEntry({
    required this.label,
    required this.value,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.font(
            size: 11.5,
            weight: FontWeight.w700,
            color: context.c.muted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTheme.font(
            size: 13,
            weight: FontWeight.w800,
            color: colour,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
