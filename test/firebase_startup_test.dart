import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/firebase_startup_provider.dart';
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/screens/startup/firebase_unavailable_screen.dart';

/// Sprint 4, P1-3 — a Firebase that never came up must not be pretended away.
///
/// `main()` used to wrap `Firebase.initializeApp` in a try/catch whose only
/// response was a `debugPrint` behind `kDebugMode`. In release the failure
/// was invisible and the app launched regardless, into a state where every
/// account operation throws `[core/no-app]` from deep inside a provider — a
/// raw platform exception in a snackbar for a signed-out user, and a stalled
/// restore for a returning one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the connection state', () {
    test('starts as connecting, before anything can be claimed', () {
      final firebase = FirebaseStartupProvider(initialise: () async {});

      // Not "failed": no attempt has been made, and an error screen at that
      // point would be an error the app has no grounds for.
      expect(firebase.status, FirebaseStatus.connecting);
      expect(firebase.hasFailed, isFalse);
      expect(firebase.isReady, isFalse);
    });

    test('a successful initialisation reports ready', () async {
      var attempts = 0;
      final firebase = FirebaseStartupProvider(
        initialise: () async => attempts++,
      );

      await firebase.connect();

      expect(attempts, 1);
      expect(firebase.status, FirebaseStatus.ready);
      expect(firebase.error, isNull);
    });

    test('a failure is recorded rather than swallowed', () async {
      final firebase = FirebaseStartupProvider(
        initialise: () async => throw Exception('no network'),
      );

      await firebase.connect();

      // The old implementation reached exactly this point and said nothing.
      expect(
        firebase.hasFailed,
        isTrue,
        reason: 'the app carried on as though Firebase were available',
      );
      expect(firebase.error, isNotNull);
    });

    test('notifies so the tree can react to either outcome', () async {
      var notifications = 0;
      final firebase = FirebaseStartupProvider(
        initialise: () async => throw Exception('no network'),
      )..addListener(() => notifications++);

      await firebase.connect();

      expect(notifications, greaterThan(0));
    });
  });

  group('retrying', () {
    test('actually re-runs the initialisation', () async {
      var attempts = 0;
      final firebase = FirebaseStartupProvider(initialise: () async {
        attempts++;
        throw Exception('no network');
      });

      await firebase.connect();
      await firebase.connect();

      expect(attempts, 2, reason: 'the retry did not retry anything');
    });

    test('a retry that works recovers the app', () async {
      var attempts = 0;
      final firebase = FirebaseStartupProvider(initialise: () async {
        attempts++;
        if (attempts == 1) throw Exception('no network');
      });

      await firebase.connect();
      expect(firebase.hasFailed, isTrue);

      await firebase.connect();

      expect(firebase.isReady, isTrue);
      expect(firebase.error, isNull);
      expect(firebase.status, FirebaseStatus.ready);
    });

    test('clears the previous error while trying again', () async {
      var attempts = 0;
      final states = <FirebaseStatus>[];
      late final FirebaseStartupProvider firebase;

      firebase = FirebaseStartupProvider(initialise: () async {
        attempts++;
        if (attempts == 1) throw Exception('no network');
      })..addListener(() => states.add(firebase.status));

      await firebase.connect();
      await firebase.connect();

      // The second attempt passes back through connecting rather than
      // leaving an error on screen while it works.
      expect(states, [
        FirebaseStatus.failed,
        FirebaseStatus.connecting,
        FirebaseStatus.ready,
      ]);
    });
  });

  group('initialisation happens once', () {
    test('a second call once ready does nothing', () async {
      var attempts = 0;
      final firebase = FirebaseStartupProvider(
        initialise: () async => attempts++,
      );

      await firebase.connect();
      await firebase.connect();
      await firebase.connect();

      // Firebase throws `duplicate-app` on a second initializeApp, so a
      // retry that fired anyway would turn a recovered app into a broken one.
      expect(attempts, 1);
    });

    test('concurrent calls collapse into one attempt', () async {
      var attempts = 0;
      final gate = Completer<void>();

      final firebase = FirebaseStartupProvider(initialise: () async {
        attempts++;
        await gate.future;
      });

      final first = firebase.connect();
      final second = firebase.connect();

      gate.complete();
      await Future.wait([first, second]);

      expect(attempts, 1);
      expect(firebase.isReady, isTrue);
    });
  });

  group('the failure screen', () {
    Widget host(
      Widget child, {
      double textScale = 1,
      Brightness brightness = Brightness.light,
    }) =>
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme:
                brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
            home: child,
            builder: (context, inner) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: inner!,
            ),
          ),
        );

    void sizeAt(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('says what happened without leaking the exception',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        FirebaseUnavailableScreen(onRetry: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text("MyPetFit can't connect"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      // A platform exception tells a user nothing and can carry project
      // identifiers.
      expect(find.textContaining('core/no-app'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('firebase'), findsNothing);
    });

    testWidgets('the retry control is operable by a screen reader',
        (tester) async {
      sizeAt(tester, const Size(400, 900));
      final handle = tester.ensureSemantics();
      var retries = 0;

      await tester.pumpWidget(host(
        FirebaseUnavailableScreen(onRetry: () => retries++),
      ));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.bySemanticsLabel('Try again'));
      final data = node.getSemanticsData();

      expect(data.flagsCollection.isButton, isTrue);
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'a recovery control a screen reader cannot press',
      );

      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();

      expect(retries, 1, reason: 'the action fired but reached nothing');

      handle.dispose();
    });

    testWidgets('a retry in flight cannot be pressed again', (tester) async {
      sizeAt(tester, const Size(400, 900));
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(host(
        FirebaseUnavailableScreen(onRetry: () {}, retrying: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Trying…'), findsOneWidget);

      final data =
          tester.getSemantics(find.bySemanticsLabel('Trying…')).getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);

      handle.dispose();
    });

    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 640),
        'large android': Size(412, 915),
        'tablet': Size(834, 1112),
        'landscape': Size(915, 412),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          sizeAt(tester, entry.value);

          await tester.pumpWidget(host(
            FirebaseUnavailableScreen(onRetry: () {}),
            textScale: scale,
          ));
          await tester.pumpAndSettle();

          expect(find.text("MyPetFit can't connect"), findsOneWidget);
          expect(find.text('Try again'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('renders in dark mode', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        FirebaseUnavailableScreen(onRetry: () {}),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text("MyPetFit can't connect"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
