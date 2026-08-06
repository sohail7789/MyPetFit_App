import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'support/product_fixtures.dart';
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/address_screen.dart';
import 'package:mypetfit_app/screens/auth/sign_in_screen.dart';
import 'package:mypetfit_app/screens/pet_info/owner_info_screen.dart';
import 'package:mypetfit_app/screens/pet_info/pet_info_screen.dart';
import 'package:mypetfit_app/screens/shop/checkout_screen.dart';
import 'package:mypetfit_app/screens/shop/shop_screen.dart';
import 'package:mypetfit_app/widgets/labeled_field.dart';

/// Regression cover for the layout breakage reported on a Samsung A52.
///
/// Android's Display size and Font size settings both feed `textScaler`, and
/// One UI ships several steps above 1.0. Every screen below used to pin its
/// fields and buttons to fixed heights, which sliced placeholder text in half
/// and ran labels into each other. These tests pump the affected screens at
/// the top of the range the app honours and fail on any overflow.
///
/// Two different assertions are needed, because the original bug was invisible
/// to the obvious one:
///
///  * `tester.takeException()` catches *layout* overflow, which throws in
///    debug. This is forward-looking cover — it caught a 3px overflow in the
///    product tile while the stepper was being added.
///  * The [LabeledField] cases below measure heights instead. A fixed-height
///    box whose contents don't fit doesn't overflow, it silently paints the
///    text clipped, which is why sliced placeholders shipped without a single
///    console warning. Measuring is the only thing that catches a regression
///    back to a pinned height.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The ceiling `MyPetFitApp` clamps to. Anything the app will actually
  /// render has to survive this.
  const maxScale = 1.3;

  /// A phone roughly the size of the reporter's A52 (1080x2400 at 2.625x).
  const phone = Size(411, 914);

  Widget host(Widget child, {double scale = maxScale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PetInfoProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => loadedTestCatalog()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
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

  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen, {
    double scale = maxScale,
  }) async {
    tester.view.physicalSize = phone * 2.625;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(screen, scale: scale));
    await tester.pump();
  }

  group('screens survive a 1.3 font scale', () {
    testWidgets('sign in', (tester) async {
      await pumpAt(tester, const SignInScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('owner details', (tester) async {
      await pumpAt(tester, const OwnerInfoScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('pet details', (tester) async {
      await pumpAt(tester, const PetInfoScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('delivery address', (tester) async {
      await pumpAt(tester, const AddressScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('checkout', (tester) async {
      await pumpAt(tester, const CheckoutScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('shop grid', (tester) async {
      await pumpAt(tester, const ShopScreen());
      expect(tester.takeException(), isNull);
    });
  });

  group('LabeledField', () {
    testWidgets('grows with the font scale instead of clipping its value',
        (tester) async {
      Future<double> heightAt(double scale) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
              ),
              child: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 320,
                    child: LabeledField(
                      label: 'Owner name',
                      hint: 'Full name',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return tester.getSize(find.byType(LabeledField)).height;
      }

      final resting = await heightAt(1);
      final scaled = await heightAt(maxScale);

      // The design's resting height is honoured as a floor...
      expect(resting, greaterThanOrEqualTo(58));
      // ...but the box grows rather than slicing the value row, which is
      // exactly what the fixed 20px value SizedBox used to do.
      expect(scaled, greaterThan(resting));
      expect(tester.takeException(), isNull);
    });

    testWidgets('gives the value row its full line height, uncropped',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(maxScale),
            ),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: LabeledField(
                    label: 'Contact number',
                    hint: '+91 00000 00000',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 15px at 1.3 scale with a 1.3 leading needs ~25px. The old build gave
      // the input a hardcoded 20px box, so the descenders were cut off — the
      // half-height placeholders in the bug report. Nothing throws when that
      // happens, so assert on the box the input actually got.
      final field = tester.getSize(find.byType(EditableText)).height;
      expect(field, greaterThan(15 * maxScale));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long placeholder ellipsizes rather than reflowing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(maxScale),
            ),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 150,
                  child: LabeledField(
                    label: 'Veterinarian name & contact',
                    labelNote: 'optional',
                    hint: 'Dr. name, phone number and clinic address',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('pet details at scale', () {
    testWidgets('every field label is still legible, not clipped',
        (tester) async {
      await pumpAt(tester, const PetInfoScreen());

      // The captions the reporter saw sliced in half.
      for (final label in ["PET'S NAME", 'BREED', 'AGE — YEARS']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('owner details keeps what was typed', () {
    testWidgets('reloads saved values when the step is re-entered',
        (tester) async {
      final pets = PetInfoProvider();
      pets.setOwnerInfo(
        OwnerInfo(
          name: 'Sohail',
          contactNumber: '+91 90000 11111',
          email: 'owner@example.com',
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: pets),
            ChangeNotifierProvider(create: (_) => QuizProvider()),
          ],
          child: const MaterialApp(home: OwnerInfoScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Sohail'), findsOneWidget);
      expect(find.text('owner@example.com'), findsOneWidget);
    });
  });
}
