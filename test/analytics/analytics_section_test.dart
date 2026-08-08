import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/widgets/analytics_section.dart';
import 'package:mypetfit_app/config/theme.dart';

/// Sprint 3, feature 7 — the disclosure primitive.
///
/// A heading that reveals its detail on request, and nothing else. These
/// tests are about the contract every section on Report History inherits:
/// the detail is not built while closed, the state is the platform's rather
/// than a word in a label, and a fingertip can always hit the header.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host(
    Widget child, {
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
  }) =>
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: inner!,
        ),
      );

  void sizeAt(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Tracks whether the detail was ever built, which is the performance claim
  /// this component exists to make.
  Widget section({
    bool initiallyExpanded = false,
    Widget? summary,
    VoidCallback? onBuild,
    String? expandLabel,
    String? collapseLabel,
    String subtitle = 'A line of framing.',
  }) =>
      AnalyticsSection(
        title: 'Health insights',
        subtitle: subtitle,
        initiallyExpanded: initiallyExpanded,
        collapsedSummary: summary,
        expandLabel: expandLabel,
        collapseLabel: collapseLabel,
        builder: (context) {
          onBuild?.call();
          return const Text('THE DETAIL');
        },
      );

  group('disclosure', () {
    testWidgets('starts closed by default', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section()));
      await tester.pumpAndSettle();

      expect(find.text('Health insights'), findsOneWidget);
      expect(find.text('THE DETAIL'), findsNothing);
    });

    testWidgets('starts open when asked to', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section(initiallyExpanded: true)));
      await tester.pumpAndSettle();

      expect(find.text('THE DETAIL'), findsOneWidget);
    });

    testWidgets('opens on a tap and closes again', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Health insights'));
      await tester.pumpAndSettle();
      expect(find.text('THE DETAIL'), findsOneWidget);

      await tester.tap(find.text('Health insights'));
      await tester.pumpAndSettle();
      expect(find.text('THE DETAIL'), findsNothing);
    });

    testWidgets('never builds the detail while closed', (tester) async {
      // The whole point of a builder rather than a widget: a closed section
      // costs a heading, not a heading plus everything under it.
      sizeAt(tester, const Size(400, 900));

      var builds = 0;
      await tester.pumpWidget(host(section(onBuild: () => builds++)));
      await tester.pumpAndSettle();

      expect(builds, 0);

      await tester.tap(find.text('Health insights'));
      await tester.pumpAndSettle();

      expect(builds, greaterThan(0));
    });

    testWidgets('the summary stands in only while closed', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        section(summary: const Text('THE SUMMARY')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('THE SUMMARY'), findsOneWidget);

      await tester.tap(find.text('Health insights'));
      await tester.pumpAndSettle();

      // Once the detail is open the summary would be saying again what is
      // visible just below it.
      expect(find.text('THE SUMMARY'), findsNothing);
      expect(find.text('THE DETAIL'), findsOneWidget);
    });

    testWidgets('the action words follow the state', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section(
        expandLabel: 'View all',
        collapseLabel: 'Show less',
      )));
      await tester.pumpAndSettle();

      expect(find.text('View all'), findsOneWidget);
      expect(find.text('Show less'), findsNothing);

      await tester.tap(find.text('Health insights'));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
      expect(find.text('View all'), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('the header is a button carrying its own expanded state',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section()));
      await tester.pumpAndSettle();

      final header = find.ancestor(
        of: find.text('Health insights'),
        matching: find.byType(Semantics),
      );

      // The platform flag, not an English word appended to the label: a
      // screen reader says "collapsed" in the user's own language, and would
      // say it twice if we wrote it here.
      expect(
        tester.getSemantics(header.first),
        matchesSemantics(
          label: 'Health insights. A line of framing.',
          isButton: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('the expanded state flips with the section', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Health insights'));
      await tester.pumpAndSettle();

      final header = find.ancestor(
        of: find.text('Health insights'),
        matching: find.byType(Semantics),
      );

      expect(
        tester.getSemantics(header.first),
        matchesSemantics(
          label: 'Health insights. A line of framing.',
          isButton: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('no state word is written into the label', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('collapsed')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('expanded')), findsNothing);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('the header stays a fingertip tall at text scale $scale',
          (tester) async {
        sizeAt(tester, const Size(320, 900));

        await tester.pumpWidget(host(
          // The shortest possible heading — nothing else to prop the row up.
          AnalyticsSection(
            title: 'A',
            builder: (context) => const Text('THE DETAIL'),
          ),
          textScale: scale,
        ));
        await tester.pumpAndSettle();

        final header = tester.getRect(find.byType(ConstrainedBox).first);
        expect(header.height, greaterThanOrEqualTo(48));
      });
    }
  });

  group('motion', () {
    testWidgets('expansion is immediate when animations are off',
        (tester) async {
      // No settle, and no pumping the clock forward: the state must simply be
      // true on the very next frame.
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section(), disableAnimations: true));
      await tester.pump();

      await tester.tap(find.text('Health insights'));
      await tester.pump();

      expect(find.text('THE DETAIL'), findsOneWidget);

      await tester.tap(find.text('Health insights'));
      await tester.pump();

      expect(find.text('THE DETAIL'), findsNothing);
    });

    testWidgets('the detail is still reachable when animations are on',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(section()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Health insights'));
      // Mid-flight: the child exists from the first frame, the box is what
      // animates.
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('THE DETAIL'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('presentation', () {
    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 640),
        'large android': Size(412, 915),
        'tablet': Size(834, 1112),
        'landscape': Size(915, 412),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          sizeAt(tester, entry.value);

          await tester.pumpWidget(host(
            AnalyticsSection(
              // The longest heading a real section produces, with the longest
              // action words beside it.
              title: 'Assessment timeline',
              subtitle: '12 assessments on this device.',
              expandLabel: 'View all',
              collapseLabel: 'Show less',
              collapsedSummary: const Text('A summary line'),
              builder: (context) => const Text('THE DETAIL'),
            ),
            textScale: scale,
          ));
          await tester.pumpAndSettle();

          // Built, then asserted — a viewport that never constructed the
          // widget would otherwise pass this happily.
          expect(find.text('Assessment timeline'), findsOneWidget);
          expect(find.text('A summary line'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Assessment timeline'));
          await tester.pumpAndSettle();

          expect(find.text('THE DETAIL'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('renders in dark mode, open and closed', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        section(summary: const Text('THE SUMMARY')),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('THE SUMMARY'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Health insights'));
      await tester.pumpAndSettle();

      expect(find.text('THE DETAIL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
