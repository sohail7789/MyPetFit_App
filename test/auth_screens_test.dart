import 'dart:io';

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

    // A source-level guard rather than a widget test, for the same reason
    // `test/analytics/architecture_test.dart` uses one: the thing worth
    // pinning down is that a particular call does not exist anywhere, and no
    // amount of pumping a widget can prove absence.
    //
    // Forgot Password used to pre-check the address with a Firestore query
    // against the `users` collection root. Signed out, that query cannot be
    // scoped to a caller, so allowing it means allowing any anonymous client
    // to enumerate every registered email — and it is the single operation
    // that blocks the production rules from being tightened to owner-only.
    //
    // Re-adding it would pass every other test in this suite and fail only
    // in production, on the day the rules are deployed.
    test('the reset flow performs no Firestore lookup', () {
      final offenders = <String>[];

      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          // Comments explaining why the call is gone are not the call.
          final trimmed = lines[i].trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
          if (trimmed.contains('isEmailRegistered')) {
            offenders.add('${file.path}:${i + 1}: $trimmed');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'isEmailRegistered() was removed because it let a signed-out '
            'caller enumerate the users collection. Firebase Auth already '
            'decides whether an address can be sent a reset link — ask it '
            'through sendPasswordResetEmail rather than reading '
            'Firestore.\n${offenders.join('\n')}',
      );
    });

    test('the Forgot Password screen does not reach Firestore at all', () {
      final source =
          File('lib/screens/auth/forgot_password_screen.dart').readAsStringSync();

      expect(
        source.contains('cloud_firestore'),
        isFalse,
        reason: 'Forgot Password must not query Firestore.',
      );
      expect(
        source.contains('collection('),
        isFalse,
        reason: 'Forgot Password must not query Firestore.',
      );
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
