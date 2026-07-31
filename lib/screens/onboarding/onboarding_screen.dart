import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/animated_pet_illustration.dart';
import '../../widgets/blob_background.dart';
import '../../widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      scene: PetScene.dogWalking,
      title: 'Pawfect Companions\nAwait.',
      description:
          'Discover adorable dogs ready to join your family. From playful puppies to loyal seniors.',
      pastel: AppTheme.lightAzure,
      accent: AppTheme.primary,
      variant: BlobVariant.topRight,
    ),
    _PageData(
      scene: PetScene.dogWaiting,
      title: 'Premium Dog\nEssentials.',
      description:
          'Shop high-quality food, toys, and accessories tailored for your furry best friend.',
      pastel: AppTheme.softPeach,
      accent: AppTheme.secondary,
      variant: BlobVariant.bottomLeft,
    ),
    _PageData(
      scene: PetScene.dogSuccess,
      title: 'Join the Canine\nCommunity.',
      description:
          'Connect with fellow dog lovers, get expert advice, and make tails wag with joy.',
      pastel: AppTheme.softLavender,
      accent: AppTheme.accentBlue,
      variant: BlobVariant.scattered,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    context.read<OnboardingProvider>().completeOnboarding();
    context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = AppTheme.heading(isDark);
    final descColor = AppTheme.mutedText(isDark);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return BlobBackground(
                variant: page.variant,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                    child: Column(
                      children: [
                        // Balanced spacers keep the illustration optically
                        // centred in the space above the copy. Previously a
                        // fixed 60px top + single Spacer stranded it near the
                        // status bar with a large void beneath.
                        const Spacer(flex: 3),
                        AnimatedPetIllustration(
                          scene: page.scene,
                          size: 220,
                          accent: page.accent,
                          pastel: page.pastel,
                        ),
                        const Spacer(flex: 4),
                        Text(
                          page.title,
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: titleColor,
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.description,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: descColor,
                            letterSpacing: -0.1,
                            height: 1.55,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Reserves room for the pinned dots + button below.
                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Skip button — hidden on the last page since "Get Started"
          // already advances the user.
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: TextButton(
                onPressed: () {
                  context.read<OnboardingProvider>().completeOnboarding();
                  context.go(AppRoutes.signIn);
                },
                child: Text(
                  'SKIP',
                  style: GoogleFonts.inter(
                    color: AppTheme.interactive(isDark),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          // Bottom area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotColor: AppTheme.interactive(isDark).withValues(alpha: 0.22),
                        activeDotColor: AppTheme.interactive(isDark),
                        dotHeight: 7,
                        dotWidth: 7,
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    PrimaryButton(
                      label: _currentPage == _pages.length - 1
                          ? 'Get started'
                          : 'Next',
                      onPressed: _onNext,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final PetScene scene;
  final String title;
  final String description;
  final Color pastel;
  final Color accent;
  final BlobVariant variant;

  const _PageData({
    required this.scene,
    required this.title,
    required this.description,
    required this.pastel,
    required this.accent,
    required this.variant,
  });
}
