import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/screens/consent/consent_screen.dart';

import 'support/fake_cloud.dart';

/// The consent screen has to *record* consent, not just move on from it.
///
/// It used to only navigate: "Agree & Continue" pushed /owner-info and never
/// called giveConsent, so `consentGiven` stayed false for the whole session.
/// Nothing noticed until the next launch, because the router only re-checks
/// the gates on an entry route — so the user finished the assessment, and was
/// then sent back to the consent form on every subsequent sign-in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(PetInfoProvider pets) {
    final router = GoRouter(
      initialLocation: AppRoutes.consent,
      routes: [
        GoRoute(
          path: AppRoutes.consent,
          builder: (_, _) => const ConsentScreen(),
        ),
        GoRoute(
          path: AppRoutes.petInfo,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('PET INFO'))),
        ),
      ],
    );

    return ChangeNotifierProvider.value(
      value: pets,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<void> agreeAndContinue(WidgetTester tester) async {
    await tester.tap(find.text('I have read and agree to the consent above.'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Sohail Inamdar');
    await tester.pump();
    await tester.tap(find.text('Agree & Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('agreeing records consent, not just navigation', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    expect(pets.consentGiven, isFalse);

    await tester.pumpWidget(host(pets));
    await tester.pump();
    await agreeAndContinue(tester);

    // The navigation always worked. The recording is what was missing.
    expect(find.text('PET INFO'), findsOneWidget);
    expect(pets.consentGiven, isTrue);
  });

  testWidgets('the typed signature is captured with the consent',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();

    await tester.pumpWidget(host(pets));
    await tester.pump();
    await agreeAndContinue(tester);

    expect(pets.consentRecord?.signatureName, 'Sohail Inamdar');
    expect(pets.consentUpdatedAt, isNotNull);
  });

  testWidgets('consent is on disk before the next screen appears',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();

    await tester.pumpWidget(host(pets));
    await tester.pump();
    await agreeAndContinue(tester);

    // giveConsent awaits its own local write, so leaving this screen cannot
    // outrun the persistence — a process death on the owner form still finds
    // the decision recorded on the next launch.
    expect(find.text('PET INFO'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pet_info_state'), contains('"consentGiven":true'));
  });

  testWidgets('the recorded consent reaches the cloud', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cloud = FakeCloud();
    final pets = PetInfoProvider(service: cloud);
    await pets.init();

    await tester.pumpWidget(host(pets));
    await tester.pump();
    await agreeAndContinue(tester);
    await tester.pumpAndSettle();

    // Without this the account-level persistence added earlier has nothing to
    // persist, and every later sign-in restores `given: false`.
    expect(cloud.consentWrites, 1);
    expect(cloud.consent?.given, isTrue);
    expect(cloud.consent?.record?.signatureName, 'Sohail Inamdar');
  });
}
