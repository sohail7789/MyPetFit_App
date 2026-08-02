import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import '../../widgets/paw_mark.dart';
import '../../widgets/screen_backdrop.dart';
import '../../widgets/social_buttons.dart';

/// Screen 01 — Welcome.
///
/// The design plays a looping clip here. WebM plays on Android and web; iOS
/// has no WebM decoder, so it shows the `running.png` still until the
/// `.mov` encode is supplied.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackdrop(
        colors: const [Color(0xFFFFFFFF), Color(0xFFFAF9FC), Color(0xFFEFECF5)],
        stops: const [0, 0.48, 1],
        decoration: const [
          PawWatermark(
            top: 78,
            left: -14,
            size: 86,
            color: AppTheme.action,
            opacity: 0.07,
            rotationDegrees: -18,
          ),
          PawWatermark(
            top: 150,
            right: 14,
            size: 54,
            color: AppTheme.startLight,
            opacity: 0.08,
            rotationDegrees: 14,
          ),
        ],
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: DesignImage(
                  AppAssets.logo,
                  width: 200,
                  semanticLabel:
                      'MyPetFit — Intelligent Care for Lifelong Pet Health',
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      // Held on the still until an opaque re-export lands:
                      // video_player renders Android video onto an opaque
                      // surface, so the clip's alpha composites to black.
                      // Same 306 width as the clip, so nothing shifts when
                      // it is swapped back.
                      child: DesignImage(
                        AppAssets.welcomePoster,
                        width: 306,
                        shadow: true,
                        semanticLabel: 'A puppy running',
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome!',
                      textAlign: TextAlign.center,
                      style: AppTheme.h1Welcome,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Let's keep your pet healthy, happy\nand full of energy.",
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyText,
                    ),
                    const SizedBox(height: 26),
                    AppButton(
                      label: 'Get Started',
                      variant: AppButtonVariant.start,
                      onPressed: () => context.go(AppRoutes.onboarding),
                    ),
                    const SizedBox(height: 20),
                    InlineLink(
                      prefix: 'Already have an account?',
                      action: 'Log in',
                      onTap: () => context.go(AppRoutes.signIn),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
