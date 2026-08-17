import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/composition.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/pet_info_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/product_provider.dart';
import 'providers/app_startup_provider.dart';
import 'providers/reminders_provider.dart';
import 'services/crash_reporter.dart';
import 'services/reminder_gateway.dart';
import 'services/reminder_schedule.dart';
import 'services/reminder_scheduler.dart';
import 'providers/firebase_startup_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase comes up before the first frame, and its outcome is carried in
  // the tree rather than swallowed. This used to be a try/catch whose only
  // response was a debugPrint behind kDebugMode: in release the failure was
  // invisible and the app launched anyway, into a state where every account
  // operation throws deep inside a provider. See [FirebaseStartupProvider].
  final firebaseStartup = FirebaseStartupProvider();
  await firebaseStartup.connect();

  // Crash reporting is a Firebase product, so it goes up after Firebase and
  // only if Firebase came up. An app that cannot report is worse than one
  // that cannot start, so this is never allowed to be a launch blocker: when
  // the connection failed, the app runs without reporting and shows the
  // recovery screen instead.
  if (firebaseStartup.isReady) {
    CrashReporter.install();
  }

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
  // Built by [AppComposition] rather than inline, so the choice of repository
  // is a named, testable decision. The account-backed repository keeps the
  // device copy as an offline cache; AppStartupProvider re-reads it once a
  // session exists, because the read below happens before sign-in and can
  // only reach that cache.
  final addressProvider = AppComposition.addressProvider();
  final themeProvider = ThemeProvider();
  final productProvider = ProductProvider();
  final appStartupProvider = AppStartupProvider();
  final remindersProvider = RemindersProvider();
  // The gateway is the only part that touches the notification plugin, so
  // the unsupported platforms get an inert one rather than a conditional at
  // every call site.
  final reminderScheduler = ReminderScheduler(
    remindersSupported
        ? LocalNotificationGateway()
        : const NoopReminderGateway(),
  );

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
        ChangeNotifierProvider.value(value: appStartupProvider),
        ChangeNotifierProvider.value(value: firebaseStartup),
        ChangeNotifierProvider.value(value: remindersProvider),
        Provider<ReminderScheduler>.value(value: reminderScheduler),
      ],
      child: const MyPetFitApp(),
    ),
  );

  // Assessment results are stored per pet, so the quiz has to know which pet
  // is active. Wired here rather than inside either provider so the
  // dependency is visible in one place: pets own the selection, the quiz
  // follows it.
  void bindActivePet() => quizProvider.bindPet(petInfoProvider.activePet?.id);
  petInfoProvider.addListener(bindActivePet);

  // The cart persists product ids, not products, so a restored cart is only
  // rows-in-waiting until the Firestore catalog lands. Wired here for the
  // same reason as the pet binding above — the dependency between the two
  // providers is visible in one place rather than buried in either of them.
  void hydrateCart() => cartProvider.hydrate(productProvider.products);
  productProvider.addListener(hydrateCart);

  // Reminders are derived state, never state of their own: what the OS holds
  // is recomputed from the preference, the pets and their latest results
  // whenever any of the three changes. Wired here for the same reason as the
  // two above — the dependency between them is visible in one place.
  //
  // Turning the preference off produces an empty plan, which cancels
  // everything pending. That is what makes disabling a reminder actually
  // stop it rather than only hiding the switch.
  void syncReminders() {
    reminderScheduler.apply(
      planRetakeReminders(
        enabled: remindersProvider.assessmentRetake,
        pets: petInfoProvider.pets,
        latestFor: quizProvider.resultFor,
        now: DateTime.now(),
      ),
    );
  }

  remindersProvider.addListener(syncReminders);
  petInfoProvider.addListener(syncReminders);
  quizProvider.addListener(syncReminders);

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
    // Reconciles once the stored preference is known. Nothing is scheduled
    // before this lands: the default is off, and the listener above only
    // fires on a change.
    remindersProvider.init().then((_) => syncReminders());
    // Products are loaded from Firestore, which is async, so the provider is
    // constructed synchronously with an empty list and the load is kicked off
    // here. The provider calls notifyListeners() when the load completes so
    // the UI rebuilds automatically.
    productProvider.loadProducts();
  });
}
