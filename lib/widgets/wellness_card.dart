import 'package:flutter/material.dart';
import '../config/theme.dart';

class WellnessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final Color pastel;
  final double? progress;
  final VoidCallback? onTap;

  /// Optional short badge shown beside the icon (e.g. "Soon"). Use it to
  /// set expectations up front rather than letting a tap dead-end.
  final String? badge;

  const WellnessCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
    required this.pastel,
    this.progress,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Navy accents need a lighter stand-in on dark surfaces.
    final effectiveAccent = isDark &&
            (accent == AppTheme.primary || accent == AppTheme.neutralDark)
        ? AppTheme.accentBlue
        : accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border:
                Border.all(color: AppTheme.hairline(isDark), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.tint(isDark, effectiveAccent, pastel),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: effectiveAccent, size: 20),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.mutedText(isDark)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppTheme.mutedText(isDark),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.heading(isDark),
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor:
                        AppTheme.tint(isDark, effectiveAccent, pastel),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(effectiveAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
