import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../domain/category_sort.dart';
import '../models/category_trend.dart';
import 'category_trend_card.dart';

/// Every health area, and which way each has moved.
///
/// All categories stay visible: this is a health record, and hiding the ones
/// that look uneventful is how a slow decline goes unnoticed. Ordering is
/// what surfaces the urgent ones, not omission.
///
/// [mode] is carried so a future surface — a veterinarian portal ranking by
/// current health, a premium view ranking by improvement — can reorder
/// without this widget changing. No UI selects it yet; the default is the
/// worst decline first.
///
/// Presentation only, provider-free, and it sorts through the domain rather
/// than holding its own opinion about order.
class CategoryEvolutionList extends StatelessWidget {
  final List<CategoryTrend> trends;
  final CategorySortMode mode;

  /// Heading and framing. Overridable so a portal can use its own words.
  final String title;
  final String subtitle;

  /// Whether to draw the heading. False when a disclosure heading above
  /// already names the section; true by default so existing callers are
  /// unaffected.
  final bool showHeader;

  const CategoryEvolutionList({
    super.key,
    required this.trends,
    this.mode = CategorySortMode.largestDeclineFirst,
    this.title = 'Category progress',
    // Deliberately not "since your first assessment". History is trimmed, so
    // the oldest kept report is not necessarily the first ever taken — this
    // wording stays true whatever retention does.
    this.subtitle = 'First recorded to latest, across your recorded history.',
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) return const SizedBox.shrink();

    final ordered = sortCategoryTrends(trends, mode: mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Semantics(
            header: true,
            container: true,
            excludeSemantics: true,
            label: '$title. $subtitle',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.font(
                    size: 16,
                    weight: FontWeight.w800,
                    color: context.c.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTheme.font(
                    size: 12.5,
                    color: context.c.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < ordered.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == ordered.length - 1 ? 0 : 10),
            child: CategoryTrendCard(trend: ordered[i]),
          ),
      ],
    );
  }
}
