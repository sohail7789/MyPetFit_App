import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';

import 'support/product_fixtures.dart';

/// Report history can be opened for a pet that is not the active one. The
/// quiz scores whichever pet is *active*, so starting an assessment from a
/// second pet's history used to file the result against the first pet — the
/// wrong animal's health record, written silently.
///
/// These tests assert the association end-to-end: they start the assessment
/// the way the screen does, complete it, and read back which pet the stored
/// result names.

PetInfo _pet(String id, String name) => PetInfo(
      id: id,
      name: name,
      breed: 'Beagle',
      ageYears: 3,
      ageMonths: 0,
      gender: PetGender.male,
      weightKg: 12,
      heightCm: 40,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

/// Answers every scored question and records a result against whichever pet
/// is currently bound.
void _assess(QuizProvider quiz, {int rank = 0}) {
  for (final category in healthCategories) {
    for (final question in category.scoredQuestions) {
      final ranked = [...question.answers]
        ..sort((a, b) => b.score.compareTo(a.score));
      quiz.selectAnswer(question.id, ranked[rank.clamp(0, ranked.length - 1)]);
    }
  }
  quiz.calculateResult();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('starting an assessment from a pet\'s report history', () {
    /// Builds the screen with the same pets-drive-the-quiz wiring `main`
    /// installs, so the binding under test is the production one rather than
    /// something the test arranges for itself.
    Future<Widget> host({
      required QuizProvider quiz,
      required PetInfoProvider pets,
      required int petIndex,
      ProductProvider? catalog,
    }) async {
      void bindActivePet() => quiz.bindPet(pets.activePet?.id);
      pets.addListener(bindActivePet);
      bindActivePet();

      final router = GoRouter(
        initialLocation: '/report-history',
        routes: [
          GoRoute(
            path: '/report-history',
            builder: (context, state) =>
                ReportHistoryScreen(petIndex: petIndex),
          ),
          // The quiz itself is not exercised here; the push only has to
          // succeed so the handler runs to completion.
          GoRoute(
            path: '/quiz',
            builder: (context, state) => const Scaffold(body: Text('quiz')),
          ),
        ],
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: quiz),
          ChangeNotifierProvider.value(value: pets),
          ChangeNotifierProvider(create: (_) => catalog ?? emptyCatalog()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
    }

    /// Two pets, with [activeIndex] selected — the situation that produces
    /// the bug when the history being viewed belongs to the other one.
    Future<(QuizProvider, PetInfoProvider)> twoPets({
      int activeIndex = 0,
    }) async {
      final quiz = QuizProvider();
      await quiz.init();

      final pets = PetInfoProvider();
      await pets.addPet(_pet('pet_a', 'Bruno'));
      await pets.addPet(_pet('pet_b', 'Nala'));
      pets.setActivePet(activeIndex);

      return (quiz, pets);
    }

    testWidgets(
      'an empty history starts the assessment for the pet being viewed',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // Pet A is active; we are looking at Pet B's (empty) history.
        final (quiz, pets) = await twoPets(activeIndex: 0);
        expect(pets.activePet!.id, 'pet_a');

        await tester.pumpWidget(await host(quiz: quiz, pets: pets, petIndex: 1));
        await tester.pump();

        await tester.tap(find.text('Start the assessment'));
        await tester.pumpAndSettle();

        // The subject follows the history that was open, not the previous
        // selection. This is the regression.
        expect(pets.activePet!.id, 'pet_b');

        // And the result actually lands on Pet B.
        _assess(quiz);
        expect(quiz.result!.petId, 'pet_b');
        expect(quiz.historyFor('pet_b'), hasLength(1));
        expect(quiz.historyFor('pet_a'), isEmpty);
      },
    );

    testWidgets(
      'the active pet\'s own history still starts for that pet',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // The converse of the case above: selecting the viewed pet must not
        // have moved the selection somewhere else.
        final (quiz, pets) = await twoPets(activeIndex: 0);

        await tester.pumpWidget(await host(quiz: quiz, pets: pets, petIndex: 0));
        await tester.pump();

        await tester.tap(find.text('Start the assessment'));
        await tester.pumpAndSettle();

        expect(pets.activePet!.id, 'pet_a');

        _assess(quiz);
        expect(quiz.result!.petId, 'pet_a');
        expect(quiz.historyFor('pet_b'), isEmpty);
      },
    );

    testWidgets(
      'a retake from a second pet\'s history is filed against that pet',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // The other entry point: one assessment on file, so the screen shows
        // "Take another assessment" rather than the empty state.
        final (quiz, pets) = await twoPets(activeIndex: 1);

        // Seed Pet B's single report. The pets-drive-the-quiz listener is
        // installed by `host` below, so the subject is bound directly here —
        // this is arranging prior state, not the behaviour under test.
        quiz.bindPet('pet_b');
        _assess(quiz);
        expect(quiz.historyFor('pet_b'), hasLength(1));

        // Now switch the active pet away, exactly as using the app would.
        pets.setActivePet(0);
        expect(pets.activePet!.id, 'pet_a');

        await tester.pumpWidget(await host(quiz: quiz, pets: pets, petIndex: 1));
        await tester.pump();

        await tester.tap(find.text('Take another assessment'));
        await tester.pumpAndSettle();

        expect(pets.activePet!.id, 'pet_b');

        _assess(quiz, rank: 99);
        expect(quiz.result!.petId, 'pet_b');
        // The retake joins Pet B's record and leaves Pet A with none.
        expect(quiz.historyFor('pet_b'), hasLength(2));
        expect(quiz.historyFor('pet_a'), isEmpty);
      },
    );
  });
}
