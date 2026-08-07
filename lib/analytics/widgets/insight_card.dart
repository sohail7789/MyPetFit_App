import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../models/health_insight.dart';
import '../models/insight_severity.dart';
import '../presentation/insight_formatter.dart';

/// One finding, in words.
///
/// Presentation only: the sentence comes from an [InsightFormatter] and the
/// urgency from the insight's own [InsightSeverity]. This widget decides
/// neither — it only decides how they look.
class InsightCard extends StatelessWidget {
  final HealthInsight insight;
  final InsightFormatter formatter;

  const InsightCard({
    super.key,
    required this.insight,
    this.formatter = const DefaultInsightFormatter(),
  });

  @override
  Widget build(BuildContext context) {
    final text = formatter.format(insight);
    final (colour, icon) = _appearance(context, insight.severity);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: text,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
          border: Border.all(color: colour.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 17, color: colour),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTheme.font(
                  size: 13,
                  weight: FontWeight.w600,
                  color: context.c.bodyStrong,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Severity drives the treatment, so a finding cannot look calm in one
  /// place and urgent in another.
  (Color, IconData) _appearance(BuildContext context, InsightSeverity level) =>
      switch (level) {
        InsightSeverity.positive => (
            context.c.successText,
            Icons.trending_up_rounded,
          ),
        InsightSeverity.neutral => (
            context.c.actionText,
            Icons.info_outline_rounded,
          ),
        InsightSeverity.caution => (
            context.c.warningText,
            Icons.trending_down_rounded,
          ),
        InsightSeverity.alert => (
            context.c.critical,
            Icons.priority_high_rounded,
          ),
      };
}
