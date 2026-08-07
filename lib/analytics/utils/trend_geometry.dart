import 'dart:ui' show Offset, Size;

import '../models/assessment_point.dart';
import '../models/assessment_series.dart';

/// One observation placed on a chart.
class TrendNode {
  final AssessmentPoint point;

  /// Where it sits inside the plot area, in local coordinates.
  final Offset offset;

  const TrendNode({required this.point, required this.offset});
}

/// Where a trend's observations sit on a canvas.
///
/// Rendering maths, deliberately not analytics: the domain says what the
/// data means, this says where to draw it. Kept apart from the painter for
/// one reason — the painted line and the tappable markers must agree to the
/// pixel, and they only can if both read the same computed positions rather
/// than each doing their own arithmetic.
///
/// Pure and Flutter-free beyond `dart:ui`, so a web renderer can reuse it.
class TrendGeometry {
  final Size size;

  /// Inset from each edge, leaving room for axis labels.
  final double leftInset;
  final double rightInset;
  final double topInset;
  final double bottomInset;

  /// The score at the bottom and top of the drawn axis.
  final double axisMin;
  final double axisMax;

  /// Oldest first, matching the series.
  final List<TrendNode> nodes;

  const TrendGeometry({
    required this.size,
    required this.axisMin,
    required this.axisMax,
    required this.nodes,
    this.leftInset = 34,
    this.rightInset = 10,
    this.topInset = 14,
    this.bottomInset = 24,
  });

  /// Places [series] inside [size].
  ///
  /// **The Y axis never fits itself tightly to the data.** Auto-scaling a
  /// three-point wobble to fill the card turns ordinary variation into what
  /// looks like a collapse, which for a health record is worse than a dull
  /// chart. [minimumSpan] is the smallest range the axis will show; the
  /// window is centred on the data and then slid to stay inside 0–100.
  ///
  /// **The X axis is proportional to time**, not to position in the list.
  /// Assessments three years apart must not read as adjacent to ones a week
  /// apart, and observations clustering in one month is itself information.
  static TrendGeometry compute({
    required AssessmentSeries series,
    required Size size,
    required double minimumSpan,
    double leftInset = 34,
    double rightInset = 10,
    double topInset = 14,
    double bottomInset = 24,
  }) {
    if (series.isEmpty) {
      return TrendGeometry(
        size: size,
        axisMin: 0,
        axisMax: 100,
        nodes: const [],
        leftInset: leftInset,
        rightInset: rightInset,
        topInset: topInset,
        bottomInset: bottomInset,
      );
    }

    var lowest = series.points.first.score.toDouble();
    var highest = lowest;
    for (final point in series.points) {
      final score = point.score.toDouble();
      if (score < lowest) lowest = score;
      if (score > highest) highest = score;
    }

    final span = (highest - lowest) < minimumSpan
        ? minimumSpan
        : (highest - lowest);
    final centre = (highest + lowest) / 2;

    var axisMin = centre - span / 2;
    var axisMax = centre + span / 2;

    // Slide, rather than clip, so the requested span is preserved when the
    // data sits near an end of the scale.
    if (axisMin < 0) {
      axisMax += -axisMin;
      axisMin = 0;
    }
    if (axisMax > 100) {
      axisMin -= axisMax - 100;
      axisMax = 100;
    }
    if (axisMin < 0) axisMin = 0;

    final plotWidth = (size.width - leftInset - rightInset).clamp(1.0, 1 << 20);
    final plotHeight =
        (size.height - topInset - bottomInset).clamp(1.0, 1 << 20);
    final axisSpan = (axisMax - axisMin).abs() < 0.001 ? 1.0 : axisMax - axisMin;

    final firstAt = series.first!.takenAt;
    final totalMs = series.latest!.takenAt.difference(firstAt).inMilliseconds;

    final nodes = <TrendNode>[];
    for (var i = 0; i < series.length; i++) {
      final point = series.points[i];

      // Everything recorded at one instant — a fixture, or two assessments
      // filed together — spreads evenly rather than stacking on one column.
      final fraction = totalMs <= 0
          ? (series.length == 1 ? 0.5 : i / (series.length - 1))
          : point.takenAt.difference(firstAt).inMilliseconds / totalMs;

      final normalised =
          ((point.score - axisMin) / axisSpan).clamp(0.0, 1.0).toDouble();

      nodes.add(
        TrendNode(
          point: point,
          offset: Offset(
            leftInset + plotWidth * fraction,
            topInset + plotHeight * (1 - normalised),
          ),
        ),
      );
    }

    return TrendGeometry(
      size: size,
      axisMin: axisMin,
      axisMax: axisMax,
      nodes: nodes,
      leftInset: leftInset,
      rightInset: rightInset,
      topInset: topInset,
      bottomInset: bottomInset,
    );
  }

  bool get isEmpty => nodes.isEmpty;

  double get plotTop => topInset;

  double get plotBottom => size.height - bottomInset;

  /// The y for a score on the drawn axis.
  double yFor(double score) {
    final axisSpan = (axisMax - axisMin).abs() < 0.001 ? 1.0 : axisMax - axisMin;
    final normalised = ((score - axisMin) / axisSpan).clamp(0.0, 1.0);
    return plotTop + (plotBottom - plotTop) * (1 - normalised);
  }

  /// The observation nearest [local], or null on an empty chart.
  ///
  /// Compared on the horizontal only. A time series is read left to right,
  /// and a tap a little above or below the line still means "that date" —
  /// matching on true distance would pick a neighbouring point whenever the
  /// line was steep.
  TrendNode? nearest(Offset local) {
    if (nodes.isEmpty) return null;

    var closest = nodes.first;
    var best = (closest.offset.dx - local.dx).abs();

    for (final node in nodes.skip(1)) {
      final distance = (node.offset.dx - local.dx).abs();
      if (distance < best) {
        best = distance;
        closest = node;
      }
    }
    return closest;
  }

  /// Evenly spaced score labels for the axis, low to high.
  List<double> axisLabels({int count = 4}) {
    if (count < 2) return [axisMin, axisMax];
    final step = (axisMax - axisMin) / (count - 1);
    return [for (var i = 0; i < count; i++) axisMin + step * i];
  }
}

/// Holds the last computed geometry so a repaint does not redo the maths.
///
/// A chart repaints on every animation frame and again on every hover or
/// selection. Recomputing positions for hundreds of observations each time
/// is the cost that makes an analytics screen feel heavy, and it is entirely
/// avoidable: the layout only changes when the history or the box does.
class TrendGeometryCache {
  String? _key;
  TrendGeometry? _cached;

  TrendGeometry geometryFor({
    required AssessmentSeries series,
    required Size size,
    required double minimumSpan,
  }) {
    final key = '${series.identity}/${size.width}x${size.height}/$minimumSpan';
    final cached = _cached;
    if (cached != null && _key == key) return cached;

    final computed = TrendGeometry.compute(
      series: series,
      size: size,
      minimumSpan: minimumSpan,
    );
    _key = key;
    _cached = computed;
    return computed;
  }

  /// Whether [series] at [size] would be served from the cache.
  bool holds({
    required AssessmentSeries series,
    required Size size,
    required double minimumSpan,
  }) =>
      _cached != null &&
      _key == '${series.identity}/${size.width}x${size.height}/$minimumSpan';
}
