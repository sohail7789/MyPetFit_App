import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../providers/dashboard_provider.dart';

class MoodSelectorCard extends StatelessWidget {
  final String petName;
  final PetMood? selected;
  final ValueChanged<PetMood> onChanged;

  const MoodSelectorCard({
    super.key,
    required this.petName,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final options = <(PetMood, String, String, Color)>[
      (PetMood.highEnergy, '⚡', 'High energy', AppTheme.accentBlue),
      (PetMood.middle, '😌', 'In the middle', AppTheme.primary),
      (PetMood.lowEnergy, '😴', 'Low energy', AppTheme.secondary),
    ];

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
          Text(
            'How does $petName feel today?',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.heading(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final option in options) ...[
                Expanded(
                  child: _MoodButton(
                    emoji: option.$2,
                    label: option.$3,
                    // The deep navy accent vanishes against dark surfaces;
                    // swap it for the light blue in dark mode.
                    accent: isDark && option.$4 == AppTheme.primary
                        ? AppTheme.accentBlue
                        : option.$4,
                    isDark: isDark,
                    isSelected: selected == option.$1,
                    onTap: () => onChanged(option.$1),
                  ),
                ),
                if (option != options.last)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color accent;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? accent : AppTheme.hairline(isDark),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: AppMotion.base,
              curve: AppMotion.curve,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? accent : AppTheme.mutedText(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
