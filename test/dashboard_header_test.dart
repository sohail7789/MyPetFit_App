import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';
import 'support/product_fixtures.dart';

/// Sprint 1, feature 1 — the header is real provider data.
///
/// It showed the account's first name, which [AuthProvider.signIn] leaves
/// empty for an email sign-in, so those users were greeted by their
/// username. Breed, age and the pet's photo were not on the screen at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PetInfo pet(
    String id, {
    required String name,
    String breed = 'Beagle',
    int years = 3,
    int months = 2,
  }) =>
      PetInfo(
        id: id,
        name: name,
        breed: breed,
        ageYears: years,
        ageMonths: months,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  Widget host(PetInfoProvider pets, {AuthProvider? auth}) {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomeDashboardScreen(),
        ),
        for (final path in [
          AppRoutes.petInfo,
          AppRoutes.quiz,
          AppRoutes.report,
          AppRoutes.shop,
          AppRoutes.account,
          AppRoutes.inbox,
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Center(child: Text(path))),
          ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider.value(value: auth ?? AuthProvider()),
        // The dashboard's recommendation card reads the catalog.
        ChangeNotifierProvider(create: (_) => emptyCatalog()),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(service: FakeCloud()),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<PetInfoProvider> account({
    String? ownerName,
    List<PetInfo> withPets = const [],
  }) async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    if (ownerName != null) {
      await pets.setOwnerInfo(
        OwnerInfo(
          name: ownerName,
          contactNumber: '9000000000',
          email: 'sohail@example.com',
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      );
    }
    for (final p in withPets) {
      await pets.addPet(p);
    }
    return pets;
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('owner name', () {
    testWidgets('comes from the owner record, not the account', (tester) async {
      sizeUp(tester);
      // Exactly the email sign-in shape: signed in, but no name on the
      // credential. This is what showed the username instead.
      final auth = AuthProvider();
      final pets = await account(ownerName: 'Sohail Inamdar');

      await tester.pumpWidget(host(pets, auth: auth));
      await tester.pumpAndSettle();

      expect(find.text('Sohail'), findsOneWidget);
    });

    testWidgets('falls back to a friendly greeting with nothing on file',
        (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(await account()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('pet identity', () {
    testWidgets('shows the active pet with breed and age', (tester) async {
      sizeUp(tester);
      final pets = await account(
        ownerName: 'Sohail',
        withPets: [pet('p1', name: 'Bruno')],
      );

      await tester.pumpWidget(host(pets));
      await tester.pumpAndSettle();

      expect(find.text('Bruno'), findsOneWidget);
      // Over two years, so the months are dropped — see petAgeLabel.
      expect(find.text('Beagle · 3 years'), findsOneWidget);
    });

    testWidgets('a younger pet keeps its months', (tester) async {
      sizeUp(tester);
      final pets = await account(
        ownerName: 'Sohail',
        withPets: [pet('p1', name: 'Mia', breed: 'Corgi', years: 1, months: 5)],
      );

      await tester.pumpWidget(host(pets));
      await tester.pumpAndSettle();

      expect(find.text('Corgi · 1 yr 5 mo'), findsOneWidget);
    });

    testWidgets('offers to add one when there are no pets', (tester) async {
      sizeUp(tester);
      await tester.pumpWidget(host(await account(ownerName: 'Sohail')));
      await tester.pumpAndSettle();

      expect(find.text('Add your first pet'), findsOneWidget);

      await tester.tap(find.text('Add your first pet'));
      await tester.pumpAndSettle();
      expect(find.text(AppRoutes.petInfo), findsOneWidget);
    });

    testWidgets('no switcher affordance for a single pet', (tester) async {
      sizeUp(tester);
      final pets = await account(
        ownerName: 'Sohail',
        withPets: [pet('p1', name: 'Bruno')],
      );

      await tester.pumpWidget(host(pets));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.unfold_more_rounded), findsNothing);
    });
  });

  group('switching pets', () {
    testWidgets('the header follows the selection', (tester) async {
      sizeUp(tester);
      final pets = await account(
        ownerName: 'Sohail',
        withPets: [
          pet('p1', name: 'Bruno'),
          pet('p2', name: 'Mia', breed: 'Corgi', years: 1, months: 0),
        ],
      );
      // addPet makes the newest pet active.
      pets.setActivePet(0);

      await tester.pumpWidget(host(pets));
      await tester.pumpAndSettle();

      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('2 pets'), findsOneWidget);

      await tester.tap(find.text('Bruno'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mia').last);
      await tester.pumpAndSettle();

      // The provider is the record of the choice, and the strip reflects it.
      expect(pets.activePetIndex, 1);
      expect(find.text('Mia'), findsOneWidget);
      expect(find.text('Corgi · 1 year'), findsOneWidget);
      expect(find.text('Bruno'), findsNothing);
    });
  });

  group('age and breed formatting', () {
    test('months only, below a year', () {
      expect(petAgeLabel(pet('p', name: 'x', years: 0, months: 7)), '7 months');
      expect(petAgeLabel(pet('p', name: 'x', years: 0, months: 1)), '1 month');
    });

    test('years and months while the months still matter', () {
      expect(petAgeLabel(pet('p', name: 'x', years: 2, months: 4)), '2 yr 4 mo');
    });

    test('months are dropped once precision stops helping', () {
      expect(petAgeLabel(pet('p', name: 'x', years: 5, months: 4)), '5 years');
      expect(petAgeLabel(pet('p', name: 'x', years: 1, months: 0)), '1 year');
    });

    test('no age recorded reads as none, not as zero', () {
      expect(petAgeLabel(pet('p', name: 'x', years: 0, months: 0)), isNull);
    });

    test('a half-filled pet never renders a dangling separator', () {
      expect(
        petSubtitle(pet('p', name: 'x', breed: '', years: 3, months: 0)),
        '3 years',
      );
      expect(
        petSubtitle(pet('p', name: 'x', years: 0, months: 0)),
        'Beagle',
      );
      expect(
        petSubtitle(pet('p', name: 'x', breed: '', years: 0, months: 0)),
        'Tap to add details',
      );
    });
  });
}
