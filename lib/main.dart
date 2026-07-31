import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/pet_info_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent Google Fonts from making network requests at runtime.
  // Fonts are served from the package cache (already bundled by pub get).
  GoogleFonts.config.allowRuntimeFetching = false;

  // IMPORTANT: Do NOT await SharedPreferences before runApp().
  //
  // Previously we did `await themeProvider.load()` + `await onboardingProvider.init()`
  // here, which blocked the first frame for ~100–400 ms on cold start —
  // especially noticeable in debug mode on Android emulators (appears as
  // a "blank screen" / "Skipped N frames" warning from Choreographer).
  //
  // Instead we construct the providers synchronously with sensible defaults
  // and kick off their async loads in the background. Each provider calls
  // notifyListeners() when its load completes, so any watching widgets
  // rebuild with the persisted values automatically.
  final themeProvider = ThemeProvider();
  final onboardingProvider = OnboardingProvider();
  final authProvider = AuthProvider();
  final petInfoProvider = PetInfoProvider();
  final quizProvider = QuizProvider();
  final cartProvider = CartProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: onboardingProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: petInfoProvider),
        ChangeNotifierProvider.value(value: quizProvider),
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const MyPetFitApp(),
    ),
  );

  // Kick off persisted-state loads after the first frame has been scheduled.
  // Providers notifyListeners() when done; widgets rebuild automatically,
  // and the router re-evaluates its redirect (see AppRoutes.build).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    themeProvider.load();
    onboardingProvider.init();
    authProvider.init();
    petInfoProvider.init();
    quizProvider.init();
    cartProvider.init();
  });
}
