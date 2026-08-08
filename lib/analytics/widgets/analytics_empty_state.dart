import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// What an analytics surface shows when it has nothing to draw.
///
/// Presentation only, and provider-free by design: every string, action and
/// piece of art is a parameter, so a veterinarian portal or a web dashboard
/// can reuse the exact component with its own copy. Two named constructors
/// cover the two states this module can honestly be in.
class AnalyticsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Optional call to action. Omitted where there is nothing useful to do.
  final String? actionLabel;
  final VoidCallback? onAction;

  const AnalyticsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Nothing recorded at all.
  ///
  /// Says why tracking matters rather than reporting an absence: "no data"
  /// tells an owner what the app lacks, not what they would gain.
  const AnalyticsEmptyState.noHistory({Key? key, VoidCallback? onStart})
      : this(
          key: key,
          icon: Icons.insights_outlined,
          title: 'Start tracking your pet’s health',
          message:
              'Each assessment becomes a point on your pet’s health '
              'record. Over time you can see what is improving, what needs '
              'attention, and what to raise with your vet.',
          actionLabel: 'Take the assessment',
          onAction: onStart,
        );

  /// Exactly one observation.
  ///
  /// A trend needs two points. Saying so plainly is the whole reason this
  /// state exists — the alternative is a graph with a single dot, which
  /// looks like a flat line and is a claim the data does not support.
  const AnalyticsEmptyState.needsSecondAssessment({
    Key? key,
    VoidCallback? onStart,
  }) : this(
          key: key,
          icon: Icons.timeline_outlined,
          title: 'One assessment recorded',
          message:
              'Complete another assessment to unlock trends. A single result '
              'is a starting point — comparing two is what shows a '
              'direction.',
          actionLabel: 'Take another assessment',
          onAction: onStart,
        );

  @override
  Widget build(BuildContext context) {
    final action = onAction;
    final label = actionLabel;

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.c.tint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              // Decorative: the title and message carry the meaning, and a
              // screen reader announcing "insights icon" adds nothing.
              child: Icon(icon, size: 26, color: context.c.actionText),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                size: 17,
                weight: FontWeight.w800,
                color: context.c.ink,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                size: 13.5,
                color: context.c.body,
                height: 1.55,
              ),
            ),
            if (action != null && label != null) ...[
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: label,
                container: true,
                excludeSemantics: true,
                // On the node itself: excluding the children's semantics also
                // excludes the detector's tap action, and an invitation a
                // screen reader cannot accept is not an invitation.
                onTap: action,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: action,
                  child: Container(
                    // A floor, not a fixed height, so the target stays past
                    // 48dp as text scales up.
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.action,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTheme.font(
                        size: 14,
                        weight: FontWeight.w800,
                        color: context.c.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
