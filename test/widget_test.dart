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
import 'package:mypetfit_app/providers/theme_provider.dart';

void main() {
  testWidgets('App launches with welcome screen showing logo and Get Started',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PetInfoProvider()),
          ChangeNotifierProvider(create: (_) => QuizProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ],
        child: const MyPetFitApp(),
      ),
    );

    // The "Get Started" CTA should be visible.
    expect(find.text('Get Started'), findsOneWidget);

    // The logo is rendered as an Image widget loading the PNG asset.
    final imageFinder = find.byWidgetPredicate((widget) {
      if (widget is! Image) return false;
      final provider = widget.image;
      if (provider is AssetImage) {
        return provider.assetName.contains('mypetfit_logo');
      }
      return false;
    });
    expect(imageFinder, findsOneWidget);
  });
}
