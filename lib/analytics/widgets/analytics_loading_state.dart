import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Placeholder blocks for an analytics surface whose history is still being
/// read.
///
/// Shape-only, matching the rhythm of the content it stands in for rather
/// than a spinner: a surface that reflows once data lands reads as broken.
/// Provider-free, so any consumer can drop it in.
///
/// Only for the window where there is nothing to show *and* the read is
/// still in flight. Restored data always wins — a skeleton drawn over real
/// history is worse than the history.
class AnalyticsLoadingState extends StatelessWidget {
  /// How many placeholder rows to draw below the header block.
  final int rows;

  const AnalyticsLoadingState({super.key, this.rows = 3});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading analytics',
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Block(height: 14, widthFactor: 0.45, context: context),
            const SizedBox(height: 10),
            _Block(height: 92, context: context, radius: 16),
            const SizedBox(height: 18),
            for (var i = 0; i < rows; i++) ...[
              _Block(
                height: 11,
                widthFactor: i.isEven ? 0.6 : 0.45,
                context: context,
              ),
              const SizedBox(height: 7),
              _Block(height: 8, context: context),
              if (i != rows - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double height;
  final double widthFactor;
  final double radius;
  final BuildContext context;

  const _Block({
    required this.height,
    required this.context,
    this.widthFactor = 1,
    this.radius = 5,
  });

  @override
  Widget build(BuildContext _) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.c.divider,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
