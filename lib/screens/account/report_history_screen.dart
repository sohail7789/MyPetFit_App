import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/score_band.dart';
import '../../models/score_result.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';

/// Screen 32 — Report history (the Report tab).
class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  static String _date(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final history = quiz.assessmentHistory;

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('Report history', style: context.t.h2),
            ),
            Expanded(
              child: history.isEmpty
                  ? _Empty(onStart: () => context.push(AppRoutes.consent))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                      children: [
                        if (history.length >= 2)
                          _TrendCard(history: history),
                        if (history.length >= 2) const SizedBox(height: 14),
                        for (var i = 0; i < history.length; i++) ...[
                          _HistoryRow(
                            result: history[i],
                            date: _date(history[i].completedAt),
                            isCurrent: i == 0,
                            // Every row opens its own report card, matching
                            // the design (all rows carry a chevron). Older
                            // rows used to have no handler at all, so the
                            // history was a list you could look at but never
                            // open.
                            onTap: () =>
                                context.push(AppRoutes.pastReport(i)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                          child: Text(
                            'Retake every 3 months to keep the trend '
                            'meaningful.',
                            style: AppTheme.font(
                              size: 12.5,
                              color: context.c.muted,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onStart;

  const _Empty({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignImage(AppAssets.emoQuestion, width: 120, height: 120),
            const SizedBox(height: 14),
            Text('No reports yet', style: context.t.h2),
            const SizedBox(height: 10),
            Text(
              'Complete the assessment and your report cards will collect '
              'here so you can watch the trend.',
              textAlign: TextAlign.center,
              style: context.t.bodyText,
            ),
            const SizedBox(height: 22),
            AppButton(label: 'Start the assessment', onPressed: onStart),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<ScoreResult> history;

  const _TrendCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final latest = history.first.percentageScore;
    final previous = history[1].percentageScore;
    final delta = latest - previous;
    final up = delta >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.c.tintPanel,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR TREND', style: context.t.overline),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$latest',
                    style: AppTheme.font(
                      size: 30,
                      weight: FontWeight.w800,
                      color: context.c.ink,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    up
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: up ? context.c.successText : context.c.warningText,
                  ),
                  Text(
                    '${up ? '+' : ''}$delta',
                    style: AppTheme.font(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: up ? context.c.successText : context.c.warningText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 130,
            height: 46,
            child: CustomPaint(
              painter: _SparklinePainter(
                // Oldest → newest.
                history.reversed.map((r) => r.percentageScore).toList(),
                context.c.actionText,
                context.c.fainter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple polyline over the score history, with the newest point emphasised.
class _SparklinePainter extends CustomPainter {
  final List<int> scores;

  /// A painter sits outside the widget tree, so the palette is passed in
  /// rather than resolved from a context.
  final Color lineColor;
  final Color dotColor;

  const _SparklinePainter(this.scores, this.lineColor, this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final span = (maxScore - minScore).clamp(1, 100);

    Offset pointAt(int i) {
      final dx = scores.length == 1
          ? size.width / 2
          : 4 + (size.width - 8) * (i / (scores.length - 1));
      final normalised = (scores[i] - minScore) / span;
      final dy = size.height - 8 - (size.height - 18) * normalised;
      return Offset(dx, dy);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < scores.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < scores.length; i++) {
      final isLast = i == scores.length - 1;
      canvas.drawCircle(
        pointAt(i),
        isLast ? 4 : 3,
        Paint()
          ..color = isLast ? lineColor : dotColor,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.scores != scores ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dotColor != dotColor;
}

class _HistoryRow extends StatelessWidget {
  final ScoreResult result;
  final String date;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _HistoryRow({
    required this.result,
    required this.date,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final band = result.category;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: context.c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: band.bandTint(context.c),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '${result.percentageScore}',
                style: AppTheme.font(
                  size: 17,
                  weight: FontWeight.w800,
                  color: band.bandColor(context.c),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: AppTheme.font(
                      size: 14.5,
                      weight: FontWeight.w800,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${band.label}${isCurrent ? ' · current' : ''}',
                    style: AppTheme.font(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: band.bandColor(context.c),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.c.faint,
              ),
          ],
        ),
      ),
    );
  }
}
