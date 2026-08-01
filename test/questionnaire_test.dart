import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The provider writes progress to SharedPreferences on every answer.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('questionnaire shape', () {
    test('has 9 categories and 45 questions', () {
      expect(healthCategories.length, 9);
      expect(allQuestions.length, 45);
    });

    test('matches the design\'s per-category question counts', () {
      expect(
        healthCategories.map((c) => c.questions.length).toList(),
        [2, 6, 3, 6, 5, 6, 6, 6, 5],
      );
    });

    test('only category 9 is unscored', () {
      for (var i = 0; i < healthCategories.length; i++) {
        final scored = healthCategories[i].scoredQuestions.length;
        if (i == 8) {
          expect(scored, 0, reason: 'Additional Information is informational');
        } else {
          expect(scored, greaterThan(0), reason: 'category $i should score');
        }
      }
    });

    test('question and answer ids are unique', () {
      final questionIds = allQuestions.map((q) => q.id).toList();
      expect(questionIds.toSet().length, questionIds.length);

      final answerIds = [
        for (final q in allQuestions) ...q.answers.map((a) => a.id),
      ];
      expect(answerIds.toSet().length, answerIds.length);
    });

    test('exactly one multi-select question', () {
      final multi = allQuestions.where((q) => q.isMulti).toList();
      expect(multi.length, 1);
      expect(multi.single.id, 'c9q3');
      expect(multi.single.answers.length, 6);
    });

    test('follow-up fields sit on the six questions the design marks', () {
      expect(
        allQuestions.where((q) => q.hasFollowUp).map((q) => q.id).toList(),
        ['c5q5', 'c8q1', 'c8q2', 'c8q6', 'c9q4', 'c9q5'],
      );
    });
  });

  group('scoring', () {
    test('bounds are derived from the data', () {
      expect(assessmentMinScore, lessThan(assessmentMaxScore));
      // 40 scored questions across categories 1-8.
      expect(
        healthCategories.fold<int>(0, (n, c) => n + c.scoredQuestions.length),
        40,
      );
    });

    test('an untouched assessment scores 0%', () {
      // Unanswered questions count as their worst option, which is the floor.
      expect(QuizProvider().fitnessPercent, 0);
    });

    test('picking the best option everywhere scores 100%', () {
      final provider = QuizProvider();
      for (final category in healthCategories) {
        for (final question in category.scoredQuestions) {
          final best = question.answers
              .reduce((a, b) => b.score > a.score ? b : a);
          provider.selectAnswer(question.id, best);
        }
      }
      expect(provider.fitnessPercent, 100);
    });

    test('category percent is earned over max', () {
      final provider = QuizProvider();
      final skinCoat = healthCategories.first;
      // Best on both questions: 8 + 8 = 16 of a possible 16.
      for (final question in skinCoat.questions) {
        provider.selectAnswer(
          question.id,
          question.answers.reduce((a, b) => b.score > a.score ? b : a),
        );
      }
      expect(provider.categoryPercent(skinCoat), 100);
    });
  });

  group('progress', () {
    test('counts unscored and multi-select questions too', () {
      final provider = QuizProvider();
      expect(provider.answeredCount, 0);

      // An unscored single-select still counts as engagement.
      final unscored = allQuestions.firstWhere((q) => q.id == 'c9q1');
      provider.selectAnswer(unscored.id, unscored.answers.first);
      expect(provider.answeredCount, 1);

      // Multi-select counts once it has at least one pick, and drops back out.
      final multi = allQuestions.firstWhere((q) => q.isMulti);
      provider.toggleMultiAnswer(multi.id, multi.answers.first);
      expect(provider.answeredCount, 2);
      provider.toggleMultiAnswer(multi.id, multi.answers.first);
      expect(provider.answeredCount, 1);
    });

    test('a category is complete once its scored questions are answered', () {
      final provider = QuizProvider();
      expect(provider.isCategoryComplete(0), isFalse);
      expect(provider.remainingInCategory(0), 2);

      for (final question in healthCategories.first.questions) {
        provider.selectAnswer(question.id, question.answers.first);
      }
      expect(provider.isCategoryComplete(0), isTrue);
    });

    test('the informational category needs no answers to advance', () {
      expect(QuizProvider().isCategoryComplete(8), isTrue);
    });
  });
}
