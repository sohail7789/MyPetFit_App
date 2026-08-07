import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/score_band.dart';
import '../models/category_trend.dart';
import '../models/trend_direction.dart';

/// How one area of health has moved across a pet's recorded history.
///
/// **Two colours saying two different things.** The bar is coloured by the
/// score — how the category is doing — and the delta by the direction it
/// moved. A category sitting at 30 that climbed 20 points is bad news and
/// good movement at once; one colour for both would misreport whichever it
/// dropped.
///
/// Presentation only: it renders a [CategoryTrend] and reads no provider.
class CategoryTrendCard extends StatelessWidget {
  final CategoryTrend trend;

  const CategoryTrendCard({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final latest = trend.latest;
    if (latest == null) return const SizedBox.shrink();

    final first = trend.first;
    final delta = trend.delta;
    final direction = trend.direction();
    final scoreColour = categoryBarColor(context.c, latest);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: _spoken(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
          border: Border.all(color: context.c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    trend.name,
                    // Two lines: the longest real category name runs to 28
                    // characters and will not fit one at a large text scale.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      size: 14,
                      weight: FontWeight.w700,
                      color: context.c.ink,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _DeltaChip(delta: delta, direction: direction),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              // Never "since your first assessment": history is trimmed, so
              // the oldest kept report is not necessarily the first ever
              // taken. "First recorded" is true whatever retention does.
              first == null || delta == null
                  ? '${latest.round()}'
                  : '${first.round()} → ${latest.round()}',
              style: AppTheme.font(
                size: 13,
                weight: FontWeight.w800,
                color: context.c.bodyStrong,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 9),
            _EvolutionBar(
              first: first,
              latest: latest,
              colour: scoreColour,
              hasMoved: delta != null,
            ),
          ],
        ),
      ),
    );
  }

  /// One sentence rather than five disconnected numbers.
  String _spoken() {
    final latest = trend.latest!;
    final first = trend.first;
    final delta = trend.delta;

    if (delta == null || first == null) {
      return '${trend.name}, first measurement, ${latest.round()}. '
          'Not enough history to compare.';
    }

    final movement = switch (trend.direction()) {
      TrendDirection.improving => 'improved $delta points',
      TrendDirection.declining => 'declined ${delta.abs()} points',
      _ => 'steady',
    };

    return '${trend.name}, $movement, '
        'from ${first.round()} to ${latest.round()}.';
  }
}

/// The movement, coloured by direction rather than by health.
class _DeltaChip extends StatelessWidget {
  final int? delta;
  final TrendDirection direction;

  const _DeltaChip({required this.delta, required this.direction});

  @override
  Widget build(BuildContext context) {
    // A category measured once is not steady — it is unmeasured. Saying so
    // is the honest state, and a neutral chip is clearer than no chip at
    // all, which reads as a rendering gap.
    if (delta == null) {
      return _Chip(
        colour: context.c.muted,
        background: context.c.surfaceLow,
        icon: Icons.remove_rounded,
        label: 'First measurement',
      );
    }

    final (colour, icon) = switch (direction) {
      TrendDirection.improving => (
          context.c.successText,
          Icons.arrow_upward_rounded,
        ),
      TrendDirection.declining => (
          context.c.warningText,
          Icons.arrow_downward_rounded,
        ),
      // A move inside the noise band shows its number without claiming a
      // direction — "+2" is a fact, "improved" would be a claim.
      _ => (context.c.muted, Icons.trending_flat_rounded),
    };

    return _Chip(
      colour: colour,
      background: colour.withValues(alpha: 0.11),
      icon: icon,
      label: '${delta! > 0 ? '+' : ''}$delta',
    );
  }
}

class _Chip extends StatelessWidget {
  final Color colour;
  final Color background;
  final IconData icon;
  final String label;

  const _Chip({
    required this.colour,
    required this.background,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colour),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            style: AppTheme.font(
              size: 11.5,
              weight: FontWeight.w800,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the category started and where it is now, in one bar.
///
/// The ghost layer is the first recorded score and the solid layer the
/// latest, so growth reads as the solid overtaking the ghost and a decline
/// reads as it falling short — the shape carries the change for anyone who
/// does not stop to read two numbers.
class _EvolutionBar extends StatelessWidget {
  final double? first;
  final double latest;
  final Color colour;
  final bool hasMoved;

  const _EvolutionBar({
    required this.first,
    required this.latest,
    required this.colour,
    required this.hasMoved,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.c.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (hasMoved && first != null)
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (first!.clamp(0, 100) / 100).toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (latest.clamp(0, 100) / 100).toDouble(),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: child,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
