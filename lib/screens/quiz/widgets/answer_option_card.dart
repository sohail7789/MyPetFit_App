import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../models/question.dart';

/// One selectable answer row.
///
/// Selected state is a quiet tinted fill + accent border (Linear/Notion
/// style) rather than the old gradient-plus-glow, so it reads cleanly in
/// both light and dark mode and doesn't shout over the content.
class AnswerOptionCard extends StatelessWidget {
  final Answer answer;
  final bool isSelected;
  final VoidCallback onTap;
  final String optionLetter;

  const AnswerOptionCard({
    super.key,
    required this.answer,
    required this.isSelected,
    required this.onTap,
    required this.optionLetter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Navy is invisible against dark surfaces — use the light-blue accent.
    final accent = isDark ? AppTheme.accentBlue : AppTheme.primary;

    final Color bg;
    final Color borderColor;
    final double borderWidth;
    if (isSelected) {
      bg = accent.withValues(alpha: isDark ? 0.20 : 0.10);
      borderColor = accent;
      borderWidth = 1.5;
    } else {
      bg = AppTheme.surface(isDark);
      borderColor = AppTheme.hairline(isDark);
      borderWidth = 0.5;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            // Option letter circle
            AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.curve,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? accent
                      : AppTheme.mutedText(isDark).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                optionLetter,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? (isDark ? AppTheme.darkBlueBg : Colors.white)
                      : AppTheme.mutedText(isDark),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Answer text — color stays the theme default so contrast is
            // guaranteed in both modes; selection is carried by weight,
            // fill, and border instead.
            Expanded(
              child: Text(
                answer.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppTheme.heading(isDark),
                ),
              ),
            ),
            // Checkmark when selected
            AnimatedScale(
              scale: isSelected ? 1 : 0,
              duration: AppMotion.base,
              curve: AppMotion.curve,
              child: Icon(
                Icons.check_circle_rounded,
                color: accent,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
