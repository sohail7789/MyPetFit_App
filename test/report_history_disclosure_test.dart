import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/analytics/widgets/analytics_loading_state.dart';
import 'package:mypetfit_app/analytics/widgets/analytics_overview_card.dart';
import 'package:mypetfit_app/analytics/widgets/analytics_section.dart';
import 'package:mypetfit_app/analytics/widgets/category_trend_card.dart';
import 'package:mypetfit_app/analytics/widgets/insight_card.dart';
import 'package:mypetfit_app/analytics/widgets/milestone_card.dart';
import 'package:mypetfit_app/analytics/widgets/trend_graph.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';
import 'support/product_fixtures.dart';

/// Sprint 3, feature 7 — progressive disclosure on Report History.
///
/// Six sections became two that are always visible and four a tap away. These
/// tests are about what that must never cost: nothing important may end up
/// behind the control, every record stays reachable, the figures do not move,
/// and one pet's expanded section must not survive onto another's record.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const skin = 'Skin & Coat';
  const dental = 'Dental Care';

  /// Widget tests cannot inject a clock — the screen reads the real one — so
  /// fixtures are dated relative to the actual today.
  ScoreResult report(
    int percent, {
    required int daysAgo,
    String petId = 'p1',
    HealthCategory band = HealthCategory.good,
    Map<String, double> categories = const {},
  }) => ScoreResult(
    rawScore: percent,
    maxPossibleScore: 100,
    percentageScore: percent,
    category: band,
    categoryScores: categories,
    completedAt: DateTime.now().subtract(Duration(days: daysAgo)),
    petId: petId,
  );

  String rowDateLine(int daysAgo) {
    final when = DateTime.now().subtract(Duration(days: daysAgo));
    return '${relativeReportDate(when)} · ${exactReportDate(when)}';
  }

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

  Widget host(
    QuizProvider quiz,
    PetInfoProvider pets, {
    ProductProvider? catalog,
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.reportHistory,
      routes: [
        GoRoute(
          path: AppRoutes.reportHistory,
          builder: (_, _) => const ReportHistoryScreen(),
        ),
        GoRoute(
          // Identity-addressed now; resolved back to a position so these
          // cases keep asserting *which* report opened.
          path: '${AppRoutes.report}/history/:identity',
          builder: (_, state) {
            final identity = Uri.decodeComponent(
              state.pathParameters['identity'] ?? '',
            );
            final at = quiz.assessmentHistory.indexWhere(
              (r) => QuizProvider.identityOf(r) == identity,
            );
            return Scaffold(body: Center(child: Text('REPORT $at')));
          },
        ),
        GoRoute(
          path: AppRoutes.quiz,
          builder: (_, _) => const Scaffold(body: Center(child: Text('QUIZ'))),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider(create: (_) => catalog ?? emptyCatalog()),
      ],
      child: MaterialApp.router(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        routerConfig: router,
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: inner!,
        ),
      ),
    );
  }

  void sizeAt(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Tall enough that a lazily built list constructs the whole screen.
  void sizeUp(WidgetTester tester) => sizeAt(tester, const Size(1200, 4000));

  /// Brings [finder] into view and proves it was actually built.
  ///
  /// A viewport that never constructs a widget passes an "and no exception"
  /// assertion happily, which is exactly how a responsive test can look green
  /// while testing nothing.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finder, findsWidgets, reason: 'never built, so never tested');
  }

  /// Four records: enough for a trend, milestones, and a collapsed timeline.
  Future<QuizProvider> fullRecord() => quizWith({
    'p1': [
      report(74, daysAgo: 0, categories: const {skin: 70, dental: 78}),
      report(70, daysAgo: 30, categories: const {skin: 62, dental: 74}),
      report(66, daysAgo: 60, categories: const {skin: 55, dental: 70}),
      report(60, daysAgo: 90, categories: const {skin: 48, dental: 66}),
    ],
  });

  group('what is always visible', () {
    testWidgets('the summary and the trend need no tap', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // The two answers someone opens this tab for.
      expect(find.byType(AnalyticsOverviewCard), findsOneWidget);
      expect(find.byType(TrendGraph), findsOneWidget);
      expect(find.text('74'), findsWidgets);
      expect(find.text('Next assessment'), findsOneWidget);
    });

    testWidgets('the newest assessment is never behind the control', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // Four records, so the timeline is closed — and the latest one still
      // reads in full, with its date line, without expanding anything.
      expect(find.text(rowDateLine(0)), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      // The older ones are the part that waits.
      expect(find.text(rowDateLine(90)), findsNothing);
    });
  });

  group('default disclosure', () {
    testWidgets('the detail sections start closed', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // Headings present…
      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('Category progress'), findsOneWidget);
      expect(find.text('Milestone history'), findsOneWidget);
      expect(find.text('Assessment timeline'), findsOneWidget);

      // …detail not built.
      expect(find.byType(CategoryTrendCard), findsNothing);
      expect(find.byType(MilestoneCard), findsNothing);

      // Four sections and no more: the overview and the graph are not behind
      // a control, and no fifth heading crept in.
      expect(find.byType(AnalyticsSection), findsNWidgets(4));
    });

    testWidgets('a short history keeps its timeline open', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [
          report(74, daysAgo: 0),
          report(70, daysAgo: 30),
          report(66, daysAgo: 60),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // Three records fit; hiding them would be disclosure for its own sake.
      expect(find.text(rowDateLine(0)), findsOneWidget);
      expect(find.text(rowDateLine(30)), findsOneWidget);
      expect(find.text(rowDateLine(60)), findsOneWidget);
    });

    testWidgets('a single milestone opens rather than hides', (tester) async {
      sizeUp(tester);
      // Two records, both below Good: only the first-assessment milestone is
      // earned, so there is exactly one.
      final quiz = await quizWith({
        'p1': [
          report(40, daysAgo: 0, band: HealthCategory.needsImprovement),
          report(42, daysAgo: 30, band: HealthCategory.needsImprovement),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('Milestone history'));
      expect(find.byType(MilestoneCard), findsOneWidget);
    });
  });

  group('expanding and collapsing', () {
    testWidgets('category progress opens on a tap and closes again', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryTrendCard), findsNothing);

      await tester.tap(find.text('Category progress'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryTrendCard), findsNWidgets(2));

      await tester.tap(find.text('Category progress'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryTrendCard), findsNothing);
    });

    testWidgets('the timeline reveals the whole record', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();

      // Every record, including the ones the closed state stood in for.
      expect(find.text(rowDateLine(0)), findsOneWidget);
      expect(find.text(rowDateLine(30)), findsOneWidget);
      expect(find.text(rowDateLine(60)), findsOneWidget);
      expect(find.text(rowDateLine(90)), findsOneWidget);
    });

    testWidgets('milestones open on a tap', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Milestone history'));
      await tester.pumpAndSettle();

      expect(find.byType(MilestoneCard), findsWidgets);
    });

    testWidgets('expansion survives an ordinary provider rebuild', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await fullRecord();
      final pets = await withPets([pet('p1', 'Bruno')]);

      await tester.pumpWidget(host(quiz, pets));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Category progress'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryTrendCard), findsWidgets);

      // Something unrelated notifies. A reader who opened a section should
      // not have it shut under them.
      quiz.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.byType(CategoryTrendCard), findsWidgets);
    });
  });

  group('nothing important hides', () {
    testWidgets('an alert the headline did not lead with stays visible', (
      tester,
    ) async {
      sizeUp(tester);
      // Overall improved, so the headline is positive — but one area fell far
      // enough to be an alert. The alert outranks nothing on weight, so it
      // would be the finding a closed section buried.
      final quiz = await quizWith({
        'p1': [
          report(70, daysAgo: 0, categories: const {skin: 40, dental: 90}),
          report(60, daysAgo: 30, categories: const {skin: 62, dental: 60}),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // Closed, and the caution is on screen anyway.
      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('$skin declined by 22 points'), findsOneWidget);
      expect(find.byType(InsightCard), findsOneWidget);
    });

    testWidgets('with nothing pressing, the closed section reports coverage', (
      tester,
    ) async {
      sizeUp(tester);
      // Everything moved the right way: no caution, no alert, so there is
      // nothing to lift out — and the overview already carries the headline.
      final quiz = await quizWith({
        'p1': [
          report(74, daysAgo: 0, categories: const {skin: 70, dental: 78}),
          report(60, daysAgo: 30, categories: const {skin: 50, dental: 60}),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      expect(find.byType(InsightCard), findsNothing);
      expect(find.textContaining('findings'), findsOneWidget);
    });

    testWidgets('a closed section says how much it is standing in for', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      expect(find.text('2 areas tracked'), findsOneWidget);
      expect(find.textContaining('earned'), findsWidgets);
    });
  });

  group('empty and partial records', () {
    testWidgets('one assessment gets a summary and an invitation, once', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [
          report(64, daysAgo: 0, categories: const {skin: 40}),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsOverviewCard), findsOneWidget);
      expect(find.text('One assessment recorded'), findsOneWidget);

      // The sections that exist to compare are absent rather than empty, and
      // the invitation is not restated under three more headings.
      expect(find.text('What changed'), findsNothing);
      expect(find.text('Category progress'), findsNothing);
      expect(find.text('Milestone history'), findsNothing);

      // The record itself is still there.
      expect(find.text('Assessment timeline'), findsOneWidget);
      expect(find.text(rowDateLine(0)), findsOneWidget);
    });

    testWidgets('no milestones means no milestone heading', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [
          report(64, daysAgo: 0, categories: const {skin: 40}),
        ],
      });

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // An empty disclosure heading promises content that is not there.
      expect(find.text('Milestone history'), findsNothing);
    });
  });

  group('the loading race', () {
    testWidgets('a read in flight shows a skeleton, not "no reports yet"', (
      tester,
    ) async {
      sizeUp(tester);

      // Deliberately not initialised: this is the frame between the screen
      // mounting and the stored history arriving.
      final quiz = QuizProvider(service: FakeCloud());
      final pets = await withPets([pet('p1', 'Bruno')]);

      await tester.pumpWidget(host(quiz, pets));
      await tester.pump();

      expect(quiz.isLoaded, isFalse);
      expect(find.byType(AnalyticsLoadingState), findsOneWidget);
      // Telling someone they have no reports while their reports are on the
      // way back is the bug this covers.
      expect(find.text('No reports yet'), findsNothing);
    });

    testWidgets('the invitation arrives once the read lands empty', (
      tester,
    ) async {
      sizeUp(tester);

      final quiz = QuizProvider(service: FakeCloud());
      final pets = await withPets([pet('p1', 'Bruno')]);

      await tester.pumpWidget(host(quiz, pets));
      await tester.pump();

      await quiz.init();
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsLoadingState), findsNothing);
      expect(find.text('No reports yet'), findsOneWidget);
    });

    testWidgets('restored history never flashes an empty state', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pump();

      expect(find.text('No reports yet'), findsNothing);
      expect(find.byType(AnalyticsLoadingState), findsNothing);
      expect(find.byType(AnalyticsOverviewCard), findsOneWidget);
    });
  });

  group('switching pets', () {
    testWidgets('the new pet starts from its own default disclosure', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [
          report(74, daysAgo: 0, categories: const {skin: 70, dental: 78}),
          report(60, daysAgo: 30, categories: const {skin: 50, dental: 60}),
        ],
        'p2': [
          report(
            45,
            daysAgo: 2,
            petId: 'p2',
            band: HealthCategory.needsImprovement,
            categories: const {skin: 30, dental: 44},
          ),
          report(
            30,
            daysAgo: 40,
            petId: 'p2',
            band: HealthCategory.needsImprovement,
            categories: const {skin: 22, dental: 38},
          ),
        ],
      });
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);

      await tester.pumpWidget(host(quiz, pets));
      await tester.pumpAndSettle();

      // Bruno, with two sections opened.
      await tester.tap(find.text('Category progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milestone history'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryTrendCard), findsWidgets);
      expect(find.byType(MilestoneCard), findsWidgets);
      expect(find.text('74'), findsWidgets);

      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      // Mia's record, from Mia's defaults. She has earned more than one
      // milestone, so her milestone history starts closed just as Bruno's
      // did — the expansion did not travel with the screen.
      expect(find.byType(CategoryTrendCard), findsNothing);
      expect(find.byType(MilestoneCard), findsNothing);

      // And none of Bruno's numbers or rows survive.
      expect(find.text('74'), findsNothing);
      expect(find.text('Bruno'), findsNothing);
      expect(find.text('45'), findsWidgets);
      expect(find.text('Mia'), findsWidgets);
    });

    testWidgets('the new pet’s own sections still open', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [
          report(74, daysAgo: 0, categories: const {skin: 70}),
          report(60, daysAgo: 30, categories: const {skin: 50}),
        ],
        'p2': [
          report(
            45,
            daysAgo: 2,
            petId: 'p2',
            band: HealthCategory.needsImprovement,
            categories: const {skin: 30, dental: 44},
          ),
          report(
            30,
            daysAgo: 40,
            petId: 'p2',
            band: HealthCategory.needsImprovement,
            categories: const {skin: 22, dental: 38},
          ),
        ],
      });
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);

      await tester.pumpWidget(host(quiz, pets));
      await tester.pumpAndSettle();

      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Category progress'));
      await tester.pumpAndSettle();

      // Mia has two measured areas; Bruno had one.
      expect(find.byType(CategoryTrendCard), findsNWidgets(2));
    });
  });

  group('the record is unchanged', () {
    testWidgets('every stored figure reads the same before and after opening', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await fullRecord();
      final before = [
        for (final r in quiz.assessmentHistory)
          (r.percentageScore, r.category, r.completedAt, r.categoryScores),
      ];

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      for (final title in const [
        'What changed',
        'Category progress',
        'Milestone history',
        'Assessment timeline',
      ]) {
        await reveal(tester, find.text(title));
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }

      final after = [
        for (final r in quiz.assessmentHistory)
          (r.percentageScore, r.category, r.completedAt, r.categoryScores),
      ];

      // Disclosure decides what is drawn. It does not touch the record.
      expect(after, before);

      // And the timeline still reads newest first.
      expect(find.text(rowDateLine(0)), findsOneWidget);
      expect(find.text(rowDateLine(90)), findsOneWidget);
    });

    testWidgets('a revealed row still opens its own report', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();

      // The third record, which is the case a within-group index gets wrong.
      await tester.tap(find.text(rowDateLine(60)));
      await tester.pumpAndSettle();

      expect(find.text('REPORT 2'), findsOneWidget);
    });

    testWidgets('the summary row opens the newest report', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      // Tapped while the timeline is closed: the stand-in row is index zero
      // and must address the same report the full list would.
      await tester.tap(find.text(rowDateLine(0)));
      await tester.pumpAndSettle();

      expect(find.text('REPORT 0'), findsOneWidget);
    });

    testWidgets('a trend marker still opens its own report', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(RegExp('^Latest,')));
      await tester.pumpAndSettle();

      expect(find.text('REPORT 0'), findsOneWidget);
    });

    testWidgets('the chart keeps its own accessible summary', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(host(quiz, await withPets([pet('p1', 'Bruno')])));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'Health trend chart, 4 assessments')),
        findsOneWidget,
      );
      // This record climbs throughout, so its highest score *is* its latest —
      // one observation doing two jobs gets one marker, not two stacked on
      // the same dot. The trough is its own point and keeps its own marker.
      expect(find.bySemanticsLabel(RegExp('^Latest,')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Lowest,')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Highest,')), findsNothing);
    });
  });

  group('motion', () {
    testWidgets('a section opens on the next frame with animations off', (
      tester,
    ) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(
        host(
          quiz,
          await withPets([pet('p1', 'Bruno')]),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Category progress'));
      await tester.pump();

      expect(find.byType(CategoryTrendCard), findsWidgets);
    });
  });

  group('presentation', () {
    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 640),
        'large android': Size(412, 915),
        'tablet': Size(834, 1112),
        'landscape': Size(915, 412),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          sizeAt(tester, entry.value);
          final quiz = await fullRecord();

          await tester.pumpWidget(
            host(quiz, await withPets([pet('p1', 'Bruno')]), textScale: scale),
          );
          await tester.pumpAndSettle();

          // Scrolled to and confirmed built before anything is asserted about
          // it — a lazy list will happily not construct what is never seen.
          await reveal(tester, find.text('Category progress'));
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Category progress').first);
          await tester.pumpAndSettle();

          expect(find.byType(CategoryTrendCard), findsWidgets);
          expect(tester.takeException(), isNull);

          await reveal(tester, find.text('Assessment timeline'));
          await tester.tap(find.text('Assessment timeline').first);
          await tester.pumpAndSettle();

          expect(find.text(rowDateLine(90)), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('renders in dark mode, opened', (tester) async {
      sizeUp(tester);
      final quiz = await fullRecord();

      await tester.pumpWidget(
        host(
          quiz,
          await withPets([pet('p1', 'Bruno')]),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Category progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milestone history'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryTrendCard), findsWidgets);
      expect(find.byType(MilestoneCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
