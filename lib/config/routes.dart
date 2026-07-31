import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/consent/consent_screen.dart';
import '../screens/pet_info/owner_info_screen.dart';
import '../screens/pet_info/pet_info_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/report/report_card_screen.dart';
import '../screens/products/product_recommendation_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/cart/order_success_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/wellness/wellness_hub_screen.dart';

class AppRoutes {
  static const welcome = '/';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const consent = '/consent';
  static const ownerInfo = '/owner-info';
  static const petInfo = '/pet-info';
  static const quiz = '/quiz';
  static const report = '/report';
  static const products = '/products';
  static const allProducts = '/products/all';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderSuccess = '/order-success';
  static const home = '/home';
  static const wellness = '/wellness';
  static const account = '/account';

  /// Routes that don't require the user to be signed in.
  static const _publicRoutes = <String>{
    welcome,
    onboarding,
    signIn,
    signUp,
    forgotPassword,
  };

  /// Build the router. Called from [MyPetFitApp] with the live providers so
  /// the router can gate routes based on onboarding + auth state, and
  /// re-evaluate whenever either provider notifies.
  static GoRouter build({
    required AuthProvider authProvider,
    required OnboardingProvider onboardingProvider,
  }) {
    return GoRouter(
      initialLocation: welcome,
      refreshListenable: Listenable.merge([authProvider, onboardingProvider]),
      redirect: (context, state) {
        // Wait until both providers have finished loading their persisted
        // state — otherwise the very first frame would redirect the user
        // to /sign-in only to bounce them to /home a moment later.
        if (!authProvider.isLoaded || !onboardingProvider.isLoaded) return null;

        final location = state.matchedLocation;
        final isPublic = _publicRoutes.contains(location);

        // Not onboarded yet → send to onboarding (except from welcome).
        if (!onboardingProvider.isComplete) {
          if (location == welcome || location == onboarding) return null;
          return onboarding;
        }

        // Already onboarded — don't let them see the onboarding pages again.
        if (location == onboarding) {
          return authProvider.isSignedIn ? home : signIn;
        }

        // Onboarded but not signed in → force auth on protected routes.
        if (!authProvider.isSignedIn) {
          if (isPublic) return null;
          return signIn;
        }

        // Signed in and landing on a public/pre-app route → jump to home.
        if (isPublic) return home;
        return null;
      },
      routes: [
        GoRoute(
          path: welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: signIn,
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: signUp,
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: consent,
          builder: (context, state) => const ConsentScreen(),
        ),
        GoRoute(
          path: ownerInfo,
          builder: (context, state) => const OwnerInfoScreen(),
        ),
        GoRoute(
          path: petInfo,
          builder: (context, state) => const PetInfoScreen(),
        ),
        GoRoute(
          path: quiz,
          builder: (context, state) => const QuizScreen(),
        ),
        GoRoute(
          path: report,
          builder: (context, state) => const ReportCardScreen(),
        ),
        GoRoute(
          path: products,
          builder: (context, state) => const ProductRecommendationScreen(),
        ),
        GoRoute(
          path: allProducts,
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(
          path: cart,
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: checkout,
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: orderSuccess,
          builder: (context, state) => const OrderSuccessScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const AppShell(),
        ),
        GoRoute(
          path: wellness,
          builder: (context, state) => const WellnessHubScreen(),
        ),
      ],
    );
  }
}
