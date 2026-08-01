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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent Google Fonts from making network requests at runtime.
  // Fonts are served from the package cache (already bundled by pub get).
  GoogleFonts.config.allowRuntimeFetching = false;

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

  runApp(
    MultiProvider(
      providers: [
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
  // The router re-evaluates its redirect when these land (see AppRoutes.build).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    onboardingProvider.init();
    authProvider.init();
    petInfoProvider.init();
    quizProvider.init();
    cartProvider.init();
  });
}
