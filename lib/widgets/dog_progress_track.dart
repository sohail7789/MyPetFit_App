import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';

/// Animated Lottie dog mascot that walks along a horizontal pill-shaped
/// track as the user makes progress through the quiz.
///
/// The Lottie walk cycle loops continuously; the whole mascot slides
/// left→right as `progress` advances.
class DogProgressTrack extends StatefulWidget {
  final double progress; // 0.0 .. 1.0
  final String? label;

  const DogProgressTrack({
    super.key,
    required this.progress,
    this.label,
  });

  @override
  State<DogProgressTrack> createState() => _DogProgressTrackState();
}

class _DogProgressTrackState extends State<DogProgressTrack> {
  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? AppTheme.darkBlueSurface : AppTheme.lightGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkBlueTextLight : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const dogSize = 56.0;
              const padding = 8.0;
              final maxLeft = width - dogSize - padding;
              final left = padding + (maxLeft - padding) * clamped;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track pill
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 26,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            widthFactor: clamped,
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.secondary],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Paw prints along the track
                  for (int i = 1; i <= 8; i++)
                    Positioned(
                      left: (width - 40) * (i / 9),
                      top: 28,
                      child: Icon(
                        Icons.pets,
                        size: 10,
                        color: (i / 9 <= clamped)
                            ? Colors.white.withValues(alpha: 0.5)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppTheme.brandGreen.withValues(alpha: 0.15)),
                      ),
                    ),
                  // Finish flag
                  Positioned(
                    right: 0,
                    top: 12,
                    child: Icon(
                      Icons.flag_rounded,
                      color: AppTheme.brandRed,
                      size: 32,
                    ),
                  ),
                  // Lottie walking dog mascot — slides along the track
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    left: left,
                    top: 4,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(clamped.toStringAsFixed(2)),
                      tween: Tween(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: SizedBox(
                        width: dogSize,
                        height: dogSize,
                        child: Lottie.asset(
                          'assets/animations/dog_walking.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
