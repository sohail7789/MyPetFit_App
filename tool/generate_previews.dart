import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/auth/sign_in_screen.dart';
import 'package:mypetfit_app/screens/pet_info/owner_info_screen.dart';
import 'package:mypetfit_app/screens/shop/shop_screen.dart';

/// Renders key screens to PNG so the layout can be eyeballed without a device.
///
/// Lives outside `test/` on purpose: it writes files rather than asserting, so
/// it is a reviewing tool, not a gate, and a bare `flutter test` should not
/// pick it up. Run it explicitly:
///
///     flutter test tool/generate_previews.dart --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // This runs under `flutter test`, but the analyzer only recognises files
    // under test/ as such — hence the ignore rather than a real misuse.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    // Widget tests ship a placeholder face by default; load the real one so
    // the previews show the app's actual typography.
    final loader = FontLoader(AppTheme.fontFamily)
      ..addFont(
        File('assets/fonts/Manrope.ttf')
            .readAsBytes()
            .then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
      );
    await loader.load();
  });

  const phone = Size(411, 914);

  Widget host(Widget child, double scale) {
    final pets = PetInfoProvider()
      ..setOwnerInfo(
        const OwnerInfo(
          name: 'Sohail Inamdar',
          contactNumber: '+91 90000 11111',
          email: 'sohail@example.com',
        ),
      );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: MediaQueryData(
            size: phone,
            textScaler: TextScaler.linear(scale),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget screen,
    double scale,
  ) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(screen, scale));

    // Asset images decode asynchronously, and widget tests run with a fake
    // async zone that never lets that finish — so a plain pump captures
    // whatever happened to be ready and silently omits the rest. That is not
    // a harmless cosmetic gap: it renders as artwork *missing* from the
    // preview, which reads exactly like an asset regression. Force every
    // image to load before the shot.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        // Bundled artwork only. Product photos are Image.network, and under
        // runAsync those make a real request that the test binding answers
        // with a 400 — the app already falls back to its paw motif for that,
        // which is what the preview should show anyway.
        if (image.image is! AssetImage && image.image is! ExactAssetImage) {
          continue;
        }
        await precacheImage(image.image, element);
      }
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('previews/$name.png'),
    );
  }

  testWidgets('sign in at 1.0', (t) async {
    await capture(t, 'sign-in-1.0', const SignInScreen(), 1);
  });

  testWidgets('sign in at 1.3', (t) async {
    await capture(t, 'sign-in-1.3', const SignInScreen(), 1.3);
  });

  testWidgets('owner details at 1.0', (t) async {
    await capture(t, 'owner-1.0', const OwnerInfoScreen(), 1);
  });

  testWidgets('owner details at 1.3', (t) async {
    await capture(t, 'owner-1.3', const OwnerInfoScreen(), 1.3);
  });

  testWidgets('shop at 1.0', (t) async {
    await capture(t, 'shop-1.0', const ShopScreen(), 1);
  });

  testWidgets('shop at 1.3', (t) async {
    await capture(t, 'shop-1.3', const ShopScreen(), 1.3);
  });
}
