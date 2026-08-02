import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/address_repository.dart';
import 'package:mypetfit_app/models/address.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/address_screen.dart';
import 'package:mypetfit_app/screens/account/pet_profile_screen.dart';
import 'package:mypetfit_app/screens/pet_info/pet_info_screen.dart';
import 'package:mypetfit_app/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// These screens navigate on save, so they need a real router in the tree —
  /// otherwise the save succeeds and the *navigation* throws, which reads
  /// like a product failure but isn't one. The stub route is where they land.
  Widget host(
    Widget child, {
    required PetInfoProvider pets,
    AddressProvider? address,
    QuizProvider? quiz,
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
        ChangeNotifierProvider.value(value: quiz ?? QuizProvider()),
        ChangeNotifierProvider.value(
          value: address ?? AddressProvider(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }

  /// A tall surface so the lazy ListViews on these screens build every row,
  /// including validation messages that would otherwise sit below the fold.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(AppButton, label));
    await tester.pump();
    await tester.pump();
  }

  group('add a pet', () {
    testWidgets('saves the pet instead of only starting the assessment',
        (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider();

      await tester.pumpWidget(
        host(
          const PetInfoScreen(mode: PetFormMode.add),
          pets: pets,
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Bruno');
      await tester.enterText(find.byType(TextField).at(1), 'Beagle');
      await tester.pump();

      expect(pets.pets, isEmpty);
      await tapButton(tester, 'Save pet');

      // The reported bug: the form navigated onward without ever adding the
      // pet, so My pets stayed on its empty state.
      expect(pets.pets, hasLength(1));
      expect(pets.pets.single.name, 'Bruno');
      expect(pets.pets.single.breed, 'Beagle');
    });

    testWidgets('refuses to save a pet with no name', (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider();

      await tester.pumpWidget(
        host(const PetInfoScreen(mode: PetFormMode.add), pets: pets),
      );
      await tester.pump();

      await tapButton(tester, 'Save pet');

      expect(pets.pets, isEmpty);
      expect(find.text("Please enter your pet's name."), findsOneWidget);
    });

    testWidgets('the add form offers Save, not the assessment',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(
        host(
          const PetInfoScreen(mode: PetFormMode.add),
          pets: PetInfoProvider(),
        ),
      );
      await tester.pump();

      expect(find.text('Save pet'), findsOneWidget);
      expect(find.text('Start the assessment'), findsNothing);
    });

    testWidgets('the onboarding step still leads into the assessment',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(
        host(const PetInfoScreen(), pets: PetInfoProvider()),
      );
      await tester.pump();

      expect(find.text('Start the assessment'), findsOneWidget);
      expect(find.text('Step 3 of 3 · this shapes the scoring.'),
          findsOneWidget);
    });
  });

  group('edit a pet', () {
    testWidgets('prefills from the saved record and updates in place',
        (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider();
      pets.addPet(
        const PetInfo(
          id: 'p1',
          name: 'Bruno',
          breed: 'Beagle',
          ageYears: 3,
          ageMonths: 2,
          gender: PetGender.male,
          weightKg: 12,
          heightCm: 40,
          vetName: 'Dr Rao',
        ),
      );

      await tester.pumpWidget(
        host(
          const PetInfoScreen(mode: PetFormMode.edit, petIndex: 0),
          pets: pets,
        ),
      );
      await tester.pump();

      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Beagle'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Bruno Jr');
      await tapButton(tester, 'Save changes');

      expect(pets.pets, hasLength(1));
      expect(pets.pets.single.name, 'Bruno Jr');
      // Fields this form doesn't collect must survive the round trip.
      expect(pets.pets.single.vetName, 'Dr Rao');
      expect(pets.pets.single.id, 'p1');
    });
  });

  group('pet profile', () {
    testWidgets('offers the assessment rather than forcing it', (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider();
      pets.addPet(
        const PetInfo(
          id: 'p1',
          name: 'Bruno',
          breed: 'Beagle',
          ageYears: 3,
          ageMonths: 0,
          gender: PetGender.male,
          weightKg: 12,
          heightCm: 40,
        ),
      );

      await tester.pumpWidget(
        host(const PetProfileScreen(petIndex: 0), pets: pets),
      );
      await tester.pump();

      expect(find.text('Bruno'), findsWidgets);
      expect(find.text('No assessment yet'), findsOneWidget);
      expect(find.text('Start the assessment'), findsOneWidget);
      expect(find.text('Edit details'), findsOneWidget);
    });

    testWidgets('degrades gracefully when the pet is gone', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(
        host(const PetProfileScreen(petIndex: 4), pets: PetInfoProvider()),
      );
      await tester.pump();

      expect(find.text('This pet is no longer in your list.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('delivery address', () {
    testWidgets('validates before saving', (tester) async {
      useTallSurface(tester);
      final address = AddressProvider();

      await tester.pumpWidget(
        host(
          const AddressScreen(),
          pets: PetInfoProvider(),
          address: address,
        ),
      );
      await tester.pump();

      await tapButton(tester, 'Save address');

      expect(address.hasAddress, isFalse);
      expect(find.text('Indian PIN codes are 6 digits.'), findsOneWidget);
      expect(find.text('City is required.'), findsOneWidget);
    });

    testWidgets('saves a complete address', (tester) async {
      useTallSurface(tester);
      final address = AddressProvider();

      await tester.pumpWidget(
        host(
          const AddressScreen(),
          pets: PetInfoProvider(),
          address: address,
        ),
      );
      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Sohail');
      await tester.enterText(fields.at(1), '9000011111');
      await tester.enterText(fields.at(2), '12B, MG Road');
      await tester.enterText(fields.at(5), 'Pune');
      await tester.enterText(fields.at(6), 'Maharashtra');
      await tester.enterText(fields.at(7), '411001');
      await tester.pump();

      await tapButton(tester, 'Save address');
      await tester.pump();

      expect(address.hasAddress, isTrue);
      expect(address.address!.city, 'Pune');
      expect(address.address!.pincode, '411001');
    });
  });

  group('address storage', () {
    test('round-trips through the repository', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalAddressRepository();

      const address = Address(
        fullName: 'Sohail',
        phone: '+91 90000 11111',
        line1: '12B, MG Road',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        landmark: 'Near the blue gate',
      );

      await repository.save(address);
      final loaded = await repository.load();

      expect(loaded, isNotNull);
      expect(loaded!.formatted, address.formatted);
      expect(loaded.landmark, 'Near the blue gate');

      await repository.clear();
      expect(await repository.load(), isNull);
    });

    test('a corrupt payload reads as no address rather than throwing',
        () async {
      SharedPreferences.setMockInitialValues({
        'delivery_address': 'not json at all',
      });
      expect(await LocalAddressRepository().load(), isNull);
    });
  });
}
