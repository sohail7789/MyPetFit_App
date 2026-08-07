import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';

/// Sprint 2, feature 1 — the report history timeline.
///
/// The screen was a flat list of dated rows. It is a grouped timeline now,
/// carrying the pet each report belongs to, and every entry still has to
/// open its own stored report.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A fixed clock for the pure functions, which take `now` as an argument.
  final now = DateTime(2026, 8, 7, 14);

  /// Widget tests cannot inject a clock — the screen reads the real one — so
  /// their fixtures are dated relative to the actual today. Pinning them to a
  /// fixed date made them pass only on the day they were written.
  ScoreResult report(
    int percent, {
    required int daysAgo,
    String petId = 'p1',
    HealthCategory band = HealthCategory.good,
    DateTime? from,
  }) =>
      ScoreResult(
        rawScore: percent,
        maxPossibleScore: 100,
        percentageScore: percent,
        category: band,
        completedAt: (from ?? DateTime.now()).subtract(Duration(days: daysAgo)),
        petId: petId,
      );

  /// The date label a widget test should expect for a report [daysAgo] old.
  String dateLabel(int daysAgo) =>
      exactReportDate(DateTime.now().subtract(Duration(days: daysAgo)));

  /// A timeline row's full date line, which is unique per report.
  ///
  /// Matched exactly rather than by substring: milestone cards below the
  /// timeline carry dates of their own, so a partial match is ambiguous.
  String rowDateLine(int daysAgo) {
    final when = DateTime.now().subtract(Duration(days: daysAgo));
    return '${relativeReportDate(when)} · ${exactReportDate(when)}';
  }

  PetInfo pet(String id, String name) => PetInfo(
        id: id,
        name: name,
        breed: 'Beagle',
        ageYears: 3,
        ageMonths: 2,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  Future<QuizProvider> quizWith(
    Map<String, List<ScoreResult>> byPet, {
    String bindTo = 'p1',
  }) async {
    final quiz = QuizProvider(service: FakeCloud(assessments: byPet));
    await quiz.init();
    await quiz.loadAssessmentsFromFirestore();
    quiz.bindPet(bindTo);
    return quiz;
  }

  Future<PetInfoProvider> withPets(List<PetInfo> list) async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    for (final p in list) {
      await pets.addPet(p);
    }
    pets.setActivePet(0);
    return pets;
  }

  Widget host(QuizProvider quiz, PetInfoProvider pets) {
    final router = GoRouter(
      initialLocation: AppRoutes.reportHistory,
      routes: [
        GoRoute(
          path: AppRoutes.reportHistory,
          builder: (_, _) => const ReportHistoryScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.report}/history/:index',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('REPORT ${state.pathParameters['index']}'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.quiz,
          builder: (_, _) => const Scaffold(body: Center(child: Text('QUIZ'))),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: pets),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('bucketing', () {
    HistoryBucket bucketAt(int daysAgo) =>
        bucketFor(now.subtract(Duration(days: daysAgo)), now: now);

    test('rolling windows, and every boundary lands where it should', () {
      expect(bucketAt(0), HistoryBucket.today);
      expect(bucketAt(1), HistoryBucket.yesterday);
      expect(bucketAt(2), HistoryBucket.lastSevenDays);
      expect(bucketAt(6), HistoryBucket.lastSevenDays);
      expect(bucketAt(7), HistoryBucket.thisMonth);
      expect(bucketAt(29), HistoryBucket.thisMonth);
      expect(bucketAt(30), HistoryBucket.older);
      expect(bucketAt(400), HistoryBucket.older);
    });

    test('the windows roll, so a report cannot change bucket overnight', () {
      // Counted back from today rather than by calendar period: a report
      // taken on the 31st must not jump to "Older" merely because the month
      // rolled over.
      final taken = DateTime(2026, 7, 31);
      expect(
        bucketFor(taken, now: DateTime(2026, 8, 1)),
        HistoryBucket.yesterday,
      );
      expect(
        bucketFor(taken, now: DateTime(2026, 8, 5)),
        HistoryBucket.lastSevenDays,
      );
    });

    test('a clock-skewed future report buckets as today', () {
      // Records sync from handsets whose clocks disagree; filing one under
      // "Earlier" because a phone ran fast would be worse than imprecision.
      expect(
        bucketFor(now.add(const Duration(days: 2)), now: now),
        HistoryBucket.today,
      );
    });

    test('earlier the same day is still today', () {
      expect(bucketFor(DateTime(2026, 8, 7, 1), now: now), HistoryBucket.today);
    });
  });

  group('grouping', () {
    test('keeps the newest-first order it was given', () {
      final groups = groupHistory([
        report(80, daysAgo: 0, from: now),
        report(75, daysAgo: 1, from: now),
        report(70, daysAgo: 3, from: now),
        report(68, daysAgo: 15, from: now),
        report(65, daysAgo: 40, from: now),
      ], now: now);

      expect(groups.map((g) => g.bucket), [
        HistoryBucket.today,
        HistoryBucket.yesterday,
        HistoryBucket.lastSevenDays,
        HistoryBucket.thisMonth,
        HistoryBucket.older,
      ]);
    });

    test('every entry keeps its index in the flat list', () {
      // The index is what the report route addresses. Renumbering inside a
      // group would open the wrong report for every group after the first.
      final groups = groupHistory([
        report(80, daysAgo: 0, from: now),
        report(75, daysAgo: 30, from: now),
        report(70, daysAgo: 60, from: now),
        report(65, daysAgo: 90, from: now),
      ], now: now);

      expect(groups.length, 2);
      expect(groups.first.entries.map((e) => e.index), [0]);
      expect(groups.last.entries.map((e) => e.index), [1, 2, 3]);
      expect(
        groups.expand((g) => g.entries).map((e) => e.result.percentageScore),
        [80, 75, 70, 65],
      );
    });

    test('several reports on one day share a group', () {
      final groups = groupHistory([
        report(80, daysAgo: 0, from: now),
        report(78, daysAgo: 0, from: now),
      ], now: now);

      expect(groups.length, 1);
      expect(groups.single.entries.length, 2);
    });

    test('empty buckets are dropped, not rendered as bare headings', () {
      final groups = groupHistory([
        report(80, daysAgo: 0, from: now),
        report(65, daysAgo: 200, from: now),
      ], now: now);

      expect(groups.map((g) => g.bucket),
          [HistoryBucket.today, HistoryBucket.older]);
    });

    test('no history groups into nothing', () {
      expect(groupHistory(const [], now: now), isEmpty);
    });
  });

  group('date labels', () {
    String ago(int days) =>
        relativeReportDate(now.subtract(Duration(days: days)), now: now);

    test('coarsen as they recede', () {
      expect(ago(0), 'Today');
      expect(ago(1), 'Yesterday');
      expect(ago(4), '4 days ago');
      expect(ago(10), 'Last week');
      expect(ago(21), '3 weeks ago');
      expect(ago(45), 'Last month');
      expect(ago(120), '4 months ago');
      expect(ago(500), 'Over a year ago');
    });

    test('the exact date is spelled out', () {
      expect(exactReportDate(DateTime(2026, 2, 14)), '14 Feb 2026');
      expect(exactReportDate(DateTime(2025, 12, 1)), '1 Dec 2025');
    });
  });

  group('the timeline', () {
    testWidgets('groups reports under headings, newest first', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [
          report(80, daysAgo: 0),
          report(75, daysAgo: 1),
          report(70, daysAgo: 3),
          report(68, daysAgo: 15),
          report(65, daysAgo: 200),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('LAST 7 DAYS'), findsOneWidget);
      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('OLDER'), findsOneWidget);
    });

    testWidgets('each entry carries the pet, the band and both dates',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report(80, daysAgo: 0), report(75, daysAgo: 30)],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // Every row names the pet; no assessment number, which could not be
      // kept stable once history is trimmed.
      expect(find.text('Bruno'), findsNWidgets(2));
      expect(find.textContaining('#'), findsNothing);
      expect(find.text('Good'), findsNWidgets(2));
      expect(find.text('Today · ${dateLabel(0)}'), findsOneWidget);
      expect(find.textContaining('Last month · '), findsOneWidget);
      // Once on its row. The trend graph above plots the score rather than
      // printing it, so it no longer duplicates the figure.
      expect(find.text('80'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
    });

    testWidgets('opens the report the row belongs to, across groups',
        (tester) async {
      sizeUp(tester);
      // Index 2 sits in the second group — the case a within-group index
      // would get wrong.
      final quiz = await quizWith({
        'p1': [
          report(80, daysAgo: 0),
          report(75, daysAgo: 30),
          report(70, daysAgo: 60),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // Rows are addressed by their full date line, which is unique.
      await tester.tap(find.text(rowDateLine(60)));
      await tester.pumpAndSettle();

      expect(find.text('REPORT 2'), findsOneWidget);
    });

    testWidgets('the newest row opens index zero', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report(80, daysAgo: 0), report(75, daysAgo: 30)],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today · ${dateLabel(0)}'));
      await tester.pumpAndSettle();

      expect(find.text('REPORT 0'), findsOneWidget);
    });

    testWidgets('reads as one entry to a screen reader', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({'p1': [report(80, daysAgo: 1)]});

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Bruno, 80 percent, Good, Yesterday'),
        findsOneWidget,
      );
    });
  });

  group('multiple pets', () {
    testWidgets('the timeline follows the active pet and does not duplicate',
        (tester) async {
      sizeUp(tester);
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      final quiz = await quizWith({
        'p1': [report(80, daysAgo: 0), report(75, daysAgo: 30)],
        'p2': [report(40, daysAgo: 2, petId: 'p2')],
      });

      await tester.pumpWidget(host(quiz, pets));
      await tester.pumpAndSettle();

      expect(find.text('Bruno'), findsNWidgets(2));
      expect(find.textContaining('Mia'), findsNothing);

      // main.dart binds the quiz to the active pet; driven the same way here.
      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      expect(find.text('Mia'), findsOneWidget);
      expect(find.textContaining('Bruno'), findsNothing);
      // One report for Mia, so exactly one row — no carry-over.
      expect(find.text('Current'), findsOneWidget);
    });

    testWidgets('a pet with no reports gets the empty state', (tester) async {
      sizeUp(tester);
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      final quiz = await quizWith({
        'p1': [report(80, daysAgo: 0)],
      });

      await tester.pumpWidget(host(quiz, pets));
      await tester.pumpAndSettle();
      expect(find.text('Bruno'), findsOneWidget);

      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      expect(find.text('No reports yet'), findsOneWidget);
      expect(find.textContaining('Bruno'), findsNothing);
    });
  });

  group('before the pet record is read', () {
    testWidgets('a row still renders without an orphaned avatar',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({'p1': [report(80, daysAgo: 0)]});
      // Not init()ed: activePet is null for these frames.
      final pets = PetInfoProvider(service: FakeCloud());

      await tester.pumpWidget(host(quiz, pets));
      await tester.pump();

      // No name line at all rather than an avatar beside empty text.
      expect(find.text('80'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
    });
  });
}
