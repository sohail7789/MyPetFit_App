import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mypetfit_app/analytics/widgets/analytics_overview_card.dart';
import 'package:mypetfit_app/analytics/widgets/category_trend_card.dart';
import 'package:mypetfit_app/analytics/widgets/trend_graph.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';

import '../test/support/fake_cloud.dart';
import 'support/harness.dart';

/// The journeys worth running on real hardware.
///
/// Widget tests already cover the logic in each of these. What a device adds
/// is everything the test harness fakes away: real layout at the device's own
/// size and text scale, real gestures and fling physics, real scrolling in a
/// lazily built list, and the platform channels behind SharedPreferences.
///
/// Firebase is faked here on purpose — see the README. These prove the app,
/// not the backend.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetDeviceState);

  group('report history on a device', () {
    testWidgets('a pet with history reads from summary to record',
        (tester) async {
      final cloud = FakeCloud(
        pets: [testPet('p1', 'Bruno')],
        assessments: {
          'p1': [
            testReport(74, petId: 'p1', daysAgo: 0),
            testReport(66, petId: 'p1', daysAgo: 30),
            testReport(58, petId: 'p1', daysAgo: 60),
            testReport(52, petId: 'p1', daysAgo: 90),
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

      // The two answers that must not need a tap.
      expect(find.byType(AnalyticsOverviewCard), findsOneWidget);
      expect(find.byType(TrendGraph), findsOneWidget);

      // Four records, so the timeline is closed — and the newest is visible
      // anyway. This is the disclosure rule, verified against a real
      // viewport rather than an assumed one.
      expect(find.text('Assessment timeline'), findsOneWidget);

      // Real scrolling through a lazily built list, which is the part a
      // widget test's oversized viewport never exercises.
      await tester.scrollUntilVisible(
        find.text('Category progress'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Category progress'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryTrendCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching pets leaves nothing of the previous one',
        (tester) async {
      // The invariant that matters most on this screen, run where the widget
      // tree is rebuilt for real.
      final cloud = FakeCloud(
        pets: [testPet('p1', 'Bruno'), testPet('p2', 'Mia')],
        assessments: {
          'p1': [
            testReport(74, petId: 'p1', daysAgo: 0),
            testReport(66, petId: 'p1', daysAgo: 30),
          ],
          'p2': [
            testReport(38, petId: 'p2', daysAgo: 2, band: HealthCategory.needsImprovement),
            testReport(30, petId: 'p2', daysAgo: 40, band: HealthCategory.needsImprovement),
          ],
        },
      );

      final quiz = await quizWithHistory(cloud, bindTo: 'p1');
      final pets = await petsWith(
        cloud,
        [testPet('p1', 'Bruno'), testPet('p2', 'Mia')],
      );

      await tester.pumpWidget(hostScreen(
        const ReportHistoryScreen(),
        initial: AppRoutes.reportHistory,
        cloud: cloud,
        quiz: quiz,
        pets: pets,
      ));
      await tester.pumpAndSettle();

      expect(find.text('74'), findsWidgets);

      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      expect(find.text('74'), findsNothing, reason: "Bruno's score survived");
      expect(find.text('Bruno'), findsNothing);
      expect(find.text('38'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('assessment history survives a bad restore', () {
    testWidgets('a failing cloud read leaves the record on screen',
        (tester) async {
      // P1-1, on a device: the local record has to still be there after the
      // restore fails, and the screen has to still render it.
      final cloud = FakeCloud(
        pets: [testPet('p1', 'Bruno')],
        assessments: {
          'p1': [
            testReport(74, petId: 'p1', daysAgo: 0),
            testReport(66, petId: 'p1', daysAgo: 30),
          ],
        },
      );

      final quiz = await quizWithHistory(cloud, bindTo: 'p1');
      final pets = await petsWith(cloud, [testPet('p1', 'Bruno')]);

      await tester.pumpWidget(hostScreen(
        const ReportHistoryScreen(),
        initial: AppRoutes.reportHistory,
        cloud: cloud,
        quiz: quiz,
        pets: pets,
      ));
      await tester.pumpAndSettle();
      expect(find.text('74'), findsWidgets);

      // The connection drops, and a restore is attempted anyway.
      cloud.offline = Exception('network unavailable');
      await expectLater(
        quiz.loadAssessmentsFromFirestore(),
        throwsA(isA<Exception>()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('74'),
        findsWidgets,
        reason: 'the failed restore emptied the visible history',
      );
      expect(quiz.historyFor('p1'), hasLength(2));
    });
  });
}
