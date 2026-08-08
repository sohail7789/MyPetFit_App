import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/firebase_startup_provider.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';
import 'package:mypetfit_app/screens/startup/firebase_unavailable_screen.dart';

import '../test/support/fake_cloud.dart';
import 'support/harness.dart';

/// Startup recovery and screen-reader operability, on real hardware.
///
/// The accessibility half is the part that most needs a device: a semantics
/// tree assembled by the real platform is not the one a test harness builds,
/// and "a screen reader can press this" is a claim about the platform.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetDeviceState);

  group('Firebase startup recovery', () {
    testWidgets('a failed connection offers a retry that retries',
        (tester) async {
      var attempts = 0;
      final firebase = FirebaseStartupProvider(initialise: () async {
        attempts++;
        if (attempts == 1) throw Exception('no network');
      });

      await firebase.connect();
      expect(firebase.hasFailed, isTrue);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: FirebaseUnavailableScreen(onRetry: firebase.connect),
      ));
      await tester.pumpAndSettle();

      expect(find.text("MyPetFit can't connect"), findsOneWidget);
      // Nothing internal on screen, on a real render.
      expect(find.textContaining('Exception'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(attempts, 2, reason: 'the retry did not retry anything');
      expect(firebase.isReady, isTrue);
    });
  });

  group('a screen reader can operate the app', () {
    /// Fires the platform's own tap action, the way assistive technology
    /// does — not a pointer event.
    void activate(WidgetTester tester, Finder finder, {String? because}) {
      final node = tester.getSemantics(finder);
      final data = node.getSemanticsData();

      expect(data.flagsCollection.isButton, isTrue, reason: because);
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'announced as a button but offers no tap action'
            '${because == null ? '' : ' — $because'}',
      );

      node.owner!.performAction(node.id, SemanticsAction.tap);
    }

    testWidgets('a timeline row opens its report through semantics',
        (tester) async {
      final handle = tester.ensureSemantics();

      final cloud = FakeCloud(
        pets: [testPet('p1', 'Bruno')],
        assessments: {
          'p1': [
            testReport(74, petId: 'p1', daysAgo: 0),
            testReport(66, petId: 'p1', daysAgo: 30),
          ],
        },
      );

      await tester.pumpWidget(hostScreen(
        const ReportHistoryScreen(),
        initial: AppRoutes.reportHistory,
        cloud: cloud,
        quiz: await quizWithHistory(cloud, bindTo: 'p1'),
        pets: await petsWith(cloud, [testPet('p1', 'Bruno')]),
        extraRoutes: [reportRouteStub()],
      ));
      await tester.pumpAndSettle();

      final row = find.bySemanticsLabel(RegExp(r'^Bruno, 66 percent'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      activate(tester, row, because: 'the older report on the timeline');
      await tester.pumpAndSettle();

      expect(find.text('REPORT 1'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the disclosure headings carry their expanded state',
        (tester) async {
      final handle = tester.ensureSemantics();

      final cloud = FakeCloud(
        pets: [testPet('p1', 'Bruno')],
        assessments: {
          'p1': [
            testReport(74, petId: 'p1', daysAgo: 0),
            testReport(66, petId: 'p1', daysAgo: 30),
          ],
        },
      );

      await tester.pumpWidget(hostScreen(
        const ReportHistoryScreen(),
        initial: AppRoutes.reportHistory,
        cloud: cloud,
        quiz: await quizWithHistory(cloud, bindTo: 'p1'),
        pets: await petsWith(cloud, [testPet('p1', 'Bruno')]),
      ));
      await tester.pumpAndSettle();

      final heading = find.bySemanticsLabel(RegExp('^Category progress'));
      await tester.scrollUntilVisible(
        heading,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // The platform's own expanded flag, not an English word in a label.
      //
      // Tristate, not bool: `Tristate.none` means the node never declared an
      // expanded state at all, which a screen reader announces as a plain
      // button. Asserting `Tristate.isFalse` is therefore the stronger claim
      // — the section says it is collapsed rather than saying nothing.
      expect(
        tester.getSemantics(heading).getSemanticsData().flagsCollection.isExpanded,
        Tristate.isFalse,
      );

      activate(tester, heading);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(heading).getSemanticsData().flagsCollection.isExpanded,
        Tristate.isTrue,
      );

      handle.dispose();
    });
  });
}
