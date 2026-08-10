import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';
import 'support/product_fixtures.dart';

/// Sprint 1, feature 5 — quick actions, the assessment reminder, and the
/// loading and empty states across the whole screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ScoreResult report({int daysAgo = 0}) => ScoreResult(
        rawScore: 70,
        maxPossibleScore: 100,
        percentageScore: 70,
        category: HealthCategory.good,
        categoryScores: const {'Skin & Coat Health': 41},
        completedAt: DateTime.now().subtract(Duration(days: daysAgo)),
        petId: 'p1',
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

  Future<QuizProvider> quizWith(List<ScoreResult> reports) async {
    final quiz = QuizProvider(
      service: FakeCloud(assessments: reports.isEmpty ? {} : {'p1': reports}),
    );
    await quiz.init();
    await quiz.loadAssessmentsFromFirestore();
    quiz.bindPet('p1');
    return quiz;
  }

  Future<PetInfoProvider> withPets(List<PetInfo> list) async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    for (final p in list) {
      await pets.addPet(p);
    }
    return pets;
  }

  Widget host({
    required QuizProvider quiz,
    required PetInfoProvider pets,
    ProductProvider? products,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomeDashboardScreen(),
        ),
        for (final path in [
          AppRoutes.quiz,
          AppRoutes.reportHistory,
          AppRoutes.pets,
          AppRoutes.shop,
          AppRoutes.petInfo,
          AppRoutes.report,
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
        ChangeNotifierProvider.value(value: products ?? emptyCatalog()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('quick actions', () {
    testWidgets('all four are offered', (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([report()]),
        pets: await withPets([bruno()]),
      ));
      await tester.pumpAndSettle();

      for (final label in ['Assessment', 'Reports', 'My pets', 'Shop']) {
        expect(find.text(label), findsOneWidget, reason: '$label is missing');
      }
    });

    testWidgets('each carries its full action for a screen reader',
        (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([report()]),
        pets: await withPets([bruno()]),
      ));
      await tester.pumpAndSettle();

      // The visible labels are shortened to fit four across; the spoken
      // labels are not.
      for (final label in [
        'Start assessment',
        'View reports',
        'My pets',
        'Shop products',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
    });

    for (final (label, destination) in [
      ('Assessment', AppRoutes.quiz),
      ('Reports', AppRoutes.reportHistory),
      ('My pets', AppRoutes.pets),
      ('Shop', AppRoutes.shop),
    ]) {
      testWidgets('$label opens $destination', (tester) async {
        sizeUp(tester);
        await tester.pumpWidget(host(
          quiz: await quizWith([report()]),
          pets: await withPets([bruno()]),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text(destination), findsOneWidget);
      });
    }

    testWidgets('starting an assessment clears the draft first',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([report()]);
      final first = quiz.categories.first.questions.first;
      quiz.selectAnswer(first.id, first.answers.first);
      expect(quiz.answeredCount, greaterThan(0));

      await tester.pumpWidget(host(quiz: quiz, pets: await withPets([bruno()])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assessment'));
      await tester.pumpAndSettle();

      expect(quiz.answeredCount, 0);
      // The earned score survives an abandoned retake.
      expect(quiz.result, isNotNull);
    });
  });

  group('assessment reminder', () {
    final now = DateTime(2026, 8, 7, 14);
    ScoreResult at(int daysAgo) => ScoreResult(
          rawScore: 70,
          maxPossibleScore: 100,
          percentageScore: 70,
          category: HealthCategory.good,
          completedAt: now.subtract(Duration(days: daysAgo)),
          petId: 'p1',
        );

    test('nothing assessed gets no banner', () {
      // The hero already carries that invitation; a banner repeating it
      // under the card that just said it is noise.
      expect(assessmentReminder(null, now: now), isNull);
    });

    test('assessed today', () {
      final reminder = assessmentReminder(at(0), now: now);
      expect(reminder?.label, 'Assessment completed today');
      expect(reminder?.isDue, isFalse);
    });

    test('the boundary is the calendar date, not a twenty-four hour window',
        () {
      // 11:30 PM yesterday, read at 10:00 AM today: ten and a half hours
      // ago, and still yesterday. Counting elapsed hours would call this
      // "today" for most of the morning, which is the one case where a
      // relative date is worth getting exactly right — someone checking
      // whether they have already assessed their pet *today*.
      final morning = DateTime(2026, 8, 10, 10);
      final lastNight = DateTime(2026, 8, 9, 23, 30);

      ScoreResult reportAt(DateTime when) => ScoreResult(
            rawScore: 70,
            maxPossibleScore: 100,
            percentageScore: 70,
            category: HealthCategory.good,
            completedAt: when,
            petId: 'p1',
          );

      expect(
        assessmentReminder(reportAt(lastNight), now: morning)?.label,
        'Last assessment yesterday',
      );

      // And one minute later, on the same calendar day, it is today.
      expect(
        assessmentReminder(
          reportAt(DateTime(2026, 8, 10, 0, 1)),
          now: morning,
        )?.label,
        'Assessment completed today',
      );
    });

    test('recent reports how long ago', () {
      expect(
        assessmentReminder(at(12), now: now)?.label,
        'Last assessment last week',
      );
      expect(assessmentReminder(at(2), now: now)?.label,
          'Last assessment 2 days ago');
    });

    test('ninety days is due, eighty-nine is not', () {
      expect(assessmentReminder(at(89), now: now)?.isDue, isFalse);
      expect(assessmentReminder(at(90), now: now)?.isDue, isTrue);
      expect(assessmentReminder(at(90), now: now)?.label, 'Assessment due');
      expect(assessmentReminder(at(400), now: now)?.isDue, isTrue);
    });

    testWidgets('a due banner offers the retake and takes it', (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([report(daysAgo: 120)]),
        pets: await withPets([bruno()]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Assessment due'), findsOneWidget);

      await tester.tap(find.text('Retake'));
      await tester.pumpAndSettle();
      expect(find.text(AppRoutes.quiz), findsOneWidget);
    });

    testWidgets('a recent banner is not a button', (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([report(daysAgo: 2)]),
        pets: await withPets([bruno()]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Last assessment 2 days ago'), findsOneWidget);
      expect(find.text('Retake'), findsNothing);
    });

    testWidgets('the hero no longer repeats the date', (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([report(daysAgo: 2)]),
        pets: await withPets([bruno()]),
      ));
      await tester.pumpAndSettle();

      // Cadence belongs to the banner; the hero keeps the score.
      expect(find.text('Assessed 2 days ago'), findsNothing);
      expect(find.text('70%'), findsOneWidget);
    });
  });

  group('loading states', () {
    testWidgets('the pet strip waits rather than offering to add a pet',
        (tester) async {
      sizeUp(tester);
      // A provider that has not read prefs yet, exactly as main.dart leaves
      // it for the first frames.
      final pets = PetInfoProvider(service: FakeCloud());
      expect(pets.isLoaded, isFalse);

      await tester.pumpWidget(host(quiz: await quizWith([]), pets: pets));
      await tester.pump();

      expect(find.bySemanticsLabel('Loading your pets'), findsOneWidget);
      expect(find.text('Add your first pet'), findsNothing);

      await pets.init();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Loading your pets'), findsNothing);
      expect(find.text('Add your first pet'), findsOneWidget);
    });

    testWidgets('a restored pet is never covered by a skeleton',
        (tester) async {
      sizeUp(tester);
      final pets = await withPets([bruno()]);

      await tester.pumpWidget(host(quiz: await quizWith([]), pets: pets));
      await tester.pump();

      expect(find.text('Bruno'), findsOneWidget);
      expect(find.bySemanticsLabel('Loading your pets'), findsNothing);
    });

    testWidgets('the catalog loading does not blank the rest of the screen',
        (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([report()]),
        pets: await withPets([bruno()]),
        products: pendingCatalog(),
      ));
      await tester.pump();

      expect(find.bySemanticsLabel('Loading recommendations'), findsOneWidget);
      // Everything not waiting on the catalog still renders.
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Category breakdown'), findsOneWidget);
      expect(find.text('Assessment'), findsOneWidget);
    });
  });

  group('empty states', () {
    testWidgets('a fresh account says each thing once', (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([]),
        pets: await withPets([bruno()]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Not assessed yet'), findsOneWidget);
      expect(find.text('What the assessment covers'), findsOneWidget);
      expect(
        find.text(
          'Complete an assessment to receive personalized recommendations.',
        ),
        findsOneWidget,
      );

      // One call to action for starting an assessment in the cards, plus the
      // quick action. The recommendation card used to add a third.
      expect(find.text('Start the assessment'), findsOneWidget);
      expect(find.text('Start Assessment'), findsNothing);
    });

    testWidgets('no reminder banner before the first assessment',
        (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([]),
        pets: await withPets([bruno()]),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last assessment'), findsNothing);
      expect(find.text('Assessment due'), findsNothing);
      expect(find.text('Assessment completed today'), findsNothing);
    });

    testWidgets('every section still renders with no pet at all',
        (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(
        quiz: await quizWith([]),
        pets: await withPets([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add your first pet'), findsOneWidget);
      expect(find.text('Recommended for you'), findsNothing);
      expect(find.text('What the assessment covers'), findsOneWidget);
      // Quick actions stay available — they are navigation, not data.
      expect(find.text('Shop'), findsOneWidget);
    });
  });
}
