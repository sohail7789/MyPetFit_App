import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';

/// Screen 23b — shown instead of the report card when the score lands in the
/// Critical band.
class VetAlertScreen extends StatelessWidget {
  const VetAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), AppTheme.bandCriticalTint],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: DesignImage(
                    AppAssets.vetAlert,
                    width: 230,
                    shadow: true,
                    semanticLabel: 'Concerned puppy',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Let's get a vet involved",
                  textAlign: TextAlign.center,
                  style: AppTheme.h1.copyWith(fontSize: 26, letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                Text(
                  'Some answers suggest your pet needs professional attention '
                  "soon. This isn't a diagnosis — but a check-up this week is "
                  'the right next step.',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    size: 14.5,
                    color: AppTheme.bodyStrong,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 26),
                AppButton(
                  label: 'Find a vet near me',
                  variant: AppButtonVariant.danger,
                  height: AppTheme.ctaHeightCompact,
                  icon: const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'View the full report',
                  variant: AppButtonVariant.outline,
                  height: 52,
                  onPressed: () => context.pushReplacement(AppRoutes.report),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

