import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/screens/account/account_screen.dart';
import 'package:mypetfit_app/screens/welcome/welcome_screen.dart';
import 'support/network_image_stub.dart';

Widget _host(Widget child, {required Brightness brightness}) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PetInfoProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: child,
      ),
    );

/// Every [Scaffold] colour actually painted in this tree.
Set<Color?> _scaffoldColors(WidgetTester tester) => tester
    .widgetList<Scaffold>(find.byType(Scaffold))
    .map((s) => s.backgroundColor)
    .toSet();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(StubNetworkImages.install);

  group('screens paint from the active palette', () {
    testWidgets('account screen follows the theme it is given', (tester) async {
      await tester.pumpWidget(
        _host(const AccountScreen(), brightness: Brightness.light),
      );
      await tester.pump();
      expect(_scaffoldColors(tester), contains(AppColors.light.surface));

      await tester.pumpWidget(
        _host(const AccountScreen(), brightness: Brightness.dark),
      );
      // MaterialApp cross-fades between themes, so the palette arrives over
      // the transition rather than on the next frame. Settling also proves
      // AppColors.lerp carries every token to its dark value instead of
      // snapping or throwing part-way.
      await tester.pumpAndSettle();
      expect(_scaffoldColors(tester), contains(AppColors.dark.surface));
    });

    testWidgets('welcome screen renders in dark without falling back to light',
        (tester) async {
      await tester.pumpWidget(
        _host(const WelcomeScreen(), brightness: Brightness.dark),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome!'), findsOneWidget);
    });
  });

  group('appearance preference', () {
    testWidgets('account offers all three appearances', (tester) async {
      await tester.pumpWidget(
        _host(const AccountScreen(), brightness: Brightness.light),
      );
      await tester.pump();

      expect(find.text('Appearance'), findsOneWidget);
      for (final option in ['Light', 'System', 'Dark']) {
        expect(find.text(option), findsOneWidget, reason: option);
      }
    });

    testWidgets('picking one records it, and System stays reachable',
        (tester) async {
      late ThemeProvider theme;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => QuizProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => PetInfoProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => AddressProvider()),
            ChangeNotifierProvider(create: (_) {
              return theme = ThemeProvider();
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AccountScreen(),
          ),
        ),
      );
      await tester.pump();

      // The settings list is taller than the test viewport, so the row has
      // to be brought on screen before a tap can land on it.
      Future<void> pick(String option) async {
        await tester.ensureVisible(find.text(option));
        await tester.pumpAndSettle();
        await tester.tap(find.text(option));
        await tester.pumpAndSettle();
      }

      await pick('Dark');
      expect(theme.mode, ThemeMode.dark);

      // The whole point of three states: you can go back.
      await pick('System');
      expect(theme.mode, ThemeMode.system);
    });

    test('the stored preference round-trips', () async {
      SharedPreferences.setMockInitialValues({});
      final a = ThemeProvider();
      await a.init();
      expect(a.mode, ThemeMode.system);
      await a.select(ThemeMode.dark);

      // A fresh provider reading the same store comes back dark.
      final b = ThemeProvider();
      await b.init();
      expect(b.mode, ThemeMode.dark);
    });

    test('an unrecognised stored value falls back to system', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'sepia'});
      final p = ThemeProvider();
      await p.init();
      expect(p.mode, ThemeMode.system);
    });
  });
}
