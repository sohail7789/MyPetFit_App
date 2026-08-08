import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/analytics/widgets/analytics_empty_state.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';
import 'package:mypetfit_app/screens/report/report_card_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';
import 'support/product_fixtures.dart';

/// Sprint 3, feature 8 — controls a screen reader can actually operate.
///
/// **`tester.tap()` proves nothing here.** It dispatches a pointer event, and
/// a control can accept pointers while offering assistive technology no way
/// in at all: `Semantics(excludeSemantics: true)` strips the tap action off
/// the descendant detector, leaving a node that announces itself as a button
/// and does nothing when TalkBack or VoiceOver activates it. Six real
/// controls shipped that way — every past report, every chart marker, print,
/// the empty-state invitation, the product tile and the dashboard's four
/// actions.
///
/// So these tests activate controls the way a screen reader does: by finding
/// the semantics node and performing [SemanticsAction.tap] on it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Fires [SemanticsAction.tap] on the node carrying [label], the way an
  /// assistive technology would, having first insisted the node is a button
  /// that advertises the action.
  ///
  /// The two assertions are both load-bearing. Without the action check a
  /// missing action reads as "the callback did not run"; without performing
  /// it, an advertised action that is wired to nothing still passes.
  void activate(WidgetTester tester, Finder finder, {String? because}) {
    expect(finder, findsOneWidget, reason: because);

    final node = tester.getSemantics(finder);
    final data = node.getSemanticsData();

    expect(
      data.flagsCollection.isButton,
      isTrue,
      reason: 'not announced as a button${because == null ? '' : ' — $because'}',
    );
    expect(
      data.hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'announced as a button but offers no tap action, so a screen '
          'reader can read it and never press it'
          '${because == null ? '' : ' — $because'}',
    );

    node.owner!.performAction(node.id, SemanticsAction.tap);
  }

  ScoreResult report(
    int percent, {
    required int daysAgo,
    String? petId = 'p1',
    HealthCategory band = HealthCategory.good,
    Map<String, double> categories = const {'Skin & Coat': 55},
  }) =>
      ScoreResult(
        rawScore: percent,
        maxPossibleScore: 100,
        percentageScore: percent,
        category: band,
        categoryScores: categories,
        completedAt: DateTime.now().subtract(Duration(days: daysAgo)),
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

  Future<QuizProvider> quizWith(Map<String, List<ScoreResult>> byPet,
      {String bindTo = 'p1'}) async {
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

  Widget host(
    Widget screen, {
    required QuizProvider quiz,
    required PetInfoProvider pets,
    ProductProvider? catalog,
    String initial = AppRoutes.reportHistory,
    Brightness brightness = Brightness.light,
  }) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: initial, builder: (_, _) => screen),
        GoRoute(
          path: '${AppRoutes.report}/history/:index',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('REPORT ${state.pathParameters['index']}'),
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.productDetail}/:id',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('PRODUCT ${state.pathParameters['id']}'),
            ),
          ),
        ),
        for (final path in [
          AppRoutes.quiz,
          AppRoutes.reportHistory,
          AppRoutes.pets,
          AppRoutes.shop,
          AppRoutes.petInfo,
          AppRoutes.report,
          AppRoutes.account,
          AppRoutes.inbox,
          AppRoutes.home,
        ])
          if (path != initial)
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
        ChangeNotifierProvider.value(value: catalog ?? emptyCatalog()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        routerConfig: router,
      ),
    );
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('every control can be operated without a pointer', () {
    testWidgets('a timeline row opens its own report', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({
        'p1': [report(74, daysAgo: 0), report(60, daysAgo: 30)],
      });

      await tester.pumpWidget(host(
        const ReportHistoryScreen(),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
      ));
      await tester.pumpAndSettle();

      activate(
        tester,
        find.bySemanticsLabel(RegExp(r'^Bruno, 60 percent')),
        because: 'the older report on the timeline',
      );
      await tester.pumpAndSettle();

      // Not merely "the action fired" — the right report opened.
      expect(find.text('REPORT 1'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a trend marker opens the report it marks', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({
        'p1': [report(74, daysAgo: 0), report(60, daysAgo: 30)],
      });

      await tester.pumpWidget(host(
        const ReportHistoryScreen(),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
      ));
      await tester.pumpAndSettle();

      activate(
        tester,
        find.bySemanticsLabel(RegExp('^Lowest,')),
        because: 'the marker whose hint promises it opens a report',
      );
      await tester.pumpAndSettle();

      expect(find.text('REPORT 1'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the recommendation tile opens the product', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({
        'p1': [
          report(74, daysAgo: 0, categories: const {'Skin & Coat': 40}),
          report(60, daysAgo: 30, categories: const {'Skin & Coat': 55}),
        ],
      });

      await tester.pumpWidget(host(
        const ReportHistoryScreen(),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        catalog: loadedTestCatalog([
          testProduct(
            id: 'skin-oil',
            name: 'Skin Support Oil',
            recommendedFor: const ['Skin & Coat'],
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      activate(
        tester,
        find.bySemanticsLabel(RegExp('^Recommended for Skin & Coat')),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRODUCT skin-oil'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the empty-state invitation can be accepted', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      var started = 0;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AnalyticsEmptyState.noHistory(onStart: () => started++),
        ),
      ));
      await tester.pumpAndSettle();

      activate(tester, find.bySemanticsLabel('Take the assessment'));
      await tester.pump();

      expect(started, 1, reason: 'the action fired but reached nothing');

      handle.dispose();
    });

    testWidgets('a dashboard quick action navigates', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({'p1': [report(74, daysAgo: 0)]});

      await tester.pumpWidget(host(
        const HomeDashboardScreen(),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        initial: AppRoutes.home,
      ));
      await tester.pumpAndSettle();

      // The visible label is shortened to fit four across, which is why the
      // node carries its own — and why its semantics were excluded, which is
      // what dropped the action.
      activate(tester, find.bySemanticsLabel('View reports'));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.reportHistory), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the print button reaches the print path', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({'p1': [report(74, daysAgo: 0)]});

      // The real capability check reaches the printing plugin, which never
      // answers under `flutter test` — so the control was absent from every
      // widget test and its accessibility went uncovered. Production passes
      // nothing and still asks ReportPdf.
      await tester.pumpWidget(host(
        ReportCardScreen(historyIndex: 0, canPrint: () async => true),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        initial: AppRoutes.report,
      ));
      await tester.pumpAndSettle();

      activate(tester, find.bySemanticsLabel('Print report'));
      await tester.pump();

      // The callback ran: the control reports itself busy while it works.
      // Anything further belongs to the plugin, which is not under test here.
      expect(
        find.bySemanticsLabel('Preparing the report to print'),
        findsOneWidget,
        reason: 'the action fired but the print callback never ran',
      );

      handle.dispose();
    });
  });

  group('the action survives every layout', () {
    // Semantics are not layout, so this is cheap cover rather than a deep
    // sweep: the point is that shrinking the screen or growing the text can
    // reflow a control without quietly costing it its action, and that a
    // control scrolled out of view is still reachable once revealed.
    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 640),
        'large android': Size(412, 915),
        'tablet': Size(834, 1112),
        'landscape': Size(915, 412),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();

          final quiz = await quizWith({
            'p1': [report(74, daysAgo: 0), report(60, daysAgo: 30)],
          });

          await tester.pumpWidget(MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: host(
              const ReportHistoryScreen(),
              quiz: quiz,
              pets: await withPets([pet('p1', 'Bruno')]),
            ),
          ));
          await tester.pumpAndSettle();

          final row = find.bySemanticsLabel(RegExp(r'^Bruno, 60 percent'));
          await tester.scrollUntilVisible(
            row,
            220,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          activate(tester, row, because: '${entry.key} at $scale');
          await tester.pumpAndSettle();

          expect(find.text('REPORT 1'), findsOneWidget);
          expect(tester.takeException(), isNull);

          handle.dispose();
        });
      }
    }

    testWidgets('and in dark mode', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({
        'p1': [report(74, daysAgo: 0), report(60, daysAgo: 30)],
      });

      await tester.pumpWidget(host(
        const ReportHistoryScreen(),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      activate(tester, find.bySemanticsLabel(RegExp(r'^Bruno, 60 percent')));
      await tester.pumpAndSettle();

      expect(find.text('REPORT 1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      handle.dispose();
    });
  });

  group('the pattern cannot come back', () {
    /// Every enabled button on screen must advertise a tap action.
    ///
    /// A behavioural guard rather than a search for a code shape: the defect
    /// was one particular spelling of it, but the thing that matters is that
    /// nothing announces itself as a pressable control while offering no way
    /// to press it. This catches whatever spelling arrives next.
    List<String> unusableButtons(WidgetTester tester) {
      final broken = <String>[];

      void walk(SemanticsNode node) {
        final data = node.getSemanticsData();
        final flags = data.flagsCollection;

        // A disabled control correctly has no action.
        final disabled = flags.isEnabled == Tristate.isFalse;

        if (flags.isButton &&
            !disabled &&
            !data.hasAction(SemanticsAction.tap)) {
          broken.add('"${data.label}"');
        }

        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      walk(tester.semantics.find(find.byType(MaterialApp)));
      return broken;
    }

    testWidgets('report history offers no dead buttons', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({
        'p1': [
          report(74, daysAgo: 0, categories: const {'Skin & Coat': 40}),
          report(60, daysAgo: 30, categories: const {'Skin & Coat': 55}),
          report(52, daysAgo: 60, categories: const {'Skin & Coat': 50}),
          report(48, daysAgo: 90, categories: const {'Skin & Coat': 44}),
        ],
      });

      await tester.pumpWidget(host(
        const ReportHistoryScreen(),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        catalog: loadedTestCatalog([
          testProduct(
            id: 'skin-oil',
            recommendedFor: const ['Skin & Coat'],
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(unusableButtons(tester), isEmpty);

      // And again with the detail open, which is where most of the controls
      // on this screen actually live.
      for (final section in const ['Category progress', 'Assessment timeline']) {
        await tester.tap(find.text(section));
        await tester.pumpAndSettle();
      }

      expect(unusableButtons(tester), isEmpty);

      handle.dispose();
    });

    testWidgets('the report card offers no dead buttons', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({
        'p1': [report(74, daysAgo: 0), report(60, daysAgo: 30)],
      });

      await tester.pumpWidget(host(
        ReportCardScreen(historyIndex: 0, canPrint: () async => true),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        initial: AppRoutes.report,
      ));
      await tester.pumpAndSettle();

      expect(unusableButtons(tester), isEmpty);

      handle.dispose();
    });

    testWidgets('the dashboard offers no dead buttons', (tester) async {
      sizeUp(tester);
      final handle = tester.ensureSemantics();

      final quiz = await quizWith({'p1': [report(74, daysAgo: 0)]});

      await tester.pumpWidget(host(
        const HomeDashboardScreen(),
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        initial: AppRoutes.home,
      ));
      await tester.pumpAndSettle();

      expect(unusableButtons(tester), isEmpty);

      handle.dispose();
    });

    testWidgets('the guard itself fails on a dead button', (tester) async {
      // A guard that cannot fail is worse than no guard: it reports safety
      // it never checked. This is the fixture that proves it bites.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Semantics(
            button: true,
            label: 'DEAD BUTTON',
            container: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () {},
              child: const SizedBox(width: 100, height: 60),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(unusableButtons(tester), contains('"DEAD BUTTON"'));

      handle.dispose();
    });
  });
}
