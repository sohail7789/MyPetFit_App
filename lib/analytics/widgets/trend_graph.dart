import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/score_band.dart';
import '../models/analytics_snapshot.dart';
import '../models/assessment_point.dart';
import '../utils/trend_geometry.dart';
import 'analytics_theme.dart';

/// A pet's overall score across its recorded history.
///
/// **Hybrid by design.** The painter draws only what cannot be tapped or
/// read aloud — grid, axis, line, fill. Every interactive point is a real
/// widget with its own semantics and a proper touch target, because a canvas
/// is invisible to a screen reader and has no hit testing, and neither can
/// be bolted on afterwards.
///
/// Only the notable observations get a marker: the latest, the highest, the
/// lowest, and whatever is selected. Every other point is still reachable —
/// a tap anywhere selects the nearest one — which keeps the widget count
/// flat whether the history holds five observations or five hundred. The
/// full enumeration for a screen reader is the assessment list this graph
/// sits above, so nothing is lost by not drawing hundreds of nodes.
///
/// Presentation only: it renders a snapshot and reports taps. It reads no
/// provider, computes no score, and never re-derives a band.
class TrendGraph extends StatefulWidget {
  final AnalyticsSnapshot snapshot;

  /// Called with the observation's stable id — never a list position.
  final ValueChanged<String>? onOpenReport;

  final AnalyticsTheme? theme;

  const TrendGraph({
    super.key,
    required this.snapshot,
    this.onOpenReport,
    this.theme,
  });

  @override
  State<TrendGraph> createState() => _TrendGraphState();
}

class _TrendGraphState extends State<TrendGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: (widget.theme ?? const AnalyticsTheme()).drawDuration,
  );

  /// Recomputing positions on every repaint is the cost that makes a chart
  /// feel heavy. Layout only changes when the history or the box does.
  final _geometry = TrendGeometryCache();

  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _draw.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honouring the platform's reduce-motion setting is part of the feature,
    // not a nicety: a drawing line is exactly the kind of motion people
    // switch off because it makes them unwell.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _draw.value = 1;
    } else if (_draw.status == AnimationStatus.dismissed || _draw.value == 1) {
      _draw
        ..value = 0
        ..forward();
    }
  }

  @override
  void didUpdateWidget(TrendGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different subject is a different chart; a selection from the old
    // pet's history must not survive onto the new one's.
    if (oldWidget.snapshot.series.subjectId !=
        widget.snapshot.series.subjectId) {
      _selectedId = null;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? AnalyticsTheme.of(context);
    final series = widget.snapshot.series;
    final extremes = widget.snapshot.extremes;

    return Semantics(
      container: true,
      label: _chartSummary(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, theme.chartHeight);
          final geometry = _geometry.geometryFor(
            series: series,
            size: size,
            minimumSpan: theme.minimumScoreSpan,
          );

          final selected = _selectedNode(geometry);

          return SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _draw,
                      builder: (context, _) => CustomPaint(
                        painter: _TrendPainter(
                          geometry: geometry,
                          progress: _draw.value,
                          line: context.c.actionText,
                          fill: context.c.actionText.withValues(alpha: 0.10),
                          grid: context.c.divider,
                          label: context.c.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                // One gesture layer for the whole plot, so points without a
                // marker are still reachable without a widget each.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) => _selectNearest(geometry, details),
                  ),
                ),
                for (final node in geometry.nodes)
                  if (_isMarked(node, extremes))
                    _Marker(
                      node: node,
                      theme: theme,
                      isSelected: node.point.id == _selectedId,
                      role: _roleOf(node.point, extremes),
                      onTap: () => widget.onOpenReport?.call(node.point.id),
                    ),
                if (selected != null)
                  _Callout(node: selected, geometry: geometry),
              ],
            ),
          );
        },
      ),
    );
  }

  TrendNode? _selectedNode(TrendGeometry geometry) {
    final id = _selectedId;
    if (id == null) return null;
    for (final node in geometry.nodes) {
      if (node.point.id == id) return node;
    }
    return null;
  }

  void _selectNearest(TrendGeometry geometry, TapUpDetails details) {
    final node = geometry.nearest(details.localPosition);
    if (node == null) return;
    setState(() => _selectedId = node.point.id);
  }

  bool _isMarked(TrendNode node, extremes) {
    if (node.point.id == _selectedId) return true;
    return extremes?.marks(node.point.id) ?? false;
  }

  String? _roleOf(AssessmentPoint point, extremes) {
    if (extremes == null) return null;
    // Checked in this order so a single-point history reads as "latest"
    // rather than announcing three roles for one dot.
    if (point.id == extremes.latest.id) return 'Latest';
    if (point.id == extremes.best.id) return 'Highest';
    if (point.id == extremes.worst.id) return 'Lowest';
    return null;
  }

  /// What a screen reader hears for the chart as a whole.
  ///
  /// A shape summary, not a data dump: the per-assessment enumeration is the
  /// list below this graph, and repeating it here would make the screen
  /// twice as long to hear for no extra information.
  String _chartSummary() {
    final series = widget.snapshot.series;
    if (series.isEmpty) return 'Health trend, no assessments recorded';

    final extremes = widget.snapshot.extremes!;
    return 'Health trend chart, ${series.length} assessments. '
        'Latest ${extremes.latest.score} percent, '
        '${extremes.latest.band.label}. '
        'Highest ${extremes.best.score}, lowest ${extremes.worst.score}.';
  }
}

