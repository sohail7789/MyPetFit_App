import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/screens/auth/forgot_password_screen.dart';
import 'package:mypetfit_app/widgets/app_button.dart';

/// Records reset requests instead of reaching Firebase.
///
/// [gate] holds the request open so the in-flight window can be observed;
/// left null, the call completes immediately.
class _FakeAuth extends AuthProvider {
  _FakeAuth({this.gate, this.error});

  final Completer<void>? gate;
  final Object? error;

  final sent = <String>[];

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sent.add(email);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }
}

Widget _host(AuthProvider auth) {
  final router = GoRouter(
    initialLocation: AppRoutes.forgotPassword,
    routes: [
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const Scaffold(body: Text('Sign in')),
      ),
    ],
  );

  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

final _sendButton = find.ancestor(
  of: find.textContaining('Send Reset Link'),
  matching: find.byType(AppButton),
);

Future<void> _tapSend(WidgetTester tester) async {
  await tester.ensureVisible(_sendButton);
  await tester.pump();
  await tester.tap(_sendButton, warnIfMissed: false);
}

/// The send control, whichever label it is currently wearing.
bool _sendEnabled(WidgetTester tester) {
  final button = tester.widget<AppButton>(find.byType(AppButton).first);
  return button.onPressed != null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('forgot password', () {
    testWidgets('an empty address is refused without asking Firebase',
        (tester) async {
      final auth = _FakeAuth();
      await tester.pumpWidget(_host(auth));

      await _tapSend(tester);
      await tester.pump();

      expect(auth.sent, isEmpty);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    });

    testWidgets('a malformed address is refused without asking Firebase',
        (tester) async {
      // Previously only emptiness was checked, so this reached Firebase and
      // came back as a generic failure.
      final auth = _FakeAuth();
      await tester.pumpWidget(_host(auth));

      await tester.enterText(find.byType(TextField).first, 'bruno@@nowhere');
      await _tapSend(tester);
      await tester.pump();

      expect(auth.sent, isEmpty);
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('a successful send lands on sign-in without an artificial wait',
        (tester) async {
      final auth = _FakeAuth();
      await tester.pumpWidget(_host(auth));

      await tester.enterText(find.byType(TextField).first, ' bruno@pets.test ');
      await _tapSend(tester);

      // Let the request resolve and the route change — and nothing more. The
      // screen used to sleep three seconds after the request had already
      // returned, so this bounded pump is the regression: settling within it
      // is only possible with the sleep gone.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Sign in'), findsOneWidget);
      // The address is trimmed before it is sent.
      expect(auth.sent, ['bruno@pets.test']);
      // The confirmation rides the ScaffoldMessenger across the navigation.
      expect(
        find.text('Password reset email sent. Please check your inbox.'),
        findsOneWidget,
      );
    });

    testWidgets('a double tap sends exactly one email', (tester) async {
      final gate = Completer<void>();
      final auth = _FakeAuth(gate: gate);
      await tester.pumpWidget(_host(auth));

      await tester.enterText(find.byType(TextField).first, 'bruno@pets.test');

      await _tapSend(tester);
      await tester.pump();

      // While the first request is open the control is disabled, so the
      // second tap cannot start another one.
      expect(_sendEnabled(tester), isFalse);
      expect(find.text('Sending…'), findsOneWidget);

      await tester.tap(find.byType(AppButton).first, warnIfMissed: false);
      await tester.pump();

      expect(auth.sent, hasLength(1));

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Sign in'), findsOneWidget);
      expect(auth.sent, hasLength(1));
    });

    testWidgets('a failure stays put, explains, and allows a retry',
        (tester) async {
      final auth = _FakeAuth(
        error: Exception('No account found with this email.'),
      );
      await tester.pumpWidget(_host(auth));

      await tester.enterText(find.byType(TextField).first, 'nobody@pets.test');
      await _tapSend(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Still on the form, with the reason — and the "Exception: " prefix
      // stripped rather than shown to the user.
      expect(find.text('Sign in'), findsNothing);
      expect(find.text('No account found with this email.'), findsOneWidget);

      // The guard is released so a corrected address can be sent.
      expect(_sendEnabled(tester), isTrue);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });
  });
}
