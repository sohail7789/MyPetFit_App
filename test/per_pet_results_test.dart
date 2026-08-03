import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';

/// Answers every scored question with the option at [rank] (0 = best) and
/// records a result against whichever pet is currently bound.
void assess(QuizProvider quiz, {int rank = 0}) {
  for (final category in healthCategories) {
    for (final question in category.scoredQuestions) {
      final ranked = [...question.answers]
        ..sort((a, b) => b.score.compareTo(a.score));
      quiz.selectAnswer(
        question.id,
        ranked[rank.clamp(0, ranked.length - 1)],
      );
    }
  }
  quiz.calculateResult();
  quiz.reset();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('results are scoped to a pet', () {
    test('each pet keeps its own score and history', () {
      final quiz = QuizProvider();

      quiz.bindPet('pet_a');
      assess(quiz, rank: 0); // best answers
      final scoreA = quiz.result!.percentageScore;

      quiz.bindPet('pet_b');
      // A pet that has never been assessed has no score, even though the
      // other one does. This is the bug: "Last assessed" showed the newest
      // assessment regardless of whose profile you were looking at.
      expect(quiz.result, isNull);
      expect(quiz.hasCompletedAssessment, isFalse);

      assess(quiz, rank: 99); // worst answers
      final scoreB = quiz.result!.percentageScore;

      expect(scoreB, lessThan(scoreA));
      expect(quiz.assessmentHistory, hasLength(1));

      quiz.bindPet('pet_a');
      expect(quiz.result!.percentageScore, scoreA);
      expect(quiz.assessmentHistory, hasLength(1));
    });

    test('a result records which pet it belongs to', () {
      final quiz = QuizProvider()..bindPet('pet_a');
      assess(quiz);
      expect(quiz.result!.petId, 'pet_a');
    });

    test('history is capped per pet, not across all of them', () {
      final quiz = QuizProvider();

      quiz.bindPet('pet_a');
      for (var i = 0; i < QuizProvider.maxHistory + 2; i++) {
        assess(quiz);
      }
      expect(quiz.assessmentHistory, hasLength(QuizProvider.maxHistory));

      // Assessing another pet must not evict the first pet's reports.
      quiz.bindPet('pet_b');
      assess(quiz);
      expect(quiz.assessmentHistory, hasLength(1));

      quiz.bindPet('pet_a');
      expect(quiz.assessmentHistory, hasLength(QuizProvider.maxHistory));
    });

    test('removing a pet takes its reports with it', () {
      final quiz = QuizProvider();

      quiz.bindPet('pet_a');
      assess(quiz);
      quiz.bindPet('pet_b');
      assess(quiz);

      quiz.clearResultsFor('pet_a');

      expect(quiz.assessmentHistory, hasLength(1)); // still on pet_b
      quiz.bindPet('pet_a');
      expect(quiz.result, isNull);
    });
  });

  group('upgrading from shared results', () {
    test('existing history is claimed by the pet bound first', () async {
      // Written by a build that had no notion of per-pet results.
      SharedPreferences.setMockInitialValues({
        'quiz_state': jsonEncode({
          'history': [
            {
              'rawScore': 120,
              'maxPossibleScore': 200,
              'percentageScore': 61,
              'category': 'good',
              'categoryScores': <String, double>{},
              'completedAt': '2026-07-28T10:00:00.000Z',
            },
          ],
        }),
      });

      final quiz = QuizProvider();
      await quiz.init();

      // Before binding, the record belongs to nobody in particular.
      expect(quiz.assessmentHistory, hasLength(1));

      quiz.bindPet('pet_a');

      // A single-pet user must not appear to have never been assessed.
      expect(quiz.result, isNotNull);
      expect(quiz.result!.percentageScore, 61);
      expect(quiz.result!.petId, 'pet_a');

      // And it is not also handed to every other pet.
      quiz.bindPet('pet_b');
      expect(quiz.result, isNull);
    });

    test('the claim happens once, not on every pet switch', () async {
      SharedPreferences.setMockInitialValues({
        'quiz_state': jsonEncode({
          'history': [
            {
              'rawScore': 120,
              'maxPossibleScore': 200,
              'percentageScore': 61,
              'category': 'good',
              'categoryScores': <String, double>{},
              'completedAt': '2026-07-28T10:00:00.000Z',
            },
          ],
        }),
      });

      final quiz = QuizProvider();
      await quiz.init();

      quiz.bindPet('pet_a');
      quiz.bindPet('pet_b');
      quiz.bindPet('pet_c');

      // Still only pet_a's.
      expect(quiz.result, isNull);
      quiz.bindPet('pet_a');
      expect(quiz.result, isNotNull);
    });
  });

  group('looking up another pet', () {
    test('reports a pet that is not the bound one', () {
      final quiz = QuizProvider();

      quiz.bindPet('pet_a');
      assess(quiz, rank: 0);
      final scoreA = quiz.result!.percentageScore;

      quiz.bindPet('pet_b');
      assess(quiz, rank: 99);

      // The pet profile can show a pet that isn't active, so it has to be
      // able to ask about one by id without switching the binding.
      expect(quiz.resultFor('pet_a')!.percentageScore, scoreA);
      expect(quiz.resultFor('pet_b')!.percentageScore, isNot(scoreA));
      expect(quiz.resultFor('pet_never_assessed'), isNull);
      expect(quiz.historyFor('pet_a'), hasLength(1));

      // And asking did not move the binding.
      expect(quiz.result!.petId, 'pet_b');
    });
  });

  group('persistence', () {
    test('survives a reload with its pet intact', () async {
      final quiz = QuizProvider()..bindPet('pet_a');
      assess(quiz);
      final score = quiz.result!.percentageScore;

      final reloaded = QuizProvider();
      await reloaded.init();
      reloaded.bindPet('pet_a');

      expect(reloaded.result, isNotNull);
      expect(reloaded.result!.percentageScore, score);
      expect(reloaded.result!.petId, 'pet_a');
    });

    test('signing out clears every pet', () async {
      final quiz = QuizProvider()..bindPet('pet_a');
      assess(quiz);

      await quiz.resetAll();

      quiz.bindPet('pet_a');
      expect(quiz.result, isNull);
      expect(quiz.assessmentHistory, isEmpty);
    });
  });
}
