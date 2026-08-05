import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';

class MyPetFitApp extends StatefulWidget {
  const MyPetFitApp({super.key});

  @override
  State<MyPetFitApp> createState() => _MyPetFitAppState();
}

class _MyPetFitAppState extends State<MyPetFitApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once with the live providers. The router listens to both itself
    // (refreshListenable) and re-evaluates redirects whenever either notifies.
    _router = AppRoutes.build(
      authProvider: context.read<AuthProvider>(),
      onboardingProvider: context.read<OnboardingProvider>(),
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
