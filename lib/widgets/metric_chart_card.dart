import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../providers/dashboard_provider.dart';

/// Simple custom-painted line chart for weight/height history. Uses
/// CustomPaint instead of an external chart dependency to keep the bundle
/// lean and avoid network installs at this stage.
class MetricChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final List<WeightPoint> points;
  final Color accent;

  const MetricChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent =
        isDark && accent == AppTheme.brandBlue ? AppTheme.accentBlue : accent;

    final latest = points.isNotEmpty ? points.last.kg : 0.0;
    final first = points.isNotEmpty ? points.first.kg : 0.0;
    final delta = latest - first;
    final deltaText =
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unit';
    final deltaColor = isDark ? const Color(0xFF5DD08A) : AppTheme.brandGreen;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.mutedText(isDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  deltaText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${latest.toStringAsFixed(1)} $unit',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppTheme.heading(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _LineChartPainter(
                points: points,
                accent: effectiveAccent,
                dotFill: AppTheme.surface(isDark),
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<WeightPoint> points;
  final Color accent;
  final Color dotFill;

  _LineChartPainter({
    required this.points,
    required this.accent,
    required this.dotFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points.map((p) => p.kg).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).clamp(0.1, double.infinity);

    final dx = size.width / (values.length - 1);

    final linePath = Path();
    final fillPath = Path();
    final positions = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final normalized = (values[i] - minVal) / range;
      final y = size.height - (normalized * size.height * 0.85) - 8;
      positions.add(Offset(x, y));
    }

    // Smooth line
    linePath.moveTo(positions[0].dx, positions[0].dy);
    fillPath.moveTo(positions[0].dx, size.height);
    fillPath.lineTo(positions[0].dx, positions[0].dy);
    for (var i = 1; i < positions.length; i++) {
      final prev = positions[i - 1];
      final curr = positions[i];
      final controlX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(
          controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
      fillPath.cubicTo(
          controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
    }
    fillPath.lineTo(positions.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.30),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Data points — inner dot uses the card surface color so points read
    // as "punched out" in both light and dark mode (was fixed white).
    final dotPaint = Paint()..color = accent;
    final dotInner = Paint()..color = dotFill;
    for (final p in positions) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 2, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.accent != accent ||
      oldDelegate.dotFill != dotFill;
}
