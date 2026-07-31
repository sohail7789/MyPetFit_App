import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/blob_background.dart';
import '../../widgets/primary_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlobBackground(
        variant: BlobVariant.scattered,
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xxl + 4),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo/mypetfit_logo.png',
                          width: 176,
                          height: 176,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 176,
                            height: 176,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl + 4),
                        Text(
                          'Your pet, better\nunderstood.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: AppTheme.heading(isDark),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Text(
                            'A gentle daily read on your best friend’s health — assessments, insights, and everything they need in one place.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText(isDark),
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Get Started',
                        onPressed: () => context.go(AppRoutes.onboarding),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.signIn),
                        child: Text(
                          'I already have an account',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.interactive(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
