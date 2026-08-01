import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/legal_content.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/account_screen.dart';
import 'package:mypetfit_app/screens/account/delete_account_screen.dart';
import 'package:mypetfit_app/screens/account/legal_screen.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';
import 'package:mypetfit_app/widgets/app_button.dart';
import 'support/network_image_stub.dart';

Widget _host(Widget child, {QuizProvider? quiz}) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => quiz ?? QuizProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PetInfoProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

bool _enabled(WidgetTester tester, String label) {
  final button =
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));
  return button.onPressed != null;
}

/// Answers everything with the best option and records a result.
QuizProvider _scored() {
  final quiz = QuizProvider();
  for (final category in healthCategories) {
    for (final question in category.scoredQuestions) {
      quiz.selectAnswer(
        question.id,
        question.answers.reduce((a, b) => b.score > a.score ? b : a),
      );
    }
  }
  quiz.calculateResult();
  return quiz;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('30 Home dashboard', () {
    testWidgets('prompts for an assessment when there is no score',
        (tester) async {
      await tester.pumpWidget(_host(const HomeDashboardScreen()));
      await tester.pump();

      expect(find.text('FITNESS SCORE'), findsOneWidget);
      expect(find.text('Not assessed yet'), findsOneWidget);
      expect(find.text('Start the assessment'), findsOneWidget);
      // No score yet, so the ring shows a dash rather than a number.
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('shows the score and report CTA once assessed',
        (tester) async {
      await tester.pumpWidget(
        _host(const HomeDashboardScreen(), quiz: _scored()),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('View report card'), findsOneWidget);
      expect(find.text("This week's focus"), findsOneWidget);
    });

    testWidgets('offers to resume a part-finished assessment',
        (tester) async {
      final quiz = QuizProvider();
      final first = healthCategories.first.questions.first;
      quiz.selectAnswer(first.id, first.answers.first);

      await tester.pumpWidget(_host(const HomeDashboardScreen(), quiz: quiz));
      await tester.pump();

      expect(find.text('Continue assessment'), findsOneWidget);
      expect(find.text('1 of 45 answered'), findsOneWidget);
    });

    testWidgets('hides the resume card when nothing is started',
        (tester) async {
      await tester.pumpWidget(_host(const HomeDashboardScreen()));
      await tester.pump();

      expect(find.text('Continue assessment'), findsNothing);
    });
  });

  group('31 Account', () {
    testWidgets('lists the settings and legal groups', (tester) async {
      await tester.pumpWidget(_host(const AccountScreen()));
      await tester.pump();

      expect(find.text('My pets'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Reminders & notifications'), findsOneWidget);
      expect(find.text('LEGAL & DATA'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);

      // The list is taller than the test viewport.
      await tester.scrollUntilVisible(
        find.text('Log out'),
        140,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Log out'), findsOneWidget);
    });
  });

  group('34/35 Legal', () {
    testWidgets('renders every Terms clause', (tester) async {
      await tester.pumpWidget(_host(const LegalScreen.terms()));
      await tester.pump();

      expect(termsOfService.length, 8);
      expect(find.text('1. Acceptance of terms'), findsOneWidget);
      expect(
        find.textContaining('is not a veterinary service'),
        findsOneWidget,
      );
    });

    testWidgets('renders the Privacy policy', (tester) async {
      await tester.pumpWidget(_host(const LegalScreen.privacy()));
      await tester.pump();

      expect(privacyPolicy.length, 8);
      expect(find.text('1. What we collect'), findsOneWidget);
    });
  });

  group('36 Delete account', () {
    testWidgets('stays locked until DELETE is typed exactly', (tester) async {
      await tester.pumpWidget(_host(const DeleteAccountScreen()));
      await tester.pump();

      expect(_enabled(tester, 'Delete my account'), isFalse);

      await tester.enterText(find.byType(TextField), 'delete me');
      await tester.pump();
      expect(_enabled(tester, 'Delete my account'), isFalse);

      // Case-insensitive, matching the design.
      await tester.enterText(find.byType(TextField), 'delete');
      await tester.pump();
      expect(_enabled(tester, 'Delete my account'), isTrue);
    });
  });

  group('32 Report history', () {
    testWidgets('shows an empty state before any assessment', (tester) async {
      await tester.pumpWidget(_host(const ReportHistoryScreen()));
      await tester.pump();

      expect(find.text('No reports yet'), findsOneWidget);
    });

    testWidgets('lists a completed report and marks it current',
        (tester) async {
      await tester.pumpWidget(
        _host(const ReportHistoryScreen(), quiz: _scored()),
      );
      await tester.pump();

      expect(find.text('100'), findsOneWidget);
      expect(find.textContaining('current'), findsOneWidget);
      // A trend needs two assessments to compare.
      expect(find.text('YOUR TREND'), findsNothing);
    });

    testWidgets('shows the trend once there are two assessments',
        (tester) async {
      final quiz = _scored();
      // A second, weaker assessment becomes the newest entry.
      quiz.reset();
      for (final category in healthCategories) {
        for (final question in category.scoredQuestions) {
          quiz.selectAnswer(
            question.id,
            question.answers.reduce((a, b) => b.score < a.score ? b : a),
          );
        }
      }
      quiz.calculateResult();

      await tester.pumpWidget(_host(const ReportHistoryScreen(), quiz: quiz));
      await tester.pump();

      expect(find.text('YOUR TREND'), findsOneWidget);
      expect(find.text('-100'), findsOneWidget);
    });
  });
}
