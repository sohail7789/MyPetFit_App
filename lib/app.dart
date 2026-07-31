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
    // Build the router once with the live providers. The router listens to
    // both providers itself (refreshListenable) and re-evaluates redirects
    // whenever either notifies.
    _router = AppRoutes.build(
      authProvider: context.read<AuthProvider>(),
      onboardingProvider: context.read<OnboardingProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'MyPetFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.mode,
      routerConfig: _router,
    );
  }
}
