import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../models/health_insight.dart';
import '../presentation/insight_formatter.dart';
import 'insight_card.dart';

/// What changed since the last assessment.
///
/// Rendered in the order the calculator returned — weighted by how much
/// moved — so the reader meets the largest change first. Provider-free, and
/// the formatter is injectable so a veterinarian portal can keep the
/// computation and change only the voice.
class InsightList extends StatelessWidget {
  final List<HealthInsight> insights;
  final InsightFormatter formatter;

  final String title;
  final String subtitle;

  /// Whether to draw the heading.
  ///
  /// False when something above already names the section — a disclosure
  /// heading, say. The list keeps its own header by default so every existing
  /// caller reads unchanged.
  final bool showHeader;

  const InsightList({
    super.key,
    required this.insights,
    this.formatter = const DefaultInsightFormatter(),
    this.title = 'What changed',
    // Names the window explicitly. The graph covers recorded history and the
    // category cards cover first-to-latest; without saying so, three
    // different comparisons on one screen read as contradicting each other.
    this.subtitle = 'Compared with your previous assessment.',
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

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
        for (var i = 0; i < insights.length; i++)
          Padding(
            padding:
                EdgeInsets.only(bottom: i == insights.length - 1 ? 0 : 10),
            child: InsightCard(insight: insights[i], formatter: formatter),
          ),
      ],
    );
  }
}
