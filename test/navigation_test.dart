import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/consent/consent_screen.dart';
import 'support/network_image_stub.dart';

/// Hosts [child] on a router whose only other route is a stand-in "home", so
/// a screen can be entered either by `push` (with a stack) or by `go`
/// (replacing it) and the back button checked in both cases.
Widget _router({
  required Widget child,
  required String childPath,
  required bool withStack,
}) {
  final router = GoRouter(
    initialLocation: withStack ? AppRoutes.home : childPath,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push(childPath),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(path: childPath, builder: (context, state) => child),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => QuizProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => PetInfoProvider()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('10 Consent back button', () {
    testWidgets('has a back button at all', (tester) async {
      await tester.pumpWidget(
        _router(
          child: const ConsentScreen(),
          childPath: AppRoutes.consent,
          withStack: false,
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Back'), findsOneWidget);
    });

    testWidgets('pops when it was pushed onto a stack', (tester) async {
      await tester.pumpWidget(
        _router(
          child: const ConsentScreen(),
          childPath: AppRoutes.consent,
          withStack: true,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Consent & Use of Data'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('falls back to home when it replaced the stack',
        (tester) async {
      // How sign-up reaches consent: `go`, so there is nothing to pop to.
      await tester.pumpWidget(
        _router(
          child: const ConsentScreen(),
          childPath: AppRoutes.consent,
          withStack: false,
        ),
      );
      await tester.pump();

      expect(find.text('Consent & Use of Data'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      // Previously a dead button; now it lands on home.
      expect(find.text('open'), findsOneWidget);
    });
  });
}
