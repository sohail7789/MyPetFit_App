import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/app_startup_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';
import 'package:mypetfit_app/screens/report/report_card_screen.dart';

/// Answers every scored question with the option at [rank] (0 = best) and
/// records a result.
QuizProvider _scored({int rank = 0, QuizProvider? into}) {
  final quiz = into ?? QuizProvider();
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
  return quiz;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('starting a retake', () {
    test('keeps the last result so an abandoned retake loses nothing', () {
      final quiz = _scored();
      final before = quiz.result;
      expect(before, isNotNull);
      expect(quiz.assessmentHistory, hasLength(1));

      // Tapping "Retake" clears the in-progress answers...
      quiz.reset();

      // ...but the score already earned has to survive, because the user may
      // never finish the retake. This is the reported bug: the dashboard fell
      // back to "Not assessed yet" the moment a retake began.
      expect(quiz.result, isNotNull);
      expect(quiz.result!.percentageScore, before!.percentageScore);
      expect(quiz.assessmentHistory, hasLength(1));
      expect(quiz.hasCompletedAssessment, isTrue);
    });

    test('clears the in-progress answers', () {
      final quiz = _scored();
      expect(quiz.answeredCount, greaterThan(0));

      quiz.reset();
      expect(quiz.answeredCount, 0);
    });

    test('completing a retake replaces the result and grows history', () {
      final quiz = _scored();
      final first = quiz.result!.percentageScore;

      quiz.reset();
      _scored(rank: 99, into: quiz); // worst option everywhere

      expect(quiz.assessmentHistory, hasLength(2));
      // Newest first.
      expect(quiz.assessmentHistory.first.percentageScore, quiz.result!.percentageScore);
      expect(quiz.assessmentHistory[1].percentageScore, first);
      expect(quiz.result!.percentageScore, lessThan(first));
    });

    test('signing out still wipes everything', () async {
      final quiz = _scored();
      await quiz.resetAll();

      expect(quiz.result, isNull);
      expect(quiz.assessmentHistory, isEmpty);
    });
  });

  group('report history', () {
    Widget host(QuizProvider quiz) {
      final router = GoRouter(
        initialLocation: '/report-history',
        routes: [
          GoRoute(
            path: '/report-history',
            builder: (context, state) => const ReportHistoryScreen(),
          ),
          GoRoute(
            path: '/report/history/:index',
            builder: (context, state) => ReportCardScreen(
              historyIndex:
                  int.tryParse(state.pathParameters['index'] ?? '') ?? -1,
            ),
          ),
        ],
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: quiz),
          ChangeNotifierProvider(create: (_) => PetInfoProvider()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      );
    }

    testWidgets('opens an older entry, not just the newest', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final quiz = _scored();
      final oldScore = quiz.result!.percentageScore;
      quiz.reset();
      _scored(rank: 99, into: quiz);
      final newScore = quiz.result!.percentageScore;
      expect(newScore, isNot(oldScore));

      await tester.pumpWidget(host(quiz));
      await tester.pump();

      // Two rows, both with a chevron — the design gives every row one.
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNWidgets(2));

      // Tap the *older* row, which previously had no handler at all.
      await tester.tap(find.text('$oldScore'));
      await tester.pumpAndSettle();

      // The archived score is shown, not the current one.
      expect(find.text('$oldScore'), findsWidgets);
      expect(find.text('All reports'), findsOneWidget);
      // "Retake" belongs to the live report, not an archived record.
      expect(find.text('Retake'), findsNothing);
    });

    testWidgets('a stale index degrades instead of crashing', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => QuizProvider()),
            ChangeNotifierProvider(create: (_) => AppStartupProvider()),
            ChangeNotifierProvider(create: (_) => PetInfoProvider()),
          ],
          child: const MaterialApp(
            home: ReportCardScreen(historyIndex: 7),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No report yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
