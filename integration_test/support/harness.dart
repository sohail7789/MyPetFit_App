import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'package:mypetfit_app/providers/app_startup_provider.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/services/firestore_service.dart';

/// Builds the app's real screens on a device, over a fake cloud.
///
/// **Deliberately not `main()`.** That initialises the production Firebase
/// project, and an integration test that signed in, wrote assessments and
/// deleted accounts against it would be operating on real people's health
/// records. Everything here runs the app's own widgets, router and providers
/// against a fake, which is what makes these suites safe to run on any
/// machine at any time.
///
/// The trade is stated plainly in the README: this proves the app, not
/// Firebase.
Widget hostScreen(
  Widget screen, {
  required String initial,
  required FirestoreService cloud,
  QuizProvider? quiz,
  PetInfoProvider? pets,
  ProductProvider? catalog,
  List<GoRoute> extraRoutes = const [],
}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: initial, builder: (_, _) => screen),
      ...extraRoutes,
      // Anywhere a screen under test can navigate to lands on a marker, so a
      // test asserts where it arrived rather than what it tapped.
      for (final path in [
        AppRoutes.signIn,
        AppRoutes.quiz,
        AppRoutes.home,
        AppRoutes.account,
        AppRoutes.accountDeleted,
        AppRoutes.reportHistory,
        AppRoutes.pets,
        AppRoutes.shop,
      ])
        if (path != initial && extraRoutes.every((r) => r.path != path))
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Center(child: Text(path))),
          ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(
        value: quiz ?? QuizProvider(service: cloud),
      ),
      ChangeNotifierProvider.value(
        value: pets ?? PetInfoProvider(service: cloud),
      ),
      ChangeNotifierProvider.value(
        value: catalog ?? ProductProvider(service: cloud),
      ),
      ChangeNotifierProvider(
        create: (_) => AuthProvider(endSession: () async {}),
      ),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => AddressProvider()),
      ChangeNotifierProvider(create: (_) => AppStartupProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    ),
  );
}

/// The route a historical report opens into, as a marker.
///
/// A test asserts which report it arrived at rather than which row it
/// pressed, which is what makes the index arithmetic worth testing at all.
GoRoute reportRouteStub() => GoRoute(
      path: '${AppRoutes.report}/history/:index',
      builder: (_, state) => Scaffold(
        body: Center(child: Text('REPORT ${state.pathParameters['index']}')),
      ),
    );

/// A device starts with whatever the last test left behind, so every suite
/// clears it first.
Future<void> resetDeviceState() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

PetInfo testPet(String id, String name) => PetInfo(
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

ScoreResult testReport(
  int percent, {
  required String petId,
  required int daysAgo,
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

/// A quiz provider carrying [byPet], restored through its own cloud path.
Future<QuizProvider> quizWithHistory(
  FirestoreService cloud, {
  required String bindTo,
}) async {
  final quiz = QuizProvider(service: cloud);
  await quiz.init();
  await quiz.loadAssessmentsFromFirestore();
  quiz.bindPet(bindTo);
  return quiz;
}

Future<PetInfoProvider> petsWith(
  FirestoreService cloud,
  List<PetInfo> list,
) async {
  final pets = PetInfoProvider(service: cloud);
  await pets.init();
  for (final pet in list) {
    await pets.addPet(pet);
  }
  pets.setActivePet(0);
  return pets;
}
