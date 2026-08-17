import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/address_list_screen.dart';
import '../screens/account/address_screen.dart';
import '../screens/account/delete_account_screen.dart';
import '../screens/account/legal_screen.dart';
import '../screens/account/my_pets_screen.dart';
import '../screens/account/owner_profile_screen.dart';
import '../screens/account/pet_profile_screen.dart';
import '../screens/account/preferences_screens.dart';
import '../screens/account/report_history_screen.dart';
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
import '../screens/shell/coming_soon_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../providers/app_startup_provider.dart';
import '../providers/pet_info_provider.dart';
import '../screens/startup/startup_screen.dart';

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
  // Screens 08 (verify code) and 09 (create new password) are deliberately
  // absent. They were built from the design deck against a custom
  // verification-code reset that was never implemented: the code screen
  // accepted any six characters without checking them, and "Save new
  // password" navigated to sign-in without changing any password. Reset is
  // done by Firebase Auth's own emailed link (see
  // AuthService.sendPasswordResetEmail), which is the flow the app actually
  // ships — so the two screens claimed an outcome that never happened and
  // are gone rather than hidden.

  // Assessment ----------------------------------------------------------
  static const consent = '/consent'; // 10
  static const ownerInfo = '/owner-info'; // 11
  static const petInfo = '/pet-info'; // 12
  static const quiz = '/quiz'; // 13–21
  static const scoring = '/scoring'; // 22
  static const report = '/report'; // 23
  static const startup = '/startup';

  /// A stored report card — `$report/history/:identity`. Design screen 32b.
  ///
  /// Addressed by [QuizProvider.identityOf], not by list position. The index
  /// this used to carry pointed into `assessmentHistory`, which is filtered
  /// to the active pet and re-sorted and trimmed underneath any link built
  /// from it — so a report opened from a non-active pet's profile resolved
  /// to another animal's record, or to nothing at all.
  static String pastReport(String identity) =>
      '$report/history/${Uri.encodeComponent(identity)}';
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

  /// One pet's report history — `$pets/:index/reports`.
  ///
  /// A pushed route of its own rather than a link to the [reportHistory]
  /// tab. That tab is a [StatefulShellRoute] branch, and pushing a branch
  /// route onto the root navigator puts a second shell on the stack: the
  /// indexed stack then resets to whichever branch was actually selected —
  /// Account, for anyone arriving from a pet profile — and leaves the branch
  /// navigator in a state no further navigation recovers from without
  /// relaunching the app.
  static String petReports(int index) => '$pets/$index/reports';
  static const orders = '/account/orders';

  /// Saved delivery addresses (design 33d), plus the add/edit form. The
  /// list is what checkout and account settings link to; the form is
  /// reached from it.
  static const addresses = '/account/addresses';
  static const addressNew = '/account/addresses/new';

  static String addressEdit(String id) => '$addresses/$id/edit';

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

  /// Whether the catalogue may be browsed.
  ///
  /// Browsing and buying are separate gates because they carry different
  /// risks. Reading the catalogue is honest: the products are real Firestore
  /// documents, the prices are the real prices, and nothing is promised to
  /// anyone by looking at them. So this is open.
  static const bool shopBrowsable = true;

  /// Whether an order can actually be placed.
  ///
  /// Closed, and it must stay closed until orders have somewhere to go.
  /// There is nothing behind checkout: no order is written anywhere, no
  /// payment is taken, and the reference number on the success screen is
  /// generated on the device from the clock. Opening this would tell a
  /// customer their order was placed when nothing recorded it and nothing
  /// was charged — which is a false statement to a real person, not a
  /// missing feature.
  ///
  /// The gate lives here, on the routes, rather than on the Shop tab,
  /// because checkout is reachable from the cart, and the cart from product
  /// detail, which is itself reachable from the home dashboard's
  /// recommendations and from report history. A tab-level gate would leave
  /// the same checkout two taps away by another path.
  ///
  /// Nothing is deleted: flip this to true when orders have somewhere to go
  /// and the whole flow returns.
  static const bool shopEnabled = false;

  /// What stands in for the buying screens while [shopEnabled] is false.
  ///
  /// Deliberately worded about *ordering* rather than about the shop as a
  /// whole: the catalogue is right there behind this screen, so telling
  /// someone the store has not opened would contradict what they can see.
  static Widget _checkoutClosed() => const ComingSoonScreen(
    title: 'Checkout',
    detail:
        'Ordering is not open yet — browsing, your pets, assessments '
        'and reports all work as usual.',
  );

  /// Routes reachable without a signed-in user.
  static const _publicRoutes = <String>{
    welcome,
    onboarding,
    signIn,
    signUp,
    forgotPassword,
  };

  static final _shellKey = GlobalKey<NavigatorState>();

  /// Routes that may not be entered until consent has been signed.
  ///
  /// Consent gates creating a pet and taking an assessment — the two places
  /// data is actually collected — rather than gating sign-in. Someone who
  /// already has a pet on file has consented at some point and is never
  /// asked again; editing a saved pet is deliberately absent for the same
  /// reason.
  static const _consentRequired = <String>{petInfo, addPet, quiz};

  /// Whether [location] may only be entered with consent on record.
  ///
  /// Exposed for the same reason [landingFor] is: the decision worth pinning
  /// down is *which* routes are gated, and that should be assertable without
  /// standing up a router and a widget tree to reach it.
  @visibleForTesting
  static bool requiresConsent(String location) =>
      _consentRequired.contains(location);

  /// The consent form, carrying where to continue once it is signed.
  ///
  /// The gate replaces the location rather than stacking on it, so the
  /// destination has to travel with the redirect — otherwise signing the
  /// form would strand the user with nowhere to go back to.
  static String consentThen(String next) =>
      '$consent?next=${Uri.encodeComponent(next)}';

  /// Where a restored user belongs: the owner record, then at least one pet,
  /// then the app.
  ///
  /// Takes two booleans rather than the providers so the decision is a pure
  /// function — the thing most worth pinning down here is the *order*, and
  /// that should be assertable without standing up Firestore-backed
  /// providers to reach it.
  ///
  /// Consent is deliberately not one of them. It used to lead this ladder,
  /// which meant a returning user was sent to a form they had already signed
  /// before they could reach anything. It is a route guard now — see
  /// [_consentRequired] — so it is asked for at the point it is needed and
  /// never on the way in.
  ///
  /// Also not gated on having completed an assessment, though the state is
  /// available. The dashboard already has a "not assessed yet" state that
  /// invites one, and routing on it would strand someone with no way into
  /// the rest of the app until they had answered 45 questions.
  @visibleForTesting
  static String landingFor({required bool hasOwner, required bool hasPet}) {
    if (!hasOwner) return ownerInfo;
    if (!hasPet) return petInfo;
    return home;
  }

  static GoRouter build({
    required AuthProvider authProvider,
    required OnboardingProvider onboardingProvider,
    required AppStartupProvider appStartupProvider,
    required PetInfoProvider petInfoProvider,
  }) {
    return GoRouter(
      initialLocation: welcome,
      navigatorKey: _shellKey,
      // petInfoProvider is read by the redirect but deliberately not listened
      // to. Its contents only decide a landing destination, which is settled
      // by the time startup reports ready; subscribing would re-run the
      // redirect on every pet edit for no routing benefit.
      refreshListenable: Listenable.merge([
        authProvider,
        onboardingProvider,
        appStartupProvider,
      ]),
      redirect: (context, state) {
        final location = state.matchedLocation;

        // Hold still until persisted state has loaded, so the first frame
        // doesn't bounce the user through /sign-in on its way to /home.
        if (!authProvider.isLoaded || !onboardingProvider.isLoaded) {
          return null;
        }

        if (!onboardingProvider.isComplete) {
          if (location == welcome || location == onboarding) return null;
          return onboarding;
        }

        if (!authProvider.isSignedIn) {
          // /startup means nothing signed out — it would sit there loading
          // data for nobody.
          return _publicRoutes.contains(location) ? null : signIn;
        }

        // Signed in, but this account's data has not been restored yet.
        // Every entry point funnels through the one screen that does it:
        // cold launch, email sign-in, Google sign-in, restart.
        if (appStartupProvider.stage != StartupStage.ready) {
          return location == startup ? null : startup;
        }

        // Consent, asked for where it is actually needed. A landing on
        // /pet-info passes through here on the next pass and is turned into
        // the form, so the first run still collects it — but nobody is asked
        // merely for signing in.
        if (_consentRequired.contains(location) &&
            !petInfoProvider.consentGiven) {
          return consentThen(location);
        }

        // Restored. Anyone still sitting on an entry route gets placed;
        // anywhere else is left alone, so this never yanks someone out of a
        // screen they navigated to themselves.
        if (location == startup || _publicRoutes.contains(location)) {
          return landingFor(
            hasOwner: petInfoProvider.ownerInfo != null,
            hasPet: petInfoProvider.pets.isNotEmpty,
          );
        }
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
          path: startup,
          builder: (context, state) => const StartupScreen(),
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

        // ---- Assessment -------------------------------------------------
        GoRoute(
          path: consent,
          builder: (context, state) =>
              ConsentScreen(next: state.uri.queryParameters['next']),
        ),
        GoRoute(
          path: ownerInfo,
          builder: (context, state) => const OwnerInfoScreen(),
        ),
        GoRoute(
          path: petInfo,
          builder: (context, state) => const PetInfoScreen(),
        ),
        GoRoute(path: quiz, builder: (context, state) => const QuizScreen()),
        GoRoute(
          path: scoring,
          builder: (context, state) => const ScoringScreen(),
        ),
        GoRoute(
          path: report,
          builder: (context, state) => const ReportCardScreen(),
          routes: [
            GoRoute(
              path: 'history/:identity',
              builder: (context, state) => ReportCardScreen(
                reportIdentity: Uri.decodeComponent(
                  state.pathParameters['identity'] ?? '',
                ),
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
          builder: (context, state) => shopBrowsable
              ? ProductDetailScreen(productId: state.pathParameters['id']!)
              : _checkoutClosed(),
        ),
        // The cart is a browsing surface: it holds a selection and totals it
        // up, and nothing in it commits the user to anything. Checkout below
        // is where the promise would be made, and that is what stays shut.
        GoRoute(
          path: cart,
          builder: (context, state) =>
              shopBrowsable ? const CartScreen() : _checkoutClosed(),
        ),
        GoRoute(
          path: checkout,
          builder: (context, state) =>
              shopEnabled ? const CheckoutScreen() : _checkoutClosed(),
        ),
        GoRoute(
          path: orderSuccess,
          builder: (context, state) =>
              shopEnabled ? const OrderSuccessScreen() : _checkoutClosed(),
        ),
        GoRoute(
          path: orderTracking,
          builder: (context, state) => shopEnabled
              ? OrderTrackingScreen(order: state.extra as OrderReference?)
              : _checkoutClosed(),
        ),
        GoRoute(
          path: support,
          builder: (context, state) => const SupportScreen(),
        ),

        // ---- Account stack ----------------------------------------------
        GoRoute(path: inbox, builder: (context, state) => const InboxScreen()),
        GoRoute(path: pets, builder: (context, state) => const MyPetsScreen()),
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
            GoRoute(
              path: 'reports',
              builder: (context, state) => ReportHistoryScreen(
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
          path: addresses,
          builder: (context, state) => const AddressListScreen(),
        ),
        // Declared before ':id' so "new" isn't swallowed as an id.
        GoRoute(
          path: addressNew,
          builder: (context, state) => const AddressScreen(),
        ),
        GoRoute(
          path: '$addresses/:id/edit',
          builder: (context, state) =>
              AddressScreen(addressId: state.pathParameters['id']),
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
                  builder: (context, state) =>
                      shopBrowsable ? const ShopScreen() : _checkoutClosed(),
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
