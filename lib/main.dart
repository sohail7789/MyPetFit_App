import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/address_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/pet_info_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/product_provider.dart';

/// Brings up Firebase using the generated per-platform options, so Android,
/// iOS and web all initialise from the same source of truth.
///
/// Failure is caught rather than fatal: a misconfigured or missing Firebase
/// project should not stop the app from launching, since nothing in the UI
/// depends on it yet.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stack) {
    if (kDebugMode) {
      debugPrint('Firebase failed to initialise: $error');
      debugPrintStack(stackTrace: stack);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();

  // IMPORTANT: Do NOT await SharedPreferences before runApp().
  //
  // Awaiting persisted state here blocks the first frame for ~100–400 ms on
  // cold start. Instead the providers are constructed synchronously with
  // sensible defaults and their loads are kicked off in the background; each
  // calls notifyListeners() on completion so watchers rebuild automatically.
  final onboardingProvider = OnboardingProvider();
  final authProvider = AuthProvider();
  final petInfoProvider = PetInfoProvider();
  final quizProvider = QuizProvider();
  final cartProvider = CartProvider();
  final localeProvider = LocaleProvider();
  final addressProvider = AddressProvider();
  final themeProvider = ThemeProvider();
  final productProvider = ProductProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: onboardingProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: petInfoProvider),
        ChangeNotifierProvider.value(value: quizProvider),
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: addressProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider.value(value: productProvider),
      ],
      child: const MyPetFitApp(),
    ),
  );

  // Assessment results are stored per pet, so the quiz has to know which pet
  // is active. Wired here rather than inside either provider so the
  // dependency is visible in one place: pets own the selection, the quiz
  // follows it.
  void bindActivePet() =>
      quizProvider.bindPet(petInfoProvider.activePet?.id);
  petInfoProvider.addListener(bindActivePet);

  // The cart persists product ids, not products, so a restored cart is only
  // rows-in-waiting until the Firestore catalog lands. Wired here for the
  // same reason as the pet binding above — the dependency between the two
  // providers is visible in one place rather than buried in either of them.
  void hydrateCart() => cartProvider.hydrate(productProvider.products);
  productProvider.addListener(hydrateCart);

  // Kick off persisted-state loads after the first frame has been scheduled.
  // The router re-evaluates its redirect when these land (see AppRoutes.build).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    onboardingProvider.init();
    authProvider.init();
    petInfoProvider.init();
    // Pets first, then the quiz binds to whichever is active. Both loads are
    // async, and the listener above covers whichever settles last.
    quizProvider.init().then((_) => bindActivePet());
    // Read the saved cart first, then load the catalog: hydrateCart runs on
    // every productProvider notification, so whichever settles last still
    // matches the two up.
    cartProvider.init().then((_) => hydrateCart());
    localeProvider.init();
    addressProvider.init();
    themeProvider.init();
    // Products are loaded from Firestore, which is async, so the provider is
    // constructed synchronously with an empty list and the load is kicked off
    // here. The provider calls notifyListeners() when the load completes so
    // the UI rebuilds automatically.
    productProvider.loadProducts();
  });
}