/// One tappable observation.
///
/// Sized to [AnalyticsTheme.minimumTapTarget] regardless of how small the dot
/// looks, so an 8px marker is still a 48dp target.
class _Marker extends StatelessWidget {
  final TrendNode node;
  final AnalyticsTheme theme;
  final bool isSelected;
  final String? role;
  final VoidCallback onTap;

  const _Marker({
    required this.node,
    required this.theme,
    required this.isSelected,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final band = node.point.band;
    final accent = band.bandColor(context.c);
    final target = theme.minimumTapTarget;
    final dot = isSelected ? 15.0 : 11.0;

    return Positioned(
      left: node.offset.dx - target / 2,
      top: node.offset.dy - target / 2,
      width: target,
      height: target,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: [
          if (role != null) role,
          _spokenDate(node.point.takenAt),
          '${node.point.score} percent',
          band.label,
        ].join(', '),
        hint: 'Opens this report',
        container: true,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: context.c.surface, width: 2.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The readout for the selected observation.
class _Callout extends StatelessWidget {
  final TrendNode node;
  final TrendGeometry geometry;

  const _Callout({required this.node, required this.geometry});

  @override
  Widget build(BuildContext context) {
    final band = node.point.band;
    const width = 132.0;

    // Kept inside the plot: a callout for the newest point would otherwise
    // hang off the right edge, which is exactly where the newest point is.
    final left = (node.offset.dx - width / 2)
        .clamp(0.0, (geometry.size.width - width).clamp(0.0, double.infinity));
    final above = node.offset.dy > geometry.size.height / 2;

    return Positioned(
      left: left,
      top: above ? null : node.offset.dy + 26,
      bottom: above ? geometry.size.height - node.offset.dy + 26 : null,
      width: width,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.border),
            boxShadow: context.c.floatShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${node.point.score}%',
                style: AppTheme.font(
                  size: 17,
                  weight: FontWeight.w800,
                  color: band.bandColor(context.c),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                band.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.font(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: context.c.bodyStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _spokenDate(node.point.takenAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.font(size: 11, color: context.c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _spokenDate(DateTime when) {
  final d = when.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Grid, axis, line and fill. Nothing here is tappable or spoken.
///
/// Takes positions rather than working them out: the markers layered over
/// this read the same [TrendGeometry], and two sets of arithmetic would
/// eventually disagree by a pixel.
class _TrendPainter extends CustomPainter {
  final TrendGeometry geometry;
  final double progress;
  final Color line;
  final Color fill;
  final Color grid;
  final Color label;

  const _TrendPainter({
    required this.geometry,
    required this.progress,
    required this.line,
    required this.fill,
    required this.grid,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintAxis(canvas, size);
    if (geometry.nodes.length < 2) return;

    final visible = _visibleNodes();
    if (visible.length < 2) return;

    final path = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (final offset in visible.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }

    final area = Path.from(path)
      ..lineTo(visible.last.dx, geometry.plotBottom)
      ..lineTo(visible.first.dx, geometry.plotBottom)
      ..close();

    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// The line as far as the draw-in has reached, interpolating the final
  /// segment so it grows smoothly rather than snapping point to point.
  List<Offset> _visibleNodes() {
    final all = [for (final node in geometry.nodes) node.offset];
    if (progress >= 1) return all;

    final travelled = progress * (all.length - 1);
    final whole = travelled.floor();
    final fraction = travelled - whole;

    final visible = all.take(whole + 1).toList();
    if (whole + 1 < all.length && fraction > 0) {
      final from = all[whole];
      final to = all[whole + 1];
      visible.add(Offset.lerp(from, to, fraction)!);
    }
    return visible;
  }

  void _paintAxis(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    for (final score in geometry.axisLabels()) {
      final y = geometry.yFor(score);
      canvas.drawLine(
        Offset(geometry.leftInset, y),
        Offset(size.width - geometry.rightInset, y),
        linePaint,
      );

      final painter = TextPainter(
        text: TextSpan(
          text: score.round().toString(),
          style: TextStyle(fontSize: 10, color: label),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(2, y - painter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.progress != progress ||
      !identical(old.geometry, geometry) ||
      old.line != line ||
      old.fill != fill ||
      old.grid != grid ||
      old.label != label;
}
