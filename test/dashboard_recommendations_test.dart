import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/product.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';
import 'support/product_fixtures.dart';

/// Sprint 1, feature 4 — the recommendation card.
///
/// Deterministic by construction: the weakest scoring area from the latest
/// report is matched against each product's `recommendedFor`. Nothing is
/// inferred from a product's name, description or shop category.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const skin = 'Skin & Coat Health';
  const oral = 'Oral, Vision & Hearing';
  const sleep = 'Sleep & Nutrition';

  ScoreResult report(
    Map<String, double> categories, {
    String petId = 'p1',
  }) =>
      ScoreResult(
        rawScore: 70,
        maxPossibleScore: 100,
        percentageScore: 70,
        category: HealthCategory.good,
        categoryScores: categories,
        completedAt: DateTime.now(),
        petId: petId,
      );

  PetInfo pet(String id, String name) => PetInfo(
        id: id,
        name: name,
        breed: 'Beagle',
        ageYears: 3,
        ageMonths: 2,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  final catalog = [
    testProduct(
      id: 'omega-3',
      name: 'Omega 3 Fish Oil',
      category: 'Supplements',
      purpose: 'Supports a fuller coat and calmer skin.',
      recommendedFor: const [skin, 'Behavior & Mental Wellness'],
    ),
    testProduct(
      id: 'coat-shampoo',
      name: 'Coat Care Shampoo',
      category: 'Grooming',
      purpose: 'Gentle weekly wash for itchy skin.',
      recommendedFor: const [skin],
    ),
    testProduct(
      id: 'dental-chews',
      name: 'Daily Dental Chews',
      category: 'Dental',
      purpose: 'Scrapes plaque as they chew.',
      recommendedFor: const [oral],
    ),
    testProduct(
      id: 'plain-treats',
      name: 'Plain Training Treats',
      category: 'Treats',
      recommendedFor: const [],
    ),
  ];

  Future<QuizProvider> quizWith(
    Map<String, List<ScoreResult>> byPet, {
    String bindTo = 'p1',
  }) async {
    final quiz = QuizProvider(service: FakeCloud(assessments: byPet));
    await quiz.init();
    await quiz.loadAssessmentsFromFirestore();
    quiz.bindPet(bindTo);
    return quiz;
  }

  Future<PetInfoProvider> withPets(List<PetInfo> list) async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    for (final p in list) {
      await pets.addPet(p);
    }
    pets.setActivePet(0);
    return pets;
  }

  Widget host({
    required QuizProvider quiz,
    required PetInfoProvider pets,
    required ProductProvider products,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomeDashboardScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.productDetail}/:id',
          builder: (_, state) => Scaffold(
            body: Center(child: Text('DETAIL ${state.pathParameters['id']}')),
          ),
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
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: products),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('matching', () {
    test('only recommendedFor decides a match', () {
      final matches = recommendedProducts(catalog, skin);

      expect(matches.map((p) => p.id), ['omega-3', 'coat-shampoo']);
      // The dental product names "Dental" in its shop category and its copy,
      // and still does not match — nothing is inferred.
      expect(matches.map((p) => p.id), isNot(contains('dental-chews')));
    });

    test('a product can serve several areas', () {
      expect(
        recommendedProducts(catalog, 'Behavior & Mental Wellness')
            .map((p) => p.id),
        ['omega-3'],
      );
    });

    test('an untagged product is never recommended', () {
      for (final category in [skin, oral, sleep]) {
        expect(
          recommendedProducts(catalog, category).map((p) => p.id),
          isNot(contains('plain-treats')),
        );
      }
    });

    test('catalog order is preserved, not re-sorted', () {
      final reversed = recommendedProducts(catalog.reversed.toList(), skin);
      expect(reversed.map((p) => p.id), ['coat-shampoo', 'omega-3']);
    });

    test('an area nobody is tagged for matches nothing', () {
      expect(recommendedProducts(catalog, sleep), isEmpty);
    });

    test('documents written before the field existed match nothing', () {
      final legacy = Product.fromMap('old', const {'name': 'Old product'});
      expect(legacy.recommendedFor, isEmpty);
      expect(recommendedProducts([legacy], skin), isEmpty);
    });
  });

  group('the card', () {
    testWidgets('recommends against the weakest area', (tester) async {
      sizeUp(tester);
      // Oral is the better score, so it must not drive the card.
      final quiz = await quizWith({
        'p1': [report({skin: 38, oral: 81, sleep: 74})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Recommended for Bruno'), findsOneWidget);
      expect(find.text('Based on your latest assessment'), findsOneWidget);
      expect(find.text('Omega 3 Fish Oil'), findsOneWidget);
      expect(find.text('Coat Care Shampoo'), findsOneWidget);
      expect(find.text('Daily Dental Chews'), findsNothing);
    });

    testWidgets('several matches scroll horizontally', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report({skin: 38, oral: 81})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      final list = tester.widget<ListView>(
        find.descendant(
          of: find.byType(SizedBox),
          matching: find.byType(ListView),
        ).first,
      );
      expect(list.scrollDirection, Axis.horizontal);
      expect(find.text('View Product'), findsNWidgets(2));
    });

    testWidgets('a single match gets the featured treatment', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report({oral: 30, skin: 88})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Daily Dental Chews'), findsOneWidget);
      expect(find.text('Scrapes plaque as they chew.'), findsOneWidget);
      expect(find.text('₹649'), findsOneWidget);
      expect(find.text('View Product'), findsOneWidget);
    });

    testWidgets('View Product opens the existing detail screen',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report({oral: 30, skin: 88})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Product'));
      await tester.pumpAndSettle();

      expect(find.text('DETAIL dental-chews'), findsOneWidget);
    });

    testWidgets('falls back to a neutral title with no pet name',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report({skin: 38})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([]),
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Recommended for you'), findsOneWidget);
    });
  });

  group('empty states', () {
    testWidgets('no assessment invites one', (tester) async {
      sizeUp(tester);
      final quiz = QuizProvider(service: FakeCloud());
      await quiz.init();

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Complete an assessment to receive personalized recommendations.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Start Assessment'));
      await tester.pumpAndSettle();
      expect(find.text(AppRoutes.quiz), findsOneWidget);
    });

    testWidgets('nothing tagged for the weakest area says so', (tester) async {
      sizeUp(tester);
      // Sleep is weakest, and no product is tagged for it.
      final quiz = await quizWith({
        'p1': [report({sleep: 22, skin: 90})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No recommendations available yet.'), findsOneWidget);
    });

    testWidgets('an empty catalog is the same case', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report({skin: 38})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: await loadedCatalog(const []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No recommendations available yet.'), findsOneWidget);
    });
  });

  group('loading state', () {
    testWidgets('skeleton while the catalog is in flight', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report({skin: 38})],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        products: pendingCatalog(),
      ));
      await tester.pump();

      expect(
        find.bySemanticsLabel('Loading recommendations'),
        findsOneWidget,
      );
      expect(find.text('No recommendations available yet.'), findsNothing);
    });
  });

  group('multiple pets', () {
    testWidgets('switching pets re-recommends immediately', (tester) async {
      sizeUp(tester);

      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      final quiz = await quizWith({
        'p1': [report({skin: 38, oral: 81})],
        'p2': [report({oral: 24, skin: 92}, petId: 'p2')],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: pets,
        products: await loadedCatalog(catalog),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Recommended for Bruno'), findsOneWidget);
      expect(find.text('Omega 3 Fish Oil'), findsOneWidget);
      expect(find.text('Daily Dental Chews'), findsNothing);

      // main.dart binds the quiz to the active pet; this drives it the same
      // way so the card is exercised through the real coupling.
      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      expect(find.text('Recommended for Mia'), findsOneWidget);
      expect(find.text('Daily Dental Chews'), findsOneWidget);
      expect(find.text('Omega 3 Fish Oil'), findsNothing);
    });
  });
}
