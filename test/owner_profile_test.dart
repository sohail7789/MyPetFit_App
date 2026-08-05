import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/address.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/screens/account/owner_profile_screen.dart';
import 'package:mypetfit_app/screens/pet_info/owner_info_screen.dart';
import 'package:mypetfit_app/widgets/app_button.dart';
import 'support/network_image_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const owner = OwnerInfo(
    name: 'Sohail Inamdar',
    contactNumber: '+91 90000 11111',
    email: 'owner@example.com',
  );

  Widget host(
    Widget child, {
    required PetInfoProvider pets,
    AddressProvider? address,
    AuthProvider? auth,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => child),
        GoRoute(
          path: '/elsewhere',
          builder: (context, state) =>
              const Scaffold(body: Text('elsewhere')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider.value(value: address ?? AddressProvider()),
        ChangeNotifierProvider.value(value: auth ?? AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('owner profile', () {
    testWidgets('shows the saved contact details', (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider()..setOwnerInfo(owner);

      await tester.pumpWidget(host(const OwnerProfileScreen(), pets: pets));
      await tester.pump();

      expect(find.text('Sohail Inamdar'), findsWidgets);
      expect(find.text('+91 90000 11111'), findsOneWidget);
      expect(find.text('owner@example.com'), findsOneWidget);
      // Edit moved into the header, matching the design.
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('marks missing details rather than showing blanks',
        (tester) async {
      useTallSurface(tester);

      await tester.pumpWidget(
        host(const OwnerProfileScreen(), pets: PetInfoProvider()),
      );
      await tester.pump();

      // Full name, contact, email, vet name and vet contact are all unset;
      // Language always resolves, so it is never "Not set".
      expect(find.text('Not set'), findsNWidgets(5));
      expect(find.text('English'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('surfaces the saved delivery address', (tester) async {
      useTallSurface(tester);
      final address = AddressProvider();
      await address.save(
        const Address(
          id: 'a1',
          fullName: 'Sohail',
          phone: '9000011111',
          line1: '12B, MG Road',
          city: 'Pune',
          state: 'Maharashtra',
          pincode: '411001',
        ),
      );

      await tester.pumpWidget(
        host(
          const OwnerProfileScreen(),
          pets: PetInfoProvider()..setOwnerInfo(owner),
          address: address,
        ),
      );
      await tester.pump();

      expect(find.text('Delivery address'), findsOneWidget);
      expect(find.textContaining('Pune'), findsWidgets);
    });

    testWidgets('does not repeat the sign-in email when it matches',
        (tester) async {
      useTallSurface(tester);

      await tester.pumpWidget(
        host(
          const OwnerProfileScreen(),
          pets: PetInfoProvider()..setOwnerInfo(owner),
        ),
      );
      await tester.pump();

      // No auth email set, so the read-only row stays hidden.
      expect(find.text('Sign-in email'), findsNothing);
    });
  });

  group('edit owner profile', () {
    testWidgets('prefills, saves, and keeps the delivery address',
        (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider()
        ..setOwnerInfo(owner.copyWith(address: '12B, MG Road, Pune'));

      await tester.pumpWidget(
        host(
          const OwnerInfoScreen(mode: OwnerFormMode.edit),
          pets: pets,
        ),
      );
      await tester.pump();

      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Sohail Inamdar'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'S. Inamdar');
      await tester.tap(find.widgetWithText(AppButton, 'Save changes'));
      await tester.pump();
      await tester.pump();

      expect(pets.ownerInfo!.name, 'S. Inamdar');
      // The address is not on this form; editing must not drop it.
      expect(pets.ownerInfo!.address, '12B, MG Road, Pune');
      expect(pets.ownerInfo!.email, 'owner@example.com');
    });

    testWidgets('rejects an obviously broken email', (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider()..setOwnerInfo(owner);

      await tester.pumpWidget(
        host(const OwnerInfoScreen(mode: OwnerFormMode.edit), pets: pets),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(2), 'not-an-email');
      await tester.tap(find.widgetWithText(AppButton, 'Save changes'));
      await tester.pump();

      expect(find.text('That email address looks wrong.'), findsOneWidget);
      expect(pets.ownerInfo!.email, 'owner@example.com');
    });

    testWidgets('edits the vet, which the design puts on the owner',
        (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider()..setOwnerInfo(owner);

      await tester.pumpWidget(
        host(const OwnerInfoScreen(mode: OwnerFormMode.edit), pets: pets),
      );
      await tester.pump();

      expect(find.textContaining('VETERINARIAN NAME'), findsOneWidget);
      expect(find.textContaining('VET CONTACT'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(3), 'Dr Rao');
      await tester.enterText(find.byType(TextField).at(4), '+91 90000 00000');
      await tester.tap(find.widgetWithText(AppButton, 'Save changes'));
      await tester.pump();
      await tester.pump();

      // Stored against the owner, not a pet — one practice covers the
      // household, so per-pet copies would have to be edited twice.
      expect(pets.ownerInfo!.vetName, 'Dr Rao');
      expect(pets.ownerInfo!.vetContact, '+91 90000 00000');
    });

    testWidgets('the assessment step is unchanged', (tester) async {
      useTallSurface(tester);

      await tester.pumpWidget(
        host(const OwnerInfoScreen(), pets: PetInfoProvider()),
      );
      await tester.pump();

      expect(find.text('Owner details'), findsOneWidget);
      expect(
        find.text('Step 2 of 3 · so your report can reach you.'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.textContaining('VETERINARIAN NAME'), findsOneWidget);
    });
  });
}
