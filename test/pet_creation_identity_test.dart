import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/pet_info/pet_info_screen.dart';
import 'package:mypetfit_app/widgets/app_button.dart';

/// One real pet is one Firestore document, however many times it is saved.
///
/// Reported as two pet documents for a single animal, six seconds apart, the
/// first with no assessments and the second with all of them. The cause was
/// not a double tap and not a race — it was reachable by hand, every time.
///
/// Onboarding *pushes* the quiz on top of the pet form, so backing out of the
/// first question returns to the same State object. `_editing` was resolved
/// once in initState, before any pet existed, so it was still null; a second
/// submit therefore minted a fresh `pet_<microseconds>` id.
/// [PetInfoProvider.setPetInfo] replaces the active pet locally, so the app
/// still showed one pet and nothing looked wrong — but the cloud write is
/// keyed by id, so Firestore gained a second document, and the assessment
/// that followed was filed under the newer one.
///
/// The id is the whole property: `savePet` writes `doc(pet.id)` and the sync
/// queue is keyed `pet-${id}`, so a stable id is exactly what makes repeated
/// saves land on one document.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late GoRouter router;

  Widget host(Widget child, {required PetInfoProvider pets}) {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => child),
        // The real destination: onboarding pushes it, which is what keeps the
        // form alive underneath and makes the second submit reachable.
        GoRoute(
          path: AppRoutes.quiz,
          builder: (context, state) => const Scaffold(body: Text('quiz')),
        ),
        // Where add and edit land. Registered so a save that works is not
        // reported as a navigation failure.
        GoRoute(
          path: AppRoutes.pets,
          builder: (context, state) => const Scaffold(body: Text('pets')),
          routes: [
            GoRoute(
              path: ':index',
              builder: (context, state) =>
                  const Scaffold(body: Text('pet profile')),
            ),
          ],
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> startTheAssessment(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(AppButton, 'Start the assessment'),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'backing out of the quiz and saving again keeps one pet, with one id',
    (tester) async {
      useTallSurface(tester);
      final pets = PetInfoProvider();

      await tester.pumpWidget(
        host(const PetInfoScreen(), pets: pets),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Bruno');
      await startTheAssessment(tester);

      expect(pets.pets, hasLength(1));
      final firstId = pets.pets.single.id;
      expect(firstId, startsWith('pet_'));

      // Back out of the first question, the way the incident did.
      router.pop();
      await tester.pumpAndSettle();

      await startTheAssessment(tester);

      expect(
        pets.pets,
        hasLength(1),
        reason: 'the same animal was entered once',
      );
      expect(
        pets.pets.single.id,
        firstId,
        reason: 'a second id here is a second Firestore document: savePet '
            'writes doc(pet.id), and the first document would be left behind '
            'with no assessments',
      );
    },
  );

  testWidgets('two different pets still get two different ids', (tester) async {
    useTallSurface(tester);
    final pets = PetInfoProvider();

    await tester.pumpWidget(host(const PetInfoScreen(), pets: pets));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'Bruno');
    await startTheAssessment(tester);
    final first = pets.pets.single.id;

    // A second animal is added through its own form, which is a fresh State
    // and therefore a fresh id. Collapsing these would be the opposite bug:
    // the app supports several pets and each is its own document.
    await tester.pumpWidget(
      host(const PetInfoScreen(mode: PetFormMode.add), pets: pets),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'Kaali');
    await tester.tap(find.widgetWithText(AppButton, 'Save pet'));
    await tester.pump();
    await tester.pump();

    expect(pets.pets, hasLength(2));
    expect(pets.pets.map((p) => p.id).toSet(), hasLength(2));
    expect(pets.pets.first.id, first, reason: 'the first pet keeps its id');
  });

  testWidgets('editing a saved pet keeps its id', (tester) async {
    useTallSurface(tester);
    final pets = PetInfoProvider();

    await tester.pumpWidget(host(const PetInfoScreen(), pets: pets));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'Bruno');
    await startTheAssessment(tester);
    final id = pets.pets.single.id;

    await tester.pumpWidget(
      host(
        const PetInfoScreen(mode: PetFormMode.edit, petIndex: 0),
        pets: pets,
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'Bruno Jr');
    await tester.tap(find.widgetWithText(AppButton, 'Save changes'));
    await tester.pump();
    await tester.pump();

    expect(pets.pets.single.id, id);
    expect(pets.pets.single.name, 'Bruno Jr');
  });
}
