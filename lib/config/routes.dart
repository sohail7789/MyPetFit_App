import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/address_screen.dart';
import '../screens/account/delete_account_screen.dart';
import '../screens/account/legal_screen.dart';
import '../screens/account/my_pets_screen.dart';
import '../screens/account/owner_profile_screen.dart';
import '../screens/account/pet_profile_screen.dart';
import '../screens/account/preferences_screens.dart';
import '../screens/account/report_history_screen.dart';
import '../screens/auth/verify_code_screen.dart';
import '../screens/home/home_dashboard_screen.dart';
import '../screens/consent/consent_screen.dart';
import '../screens/pet_info/owner_info_screen.dart';
import '../screens/pet_info/pet_info_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/report/report_card_screen.dart';
import '../screens/report/scoring_screen.dart';
import '../screens/report/vet_alert_screen.dart';
import '../screens/shop/cart_screen.dart';
import '../screens/shop/checkout_screen.dart';
import '../screens/shop/order_reference.dart';
import '../screens/shop/order_success_screen.dart';
import '../screens/shop/order_tracking_screen.dart';
import '../screens/shop/product_detail_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/shop/support_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/welcome/welcome_screen.dart';

/// Route table for the redesigned flow.
///
/// Screen numbers in comments refer to the approved application design
/// (screens 01–37).
class AppRoutes {
  AppRoutes._();

  // Pre-auth ------------------------------------------------------------
  static const welcome = '/'; // 01
  static const onboarding = '/onboarding'; // 02–04
  static const signIn = '/sign-in'; // 05
  static const signUp = '/sign-up'; // 06
  static const forgotPassword = '/forgot-password'; // 07
  static const verifyCode = '/verify-code'; // 08
  static const resetPassword = '/reset-password'; // 09

  // Assessment ----------------------------------------------------------
  static const consent = '/consent'; // 10
  static const ownerInfo = '/owner-info'; // 11
  static const petInfo = '/pet-info'; // 12
  static const quiz = '/quiz'; // 13–21
  static const scoring = '/scoring'; // 22
  static const report = '/report'; // 23

  /// A stored report card — `$report/history/:index` into
  /// QuizProvider.assessmentHistory. Design screen 32b.
  static String pastReport(int index) => '$report/history/$index';
  static const vetAlert = '/vet-alert'; // 23b

  // Shell tabs ----------------------------------------------------------
  static const home = '/home'; // 30
  static const reportHistory = '/report-history'; // 32
  static const shop = '/shop'; // 24
  static const account = '/account'; // 31

  // Shop stack ----------------------------------------------------------
  static const productDetail = '/shop/product'; // 25 (+ /:id)
  static const cart = '/cart'; // 26
  static const checkout = '/checkout'; // 27
  static const orderSuccess = '/order-success'; // 28
  static const orderTracking = '/order-tracking'; // 29
  static const support = '/support'; // 29b

  // Account stack -------------------------------------------------------
  static const inbox = '/account/inbox'; // 31b
  static const pets = '/account/pets'; // 33

  /// Add a pet from My pets — saves and lands on the new pet's profile,
  /// rather than pushing straight into the assessment the way the
  /// first-run [petInfo] step does.
  static const addPet = '/account/pets/new';

  /// A saved pet's profile — `$pets/:index`. Use [petProfile] to build one.
  static String petProfile(int index) => '$pets/$index';

  /// Edit form for a saved pet — `$pets/:index/edit`.
  static String petEdit(int index) => '$pets/$index/edit';
  static const orders = '/account/orders';

  /// Delivery address form — shared by checkout and account settings.
  static const address = '/account/address';

  /// Owner profile (design 33c) and its editor (33e). The editor reuses the
  /// assessment's owner form in [OwnerFormMode.edit] rather than duplicating
  /// four identical fields.
  static const ownerProfile = '/account/owner';
  static const ownerEdit = '/account/owner/edit';
  static const reminders = '/account/reminders';
  static const language = '/account/language';
  static const terms = '/terms'; // 34
  static const privacy = '/privacy'; // 35
  static const deleteAccount = '/account/delete'; // 36
  static const accountDeleted = '/account/deleted'; // 37

  /// Routes reachable without a signed-in user.
  static const _publicRoutes = <String>{
    welcome,
    onboarding,
    signIn,
    signUp,
    forgotPassword,
    verifyCode,
    resetPassword,
  };

  static final _shellKey = GlobalKey<NavigatorState>();

