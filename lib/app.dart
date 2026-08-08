import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_startup_provider.dart';
import 'providers/firebase_startup_provider.dart';
import 'providers/pet_info_provider.dart';
import 'screens/startup/firebase_unavailable_screen.dart';

/// The app, gated on Firebase actually being available.
///
/// The gate sits here rather than in the router: [AppRoutes] redirects on
/// account state, and a failure that happens before any account can be read
/// is not a navigation decision. Wrapping keeps the routing architecture
/// untouched and means the router is never built over a Firebase that is not
/// there.
class MyPetFitApp extends StatelessWidget {
  const MyPetFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseStartupProvider>();

    if (firebase.hasFailed) {
      return MaterialApp(
        title: 'MyPetFit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: context.watch<ThemeProvider>().mode,
        home: FirebaseUnavailableScreen(onRetry: firebase.connect),
      );
    }

    return const _RoutedApp();
  }
}

class _RoutedApp extends StatefulWidget {
  const _RoutedApp();

  @override
  State<_RoutedApp> createState() => _MyPetFitAppState();
}

class _MyPetFitAppState extends State<_RoutedApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once with the live providers. The router listens to both itself
    // (refreshListenable) and re-evaluates redirects whenever either notifies.
    _router = AppRoutes.build(
      authProvider: context.read<AuthProvider>(),
      onboardingProvider: context.read<OnboardingProvider>(),
      appStartupProvider: context.read<AppStartupProvider>(),
      petInfoProvider: context.read<PetInfoProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watched rather than read: selecting an appearance in settings has to
    // repaint the whole app, and ThemeMode.system needs MaterialApp to stay
    // subscribed to platform brightness changes.
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp.router(
      title: 'MyPetFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      // Android's Display size and Font size settings both feed textScaler,
      // and Samsung's One UI ships several steps above 1.0. Every layout here
      // flexes, but past ~1.3 the dense screens (assessment options, product
      // grid) stop being readable rather than merely tall — so honour the
      // user's preference up to that point and hold there.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
