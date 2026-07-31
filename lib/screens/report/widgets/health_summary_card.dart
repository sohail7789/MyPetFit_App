import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/score_result.dart';

class HealthSummaryCard extends StatelessWidget {
  final HealthCategory category;

  const HealthSummaryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline(isDark), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: isDark ? 0.22 : 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                category.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: category.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            category.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText(isDark),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