  static GoRouter build({
    required AuthProvider authProvider,
    required OnboardingProvider onboardingProvider,
  }) {
    return GoRouter(
      initialLocation: welcome,
      navigatorKey: _shellKey,
      refreshListenable: Listenable.merge([authProvider, onboardingProvider]),
      redirect: (context, state) {
        // Hold still until persisted state has loaded, so the first frame
        // doesn't bounce the user through /sign-in on its way to /home.
        if (!authProvider.isLoaded || !onboardingProvider.isLoaded) return null;

        final location = state.matchedLocation;
        final isPublic = _publicRoutes.contains(location);

        if (!onboardingProvider.isComplete) {
          if (location == welcome || location == onboarding) return null;
          return onboarding;
        }

        if (location == onboarding) {
          return authProvider.isSignedIn ? home : signIn;
        }

        if (!authProvider.isSignedIn) {
          return isPublic ? null : signIn;
        }

        // Signed in and sitting on a pre-auth route → into the app.
        if (isPublic) return home;
        return null;
      },
      routes: [
        // ---- Pre-auth ---------------------------------------------------
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
          path: verifyCode,
          builder: (context, state) => const VerifyCodeScreen(),
        ),
        GoRoute(
          path: resetPassword,
          builder: (context, state) => const ResetPasswordScreen(),
        ),

        // ---- Assessment -------------------------------------------------
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
          path: scoring,
          builder: (context, state) => const ScoringScreen(),
        ),
        GoRoute(
          path: report,
          builder: (context, state) => const ReportCardScreen(),
          routes: [
            GoRoute(
              path: 'history/:index',
              builder: (context, state) => ReportCardScreen(
                historyIndex:
                    int.tryParse(state.pathParameters['index'] ?? '') ?? -1,
              ),
            ),
          ],
        ),
        GoRoute(
          path: vetAlert,
          builder: (context, state) => const VetAlertScreen(),
        ),

        // ---- Shop stack (pushed over the shell) -------------------------
        GoRoute(
          path: '$productDetail/:id',
          builder: (context, state) => ProductDetailScreen(
            productId: state.pathParameters['id']!,
          ),
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
          path: orderTracking,
          builder: (context, state) => OrderTrackingScreen(
            order: state.extra as OrderReference?,
          ),
        ),
        GoRoute(
          path: support,
          builder: (context, state) => const SupportScreen(),
        ),

        // ---- Account stack ----------------------------------------------
        GoRoute(
          path: inbox,
          builder: (context, state) => const InboxScreen(),
        ),
        GoRoute(
          path: pets,
          builder: (context, state) => const MyPetsScreen(),
        ),
        // Declared before ':index' so "new" isn't swallowed as an index.
        GoRoute(
          path: addPet,
          builder: (context, state) =>
              const PetInfoScreen(mode: PetFormMode.add),
        ),
        GoRoute(
          path: '$pets/:index',
          builder: (context, state) => PetProfileScreen(
            petIndex: int.tryParse(state.pathParameters['index'] ?? '') ?? -1,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => PetInfoScreen(
                mode: PetFormMode.edit,
                petIndex:
                    int.tryParse(state.pathParameters['index'] ?? '') ?? -1,
              ),
            ),
          ],
        ),
        GoRoute(
          path: orders,
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: address,
          builder: (context, state) => const AddressScreen(),
        ),
        GoRoute(
          path: ownerProfile,
          builder: (context, state) => const OwnerProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  const OwnerInfoScreen(mode: OwnerFormMode.edit),
            ),
          ],
        ),
        GoRoute(
          path: reminders,
          builder: (context, state) => const RemindersScreen(),
        ),
        GoRoute(
          path: language,
          builder: (context, state) => const LanguageScreen(),
        ),
        GoRoute(
          path: terms,
          builder: (context, state) => const LegalScreen.terms(),
        ),
        GoRoute(
          path: privacy,
          builder: (context, state) => const LegalScreen.privacy(),
        ),
        GoRoute(
          path: deleteAccount,
          builder: (context, state) => const DeleteAccountScreen(),
        ),
        GoRoute(
          path: accountDeleted,
          builder: (context, state) => const AccountDeletedScreen(),
        ),

        // ---- Shell ------------------------------------------------------
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: home,
                  builder: (context, state) => const HomeDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: reportHistory,
                  builder: (context, state) => const ReportHistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: shop,
                  builder: (context, state) => const ShopScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: account,
                  builder: (context, state) => const AccountScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

}

/// Navigation helpers shared by screen headers.
extension AppNavigation on BuildContext {
  /// Goes back where there is somewhere to go back to, and otherwise lands on
  /// [fallback].
  ///
  /// Screens in these flows are reached both by `push` (from a tab, with a
  /// stack behind them) and by `go` (after sign-up, or "Retake" from the
  /// report card, which replace the stack). An unconditional `pop` leaves the
  /// second case stranded with a dead back button.
  void backOr(String fallback) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}
