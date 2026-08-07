import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';
import 'support/product_fixtures.dart';

/// Sprint 1, feature 2 — the fitness card.
///
/// It showed the score and band but nothing about movement: an absolute
/// "Last assessed 24 Feb" that means little at a glance, and no comparison
/// against the previous report even though the history was already loaded.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ScoreResult report(int percent, {int daysAgo = 0, String petId = 'p1'}) =>
      ScoreResult(
        rawScore: percent,
        maxPossibleScore: 100,
        percentageScore: percent,
        category: HealthCategory.good,
        completedAt: DateTime.now().subtract(Duration(days: daysAgo)),
        petId: petId,
      );

  PetInfo bruno() => PetInfo(
        id: 'p1',
        name: 'Bruno',
        breed: 'Beagle',
        ageYears: 3,
        ageMonths: 2,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  /// A quiz provider holding [reports], restored through its own cloud path
  /// rather than a test-only setter, and bound to the pet they belong to.
  Future<QuizProvider> quizWith(
    List<ScoreResult> reports, {
    String bindTo = 'p1',
  }) async {
    final byPet = <String, List<ScoreResult>>{};
    for (final r in reports) {
      byPet.putIfAbsent(r.petId!, () => []).add(r);
    }
    final quiz = QuizProvider(service: FakeCloud(assessments: byPet));
    await quiz.loadAssessmentsFromFirestore();
    quiz.bindPet(bindTo);
    return quiz;
  }

  Widget host(QuizProvider quiz, PetInfoProvider pets) {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomeDashboardScreen(),
        ),
        for (final path in [
          AppRoutes.petInfo,
          AppRoutes.quiz,
          AppRoutes.report,
          AppRoutes.shop,
          AppRoutes.account,
          AppRoutes.inbox,
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Center(child: Text(path))),
          ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // The dashboard's recommendation card reads the catalog.
        ChangeNotifierProvider(create: (_) => emptyCatalog()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<PetInfoProvider> withBruno() async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    await pets.addPet(bruno());
    return pets;
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('trend', () {
    test('a first assessment has nothing to compare against', () {
      expect(scoreTrend([report(78)]), isNull);
      expect(scoreTrend([]), isNull);
    });

    test('reads newest against previous, not the other way round', () {
      // History is newest first. Reversed, an improvement would read as a
      // drop — the kind of sign error nobody notices until a user does.
      expect(scoreTrend([report(78), report(73)]), 5);
      expect(scoreTrend([report(70), report(73)]), -3);
      expect(scoreTrend([report(73), report(73)]), 0);
    });

    test('only the two most recent reports count', () {
      expect(scoreTrend([report(80), report(75), report(10)]), 5);
    });

    test('labels read as movement, and zero is not dressed up', () {
      expect(trendLabel(5), 'Improved by 5%');
      expect(trendLabel(-3), 'Dropped by 3%');
      expect(trendLabel(0), 'No change');
    });

    test('the arrow follows the direction', () {
      expect(trendIcon(5), Icons.arrow_upward_rounded);
      expect(trendIcon(-3), Icons.arrow_downward_rounded);
      expect(trendIcon(0), Icons.remove_rounded);
    });
  });

  group('relative dates', () {
    final now = DateTime(2026, 8, 7, 14);
    String ago(int days) =>
        relativeDay(now.subtract(Duration(days: days)), now: now);

    test('the first week is exact', () {
      expect(ago(0), 'today');
      expect(ago(1), 'yesterday');
      expect(ago(2), '2 days ago');
      expect(ago(6), '6 days ago');
    });

    test('then it coarsens', () {
      expect(ago(9), 'last week');
      expect(ago(21), '3 weeks ago');
      expect(ago(45), 'last month');
      expect(ago(120), '4 months ago');
      expect(ago(500), 'over a year ago');
    });

    test('a clock-skewed future date reads as today, not negative days', () {
      // Records sync from other handsets whose clocks disagree. "in -1 days"
      // is a worse answer than a day of imprecision.
      expect(relativeDay(now.add(const Duration(days: 3)), now: now), 'today');
    });

    test('a time later the same day is still today', () {
      expect(relativeDay(DateTime(2026, 8, 7, 23), now: now), 'today');
    });
  });

  group('the card', () {
    testWidgets('shows score, band and how long ago', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([report(78, daysAgo: 2)]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      // The ring is one rich-text run, so the figure and its suffix match
      // together rather than as two widgets.
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      // Cadence moved to the reminder banner in feature 5, so the hero and
      // the banner no longer say the same thing.
      expect(find.text('Last assessment 2 days ago'), findsOneWidget);
    });

    testWidgets('shows the trend once there is a previous report',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([report(78), report(73, daysAgo: 40)]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      expect(find.text('Improved by 5%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('a first assessment shows no trend chip', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([report(78)]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Improved'), findsNothing);
      expect(find.textContaining('No change'), findsNothing);
    });

    testWidgets('a drop is reported plainly', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([report(64), report(71, daysAgo: 30)]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      expect(find.text('Dropped by 7%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('never assessed keeps the invitation, with no trend',
        (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(
        host(QuizProvider(service: FakeCloud()), await withBruno()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not assessed yet'), findsOneWidget);
      expect(find.text('Take the 45-question assessment'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('switching pets', () {
    testWidgets('the card follows the active pet', (tester) async {
      sizeUp(tester);

      final pets = PetInfoProvider(service: FakeCloud());
      await pets.init();
      await pets.addPet(bruno());
      await pets.addPet(
        bruno().copyWith(id: 'p2', name: 'Mia'),
      );

      final quiz = await quizWith([
        report(78),
        report(73, daysAgo: 30),
        report(40, petId: 'p2'),
      ]);
      pets.setActivePet(0);

      await tester.pumpWidget(host(quiz, pets));
      await tester.pumpAndSettle();
      expect(find.text('78%'), findsOneWidget);

      // The dashboard reads whichever pet is bound; main.dart wires the bind
      // to the active pet, so this test drives it the same way.
      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      expect(find.text('40%'), findsOneWidget);
      expect(find.text('78%'), findsNothing);
      // Mia has one report, so no trend follows her across.
      expect(find.textContaining('Improved'), findsNothing);
    });
  });

  test('the questionnaire still defines every scored category', () {
    // Guards the assumption the card leans on: a report's categoryScores
    // keys come from healthCategories, which feature 3 will read directly.
    expect(healthCategories.where((c) => c.maxScore > 0), isNotEmpty);
  });
}
