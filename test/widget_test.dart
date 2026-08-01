import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mypetfit_app/app.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/dashboard_provider.dart';
import 'package:mypetfit_app/providers/onboarding_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';

Widget _bootApp() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetInfoProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: const MyPetFitApp(),
    );

void main() {
  testWidgets('App boots to the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(_bootApp());
    await tester.pump();

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
