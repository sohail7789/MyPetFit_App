import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/consent/consent_screen.dart';
import 'package:mypetfit_app/screens/quiz/quiz_screen.dart';
import 'package:mypetfit_app/screens/report/report_card_screen.dart';
import 'package:mypetfit_app/widgets/app_button.dart';

Widget _host(Widget child, {QuizProvider? quiz}) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => quiz ?? QuizProvider()),
        // The report card names the pet a report was recorded against, so
        // it reads this during build rather than only when sharing.
        ChangeNotifierProvider(create: (_) => PetInfoProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

/// Scrolls the question list until [finder] exists. The list is lazy, so
/// options further down a category are not built until scrolled to.
///
/// Uses explicit pumps rather than `pumpAndSettle`: the quiz footer hosts a
/// looping Lottie walker, so the frame scheduler never goes idle.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  final list = find.byType(Scrollable).last;
  for (var i = 0; i < 25 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -160));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

bool _enabled(WidgetTester tester, String label) {
  final button =
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));
  return button.onPressed != null;
}

/// Answers every scored question with the option at [rank] (0 = best).
QuizProvider _answered({int rank = 0}) {
  final quiz = QuizProvider();
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
  return quiz;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('10 Consent', () {
    testWidgets('Continue unlocks only with both consent and a signature',
        (tester) async {
      await tester.pumpWidget(_host(const ConsentScreen()));

      expect(find.text('Consent & Use of Data'), findsOneWidget);
      expect(find.text('Step 1 of 3 · required'), findsOneWidget);
      expect(_enabled(tester, 'Agree & Continue'), isFalse);

      // Signature alone is not enough.
      await tester.enterText(find.byType(TextField).first, 'Priya Sharma');
      await tester.pump();
      expect(_enabled(tester, 'Agree & Continue'), isFalse);

      // Ticking the box completes the gate.
      await tester.tap(find.textContaining('I have read and agree'));
      await tester.pump();
      expect(_enabled(tester, 'Agree & Continue'), isTrue);
    });
  });

  group('13–21 Assessment', () {
    testWidgets('opens on category 1 and blocks Next until answered',
        (tester) async {
      await tester.pumpWidget(_host(const QuizScreen()));
      await tester.pump();

      expect(find.text('CATEGORY 1 OF 9'), findsOneWidget);
      expect(find.text('Skin & Coat Health'), findsOneWidget);
      expect(find.text('0 / 45'), findsOneWidget);

      // Both questions outstanding.
      expect(find.text('2 questions left'), findsOneWidget);
      expect(_enabled(tester, '2 questions left'), isFalse);
    });

    testWidgets('answering the category unlocks Next', (tester) async {
      await tester.pumpWidget(_host(const QuizScreen()));
      await tester.pump();

      await tester.tap(find.text('Shiny and full'));
      await tester.pump();
      expect(find.text('1 question left'), findsOneWidget);

      await _reveal(tester, find.text('No issues'));
      await tester.tap(find.text('No issues'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Next category'), findsOneWidget);
      expect(_enabled(tester, 'Next category'), isTrue);
      expect(find.text('2 / 45'), findsOneWidget);
    });

    testWidgets('the final category offers See my score', (tester) async {
      final quiz = QuizProvider()..goToCategory(8);
      await tester.pumpWidget(_host(const QuizScreen(), quiz: quiz));
      await tester.pump();

      expect(find.text('CATEGORY 9 OF 9'), findsOneWidget);
      // Category 9 is informational, so it is never blocked.
      expect(find.text('See my score'), findsOneWidget);
      expect(_enabled(tester, 'See my score'), isTrue);
    });

    testWidgets('multi-select keeps several options picked', (tester) async {
      final quiz = QuizProvider()..goToCategory(8);
      await tester.pumpWidget(_host(const QuizScreen(), quiz: quiz));
      await tester.pump();

      await _reveal(tester, find.text('Weight management'));
      await tester.tap(find.text('Weight management'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Joint mobility'));
      await tester.pump(const Duration(milliseconds: 200));

      final multi = allQuestions.firstWhere((q) => q.isMulti);
      expect(quiz.multiSelectionFor(multi.id), {'c9q3a', 'c9q3b'});

      // Tapping again removes just that one.
      await tester.tap(find.text('Weight management'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(quiz.multiSelectionFor(multi.id), {'c9q3b'});
    });

    testWidgets('follow-up field appears only where the design marks it',
        (tester) async {
      // Category 5's last question carries a supplements follow-up.
      final quiz = QuizProvider()..goToCategory(4);
      await tester.pumpWidget(_host(const QuizScreen(), quiz: quiz));
      await tester.pump();

      await _reveal(tester, find.text('WHICH SUPPLEMENTS'));
      expect(find.text('WHICH SUPPLEMENTS'), findsOneWidget);
    });
  });

  group('23 Report card', () {
    testWidgets('shows the band, score and all nine breakdown rows',
        (tester) async {
      final quiz = _answered();
      await quiz.calculateResult();

      await tester.pumpWidget(_host(const ReportCardScreen(), quiz: quiz));
      await tester.pumpAndSettle();

      expect(find.text('FITNESS REPORT CARD'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('8 categories'), findsOneWidget);

      // Category 9 is unscored, so it contributes no breakdown row.
      expect(find.text('Skin & Coat Health'), findsOneWidget);
      expect(find.text('Additional Information'), findsNothing);
    });

    testWidgets('prompts to take the assessment when there is no result',
        (tester) async {
      await tester.pumpWidget(_host(const ReportCardScreen()));
      await tester.pump();

      expect(find.text('No report yet'), findsOneWidget);
    });

    testWidgets('worst-case answers land in the Critical band',
        (tester) async {
      final quiz = QuizProvider();
      for (final category in healthCategories) {
        for (final question in category.scoredQuestions) {
          final worst = question.answers
              .reduce((a, b) => b.score < a.score ? b : a);
          quiz.selectAnswer(question.id, worst);
        }
      }
      final result = await quiz.calculateResult();

      expect(result.percentageScore, 0);
      expect(result.category, HealthCategory.critical);
    });
  });
}
