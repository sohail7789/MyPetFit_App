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
import 'package:mypetfit_app/widgets/settings_tile.dart';
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
    testWidgets('account carries a dark-appearance toggle', (tester) async {
      await tester.pumpWidget(
        _host(const AccountScreen(), brightness: Brightness.light),
      );
      await tester.pump();

      expect(find.text('Dark appearance'), findsOneWidget);
      // Starts out tracking the device rather than a choice made here.
      expect(find.text('Following your device setting'), findsOneWidget);
    });

    testWidgets('the toggle reflects the painted appearance, not the mode',
        (tester) async {
      // On `system` the switch still has to show what is actually on screen,
      // otherwise flipping it appears to do nothing.
      await tester.pumpWidget(
        _host(const AccountScreen(), brightness: Brightness.dark),
      );
      await tester.pump();

      expect(
        tester.widget<AppSwitch>(find.byType(AppSwitch)).value,
        isTrue,
      );
    });

    testWidgets('flipping it pins the appearance for the app',
        (tester) async {
      await tester.pumpWidget(
        _host(const AccountScreen(), brightness: Brightness.light),
      );
      await tester.pump();

      await tester.tap(find.text('Dark appearance'));
      await tester.pumpAndSettle();

      expect(find.text('Set for this app'), findsOneWidget);
    });

    test('setDark pins the mode either way', () async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.init();
      expect(p.isFollowingSystem, isTrue);

      await p.setDark(true);
      expect(p.mode, ThemeMode.dark);
      expect(p.isFollowingSystem, isFalse);

      await p.setDark(false);
      expect(p.mode, ThemeMode.light);
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
