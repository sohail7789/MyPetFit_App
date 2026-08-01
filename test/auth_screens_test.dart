import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/screens/auth/forgot_password_screen.dart';
import 'package:mypetfit_app/screens/auth/reset_password_screen.dart';
import 'package:mypetfit_app/screens/auth/verify_code_screen.dart';
import 'package:mypetfit_app/widgets/app_button.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: child,
    );

/// True when the button carrying [label] is enabled.
bool _enabled(WidgetTester tester, String label) {
  final button = tester.widget<AppButton>(
    find.widgetWithText(AppButton, label),
  );
  return button.onPressed != null;
}

void main() {
  group('07 Forgot password', () {
    testWidgets('renders the prompt, field and CTA', (tester) async {
      await tester.pumpWidget(_host(const ForgotPasswordScreen()));

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });
  });

  group('08 Verify code', () {
    testWidgets('renders six code boxes', (tester) async {
      await tester.pumpWidget(_host(const VerifyCodeScreen()));

      expect(find.text('Check your email'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('Verify stays disabled until all six digits are entered',
        (tester) async {
      await tester.pumpWidget(_host(const VerifyCodeScreen()));

      expect(_enabled(tester, 'Verify'), isFalse);

      final boxes = find.byType(TextField);
      for (var i = 0; i < 5; i++) {
        await tester.enterText(boxes.at(i), '${i + 1}');
        await tester.pump();
      }
      expect(_enabled(tester, 'Verify'), isFalse);

      await tester.enterText(boxes.at(5), '6');
      await tester.pump();
      expect(_enabled(tester, 'Verify'), isTrue);
    });

    testWidgets('counts the resend timer down', (tester) async {
      await tester.pumpWidget(_host(const VerifyCodeScreen()));

      expect(find.textContaining('00:42'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('00:41'), findsOneWidget);

      // Let the timer finish so the test ends with no pending work.
      await tester.pump(const Duration(seconds: 42));
    });
  });

  group('09 Reset password', () {
    testWidgets('Save stays disabled until both entries match',
        (tester) async {
      await tester.pumpWidget(_host(const ResetPasswordScreen()));

      expect(_enabled(tester, 'Save new password'), isFalse);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'sup3rsecret!');
      await tester.pump();
      expect(_enabled(tester, 'Save new password'), isFalse);

      await tester.enterText(fields.at(1), 'mismatch');
      await tester.pump();
      expect(_enabled(tester, 'Save new password'), isFalse);

      await tester.enterText(fields.at(1), 'sup3rsecret!');
      await tester.pump();
      expect(_enabled(tester, 'Save new password'), isTrue);
    });

    testWidgets('strength meter reaches Strong for a varied password',
        (tester) async {
      await tester.pumpWidget(_host(const ResetPasswordScreen()));

      await tester.enterText(find.byType(TextField).at(0), 'sup3rSecret!');
      await tester.pump();

      expect(find.text('Strong'), findsOneWidget);
    });
  });
}
