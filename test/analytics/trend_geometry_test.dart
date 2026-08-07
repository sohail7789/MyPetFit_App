import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/utils/trend_geometry.dart';
import 'package:mypetfit_app/models/score_result.dart';

/// Sprint 3, feature 2 — where the chart draws things.
///
/// Rendering maths, so it is tested as maths: no widget tree, no canvas.
void main() {
  final epoch = DateTime.utc(2026, 1, 1);
  const size = Size(300, 200);

  AssessmentSeries seriesOf(List<(int score, int dayOffset)> entries) =>
      AssessmentSeries(
        subjectId: 'p1',
        points: [
          for (final (score, dayOffset) in entries)
            AssessmentPoint(
              id: AssessmentPoint.idFor(
                'p1',
                epoch.add(Duration(days: dayOffset)),
              ),
              takenAt: epoch.add(Duration(days: dayOffset)),
              score: score,
              band: HealthCategory.good,
            ),
        ],
      );

  TrendGeometry geometryOf(
    List<(int, int)> entries, {
    double minimumSpan = 40,
  }) =>
      TrendGeometry.compute(
        series: seriesOf(entries),
        size: size,
        minimumSpan: minimumSpan,
      );

  group('the score axis never flatters a small change', () {
    test('a narrow range is padded to the minimum span', () {
      // Six points of movement must not fill the card. Fitting the axis to
      // the data would turn ordinary variation into what looks like a
      // collapse, which for a health record is the worse failure.
      final geometry = geometryOf([(72, 0), (78, 30)]);

      expect(geometry.axisMax - geometry.axisMin, 40);
      expect(geometry.axisMin, 55);
      expect(geometry.axisMax, 95);
    });

    test('a wide range is shown in full', () {
      final geometry = geometryOf([(20, 0), (95, 30)]);

      expect(geometry.axisMin, lessThanOrEqualTo(20));
      expect(geometry.axisMax, greaterThanOrEqualTo(95));
    });

    test('the window slides rather than clipping near the floor', () {
      // Scores at the bottom of the scale still get the full span, shifted
      // up, instead of a squashed axis.
      final geometry = geometryOf([(2, 0), (8, 30)]);

      expect(geometry.axisMin, 0);
      expect(geometry.axisMax, 40);
    });

    test('and near the ceiling', () {
      final geometry = geometryOf([(96, 0), (99, 30)]);

      expect(geometry.axisMax, 100);
      expect(geometry.axisMin, 60);
    });

    test('the span is configurable, not baked in', () {
      final tight = geometryOf([(72, 0), (78, 30)], minimumSpan: 10);

      expect(tight.axisMax - tight.axisMin, 10);
    });

    test('identical scores do not divide by zero', () {
      final geometry = geometryOf([(70, 0), (70, 30), (70, 60)]);

      expect(geometry.axisMax - geometry.axisMin, 40);
      for (final node in geometry.nodes) {
        expect(node.offset.dy.isFinite, isTrue);
      }
    });

    test('the axis stays inside the possible score range', () {
      for (final entries in [
        [(0, 0), (0, 30)],
        [(100, 0), (100, 30)],
        [(0, 0), (100, 30)],
      ]) {
        final geometry = geometryOf(entries);
        expect(geometry.axisMin, greaterThanOrEqualTo(0));
        expect(geometry.axisMax, lessThanOrEqualTo(100));
      }
    });
  });

  group('time, not position, decides the horizontal', () {
    test('an even cadence spaces evenly', () {
      final geometry = geometryOf([(60, 0), (70, 30), (80, 60)]);
      final xs = geometry.nodes.map((n) => n.offset.dx).toList();

      expect(xs[1] - xs[0], closeTo(xs[2] - xs[1], 0.001));
    });

    test('a long gap reads as a long gap', () {
      // Three years then a week apart must not look like three even steps.
      final geometry = geometryOf([(60, 0), (70, 1095), (80, 1102)]);
      final xs = geometry.nodes.map((n) => n.offset.dx).toList();

      expect(xs[1] - xs[0], greaterThan((xs[2] - xs[1]) * 10));
    });

    test('the first and last sit at the edges of the plot', () {
      final geometry = geometryOf([(60, 0), (80, 90)]);

      expect(geometry.nodes.first.offset.dx, closeTo(geometry.leftInset, 0.001));
      expect(
        geometry.nodes.last.offset.dx,
        closeTo(size.width - geometry.rightInset, 0.001),
      );
    });

    test('observations filed at one instant spread instead of stacking', () {
      final geometry = geometryOf([(60, 0), (70, 0), (80, 0)]);
      final xs = geometry.nodes.map((n) => n.offset.dx).toList();

      expect(xs[0], lessThan(xs[1]));
      expect(xs[1], lessThan(xs[2]));
    });

    test('a single observation is centred, not crashed on', () {
      final geometry = geometryOf([(60, 0)]);

      expect(geometry.nodes.single.offset.dx, closeTo(size.width / 2, 20));
      expect(geometry.nodes.single.offset.dy.isFinite, isTrue);
    });

    test('an empty history produces no nodes and no exception', () {
      final geometry = TrendGeometry.compute(
        series: const AssessmentSeries.empty('p1'),
        size: size,
        minimumSpan: 40,
      );

      expect(geometry.isEmpty, isTrue);
      expect(geometry.nodes, isEmpty);
    });
  });

  group('higher scores sit higher', () {
    test('the best point is above the worst', () {
      final geometry = geometryOf([(40, 0), (90, 30)]);

      expect(geometry.nodes.last.offset.dy,
          lessThan(geometry.nodes.first.offset.dy));
    });

    test('every node lands inside the plot area', () {
      final geometry = geometryOf([(0, 0), (50, 30), (100, 60)]);

      for (final node in geometry.nodes) {
        expect(node.offset.dy, greaterThanOrEqualTo(geometry.plotTop - 0.001));
        expect(
          node.offset.dy,
          lessThanOrEqualTo(geometry.plotBottom + 0.001),
        );
      }
    });
  });

  group('nearest-point hit testing', () {
    test('a tap picks the observation nearest in time', () {
      final geometry = geometryOf([(60, 0), (70, 30), (80, 60)]);
      final middle = geometry.nodes[1];

      final picked = geometry.nearest(
        Offset(middle.offset.dx + 3, middle.offset.dy),
      );

      expect(picked!.point.id, middle.point.id);
    });

    test('vertical distance does not sway the choice', () {
      // A tap above or below the line still means "that date" — matching on
      // true distance would pick a neighbour wherever the line was steep.
      final geometry = geometryOf([(10, 0), (95, 30)]);
      final first = geometry.nodes.first;

      final picked = geometry.nearest(Offset(first.offset.dx, 0));

      expect(picked!.point.id, first.point.id);
    });

    test('a tap past the end picks the end', () {
      final geometry = geometryOf([(60, 0), (70, 30), (80, 60)]);

      expect(
        geometry.nearest(const Offset(1000, 100))!.point.id,
        geometry.nodes.last.point.id,
      );
      expect(
        geometry.nearest(const Offset(-50, 100))!.point.id,
        geometry.nodes.first.point.id,
      );
    });

    test('an empty chart picks nothing rather than throwing', () {
      final geometry = TrendGeometry.compute(
        series: const AssessmentSeries.empty('p1'),
        size: size,
        minimumSpan: 40,
      );

      expect(geometry.nearest(const Offset(10, 10)), isNull);
    });
  });

  group('the geometry cache', () {
    test('computes once for a given history and box', () {
      final cache = TrendGeometryCache();
      final series = seriesOf([(60, 0), (70, 30)]);

      final first =
          cache.geometryFor(series: series, size: size, minimumSpan: 40);

      expect(cache.holds(series: series, size: size, minimumSpan: 40), isTrue);
      expect(
        identical(
          cache.geometryFor(series: series, size: size, minimumSpan: 40),
          first,
        ),
        isTrue,
        reason: 'a repaint must not redo the layout maths',
      );
    });

    test('recomputes when the box changes', () {
      final cache = TrendGeometryCache();
      final series = seriesOf([(60, 0), (70, 30)]);

      final portrait =
          cache.geometryFor(series: series, size: size, minimumSpan: 40);
      final landscape = cache.geometryFor(
        series: series,
        size: const Size(700, 140),
        minimumSpan: 40,
      );

      expect(identical(portrait, landscape), isFalse);
    });

    test('recomputes when the history changes', () {
      final cache = TrendGeometryCache();
      final before = seriesOf([(60, 0)]);
      final after = seriesOf([(60, 0), (75, 30)]);

      cache.geometryFor(series: before, size: size, minimumSpan: 40);

      expect(cache.holds(series: after, size: size, minimumSpan: 40), isFalse);
    });

    test('recomputes when the requested span changes', () {
      final cache = TrendGeometryCache();
      final series = seriesOf([(60, 0), (70, 30)]);

      cache.geometryFor(series: series, size: size, minimumSpan: 40);

      expect(cache.holds(series: series, size: size, minimumSpan: 10), isFalse);
    });
  });

  group('axis labels', () {
    test('run low to high across the drawn range', () {
      final geometry = geometryOf([(40, 0), (90, 30)]);
      final labels = geometry.axisLabels();

      expect(labels.first, geometry.axisMin);
      expect(labels.last, geometry.axisMax);
      for (var i = 1; i < labels.length; i++) {
        expect(labels[i], greaterThan(labels[i - 1]));
      }
    });
  });
}
