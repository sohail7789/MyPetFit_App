import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/screens/auth/forgot_password_screen.dart';
import 'package:mypetfit_app/widgets/password_strength.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: child,
    );

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

  // Design screens 08 (verify code) and 09 (create new password) once had
  // suites here. Both screens have been removed: they implemented a custom
  // reset flow that never existed behind them — the code screen accepted any
  // six characters, and "Save new password" changed no password — while the
  // app resets through Firebase Auth's emailed link. Their tests went with
  // them rather than being kept passing against deleted code.
  //
  // The password strength meter outlived them: it is still on sign-up, and
  // screen 09 happened to be the only place it was covered. That coverage is
  // kept here, against the widget itself.
  group('password strength meter', () {
    testWidgets('reaches Strong for a varied password', (tester) async {
      await tester.pumpWidget(_host(PasswordStrength.of('sup3rSecret!')));

      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('rates a short single-case password below Strong',
        (tester) async {
      await tester.pumpWidget(_host(PasswordStrength.of('abcdef')));

      expect(find.text('Strong'), findsNothing);
    });
  });
}
