import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_band.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/report/report_card_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';

/// Sprint 2, feature 3 — presentation only.
///
/// Nothing here may change what a report says. These tests pin the new
/// hierarchy and the category cards, and re-assert that the stored values
/// still render exactly as filed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ScoreResult report({
    int percent = 73,
    Map<String, double> categories = const {
      'Skin & Coat Health': 41,
      'Sleep & Nutrition': 92,
    },
    HealthCategory band = HealthCategory.good,
    DateTime? at,
    int? rawScore,
    String petId = 'p1',
  }) => ScoreResult(
    rawScore: rawScore ?? percent,
    maxPossibleScore: 100,
    percentageScore: percent,
    category: band,
    categoryScores: categories,
    completedAt: at ?? DateTime(2026, 2, 14, 14, 35),
    petId: petId,
  );

  PetInfo pet(String id, String name, {String breed = 'Beagle'}) => PetInfo(
    id: id,
    name: name,
    breed: breed,
    ageYears: 3,
    ageMonths: 2,
    gender: PetGender.male,
    weightKg: 12,
    heightCm: 38,
    updatedAt: DateTime.utc(2026, 1, 2),
  );

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
    int? historyIndex,
    double textScale = 1,
  }) {
    final router = GoRouter(
      initialLocation: '/view',
      routes: [
        GoRoute(
          path: '/view',
          // See the viewer test: positions are resolved to identities here
          // so the cases can keep reading as "the nth report".
          builder: (_, _) => ReportCardScreen(
            reportIdentity: historyIndex == null
                ? null
                : (historyIndex < quiz.assessmentHistory.length
                      ? QuizProvider.identityOf(
                          quiz.assessmentHistory[historyIndex],
                        )
                      : 'no-such-report'),
          ),
        ),
        for (final path in [
          AppRoutes.quiz,
          AppRoutes.home,
          AppRoutes.shop,
          AppRoutes.reportHistory,
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Center(child: Text(path))),
          ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
  }

  /// Scrolls until [target] has been built.
  ///
  /// The report list is lazy: asserting "no overflow" without reaching the
  /// bottom only ever exercised whatever fitted above the fold, which on a
  /// small phone is the hero and nothing else. Settles between drags so the
  /// scroll is not fighting its own momentum.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    final list = find.byType(Scrollable).last;
    for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -240));
      await tester.pumpAndSettle();
    }
  }

  void sizeAt(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('score presentation', () {
    testWidgets('the score leads and the band is a badge', (tester) async {
      sizeAt(tester, const Size(1200, 4000));
      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [report(percent: 73)],
          }),
          pets: await withPets([pet('p1', 'Bruno')]),
          historyIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('73'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
      // The overall band appears once in the hero badge; the two category
      // cards carry their own bands.
      expect(find.bySemanticsLabel('Health band: Good'), findsWidgets);
      expect(find.bySemanticsLabel('73 percent'), findsOneWidget);
    });

    testWidgets('the date is no longer competing with the title', (
      tester,
    ) async {
      sizeAt(tester, const Size(1200, 4000));
      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [report()],
          }),
          pets: await withPets([pet('p1', 'Bruno')]),
          historyIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FITNESS REPORT CARD'), findsOneWidget);
      // It sits in the metadata card now, with the time beside it.
      expect(find.text('14 Feb 2026 · 2:35 pm'), findsOneWidget);
      expect(find.text('Assessed'), findsOneWidget);
    });

    test('the time reads in 12-hour form, including the edges', () {
      expect(reportTime(DateTime(2026, 2, 14, 0, 5)), '12:05 am');
      expect(reportTime(DateTime(2026, 2, 14, 12, 0)), '12:00 pm');
      expect(reportTime(DateTime(2026, 2, 14, 9, 7)), '9:07 am');
      expect(reportTime(DateTime(2026, 2, 14, 23, 59)), '11:59 pm');
    });

    test('the date pads the day so widths do not jump', () {
      expect(reportDate(DateTime(2026, 2, 4)), '04 Feb 2026');
      expect(reportDate(DateTime(2026, 12, 25)), '25 Dec 2026');
    });
  });

  group('category cards', () {
    testWidgets('each category becomes its own card', (tester) async {
      sizeAt(tester, const Size(1200, 4000));
      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [report()],
          }),
          pets: await withPets([pet('p1', 'Bruno')]),
          historyIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 categories'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Skin & Coat Health, 41 percent, Needs Improvement',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Sleep & Nutrition, 92 percent, Excellent'),
        findsOneWidget,
      );
      // Icon, percentage and a bar for each.
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    test('a category band uses the same cutoffs as the overall band', () {
      // Colour and label cannot disagree, because both read AppConstants.
      expect(bandForPercent(0), HealthCategory.critical);
      expect(bandForPercent(25), HealthCategory.critical);
      expect(bandForPercent(26), HealthCategory.needsImprovement);
      expect(bandForPercent(50), HealthCategory.needsImprovement);
      expect(bandForPercent(51), HealthCategory.good);
      expect(bandForPercent(75), HealthCategory.good);
      expect(bandForPercent(76), HealthCategory.excellent);
      expect(bandForPercent(100), HealthCategory.excellent);
    });

    test('an unknown category still gets a glyph', () {
      // Renaming a category in the questionnaire must not break the card.
      expect(categoryIcon('Skin & Coat Health'), Icons.spa_outlined);
      expect(
        categoryIcon('Some Category Added Later'),
        Icons.check_circle_outline_rounded,
      );
    });
  });

  group('assessment metadata', () {
    testWidgets('names the pet, its breed and when it was assessed', (
      tester,
    ) async {
      sizeAt(tester, const Size(1200, 4000));
      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [report()],
          }),
          pets: await withPets([pet('p1', 'Bruno', breed: 'Corgi')]),
          historyIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Corgi · 3 years · 12 kg'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pet: Bruno, Corgi · 3 years · 12 kg'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Assessed on 14 Feb 2026 · 2:35 pm'),
        findsOneWidget,
      );
    });
  });

  group('historical integrity survives the polish', () {
    testWidgets('the stored percentage still wins over a derived one', (
      tester,
    ) async {
      sizeAt(tester, const Size(1200, 4000));
      // raw/max say 20%; the record says 73.
      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [report(percent: 73, rawScore: 20)],
          }),
          pets: await withPets([pet('p1', 'Bruno')]),
          historyIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('73'), findsOneWidget);
      expect(find.text('20'), findsNothing);
    });

    testWidgets('the stored band still wins over a derived one', (
      tester,
    ) async {
      sizeAt(tester, const Size(1200, 4000));
      // 12% would band as Critical if re-derived.
      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [report(percent: 12, band: HealthCategory.excellent)],
          }),
          pets: await withPets([pet('p1', 'Bruno')]),
          historyIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Health band: Excellent'), findsWidgets);
      expect(find.bySemanticsLabel('Health band: Critical'), findsNothing);
    });

    testWidgets('the report still belongs to its own pet', (tester) async {
      sizeAt(tester, const Size(1200, 4000));
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      pets.setActivePet(1);

      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [report()],
          }),
          pets: pets,
          historyIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Mia'), findsNothing);
    });
  });

  group('responsive layout', () {
    // Every combination has to lay out without a RenderFlex overflow, which
    // Flutter surfaces as an exception during paint.
    const sizes = <String, Size>{
      'small android': Size(320, 640),
      'large android': Size(412, 915),
      'tablet': Size(834, 1112),
      'landscape': Size(915, 412),
    };

    for (final entry in sizes.entries) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          sizeAt(tester, entry.value);

          await tester.pumpWidget(
            host(
              quiz: await quizWith({
                'p1': [
                  report(
                    categories: const {
                      'Skin & Coat Health': 41,
                      'Behavior & Mental Wellness': 63,
                      'Medical & Lifestyle Tracking': 88,
                    },
                  ),
                ],
              }),
              pets: await withPets([
                pet('p1', 'Bartholomew', breed: 'Rhodesian Ridgeback'),
              ]),
              historyIndex: 0,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();
          // The headline is on screen before anything scrolls.
          expect(find.text('73'), findsOneWidget);

          await reveal(tester, find.text('88%'));

          expect(tester.takeException(), isNull);
          // The last card built, so the whole page was laid out.
          expect(find.text('88%'), findsOneWidget);
        });
      }
    }

    testWidgets('a long category name wraps rather than overflowing', (
      tester,
    ) async {
      sizeAt(tester, const Size(320, 640));
      await tester.pumpWidget(
        host(
          quiz: await quizWith({
            'p1': [
              report(
                categories: const {
                  'An Extremely Long Category Name That Will Not Fit': 55,
                },
              ),
            ],
          }),
          pets: await withPets([pet('p1', 'Bruno')]),
          historyIndex: 0,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('55%'));

      expect(tester.takeException(), isNull);
      expect(find.text('55%'), findsOneWidget);
    });
  });
}
