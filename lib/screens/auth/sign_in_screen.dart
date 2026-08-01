import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/design_image.dart';
import '../../widgets/paw_mark.dart';
import '../../widgets/screen_backdrop.dart';
import '../../widgets/social_buttons.dart';

/// Screen 05 — Sign in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    await context.read<AuthProvider>().signIn(
          _email.text.trim(),
          _password.text,
        );
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          const HeroPanel(
            height: 340,
            colors: [Color(0xFFE5E1F1), Color(0xFFF2EFF8), Color(0xFFFFFFFF)],
          ),
          const PawWatermark(
            top: 96,
            left: 22,
            size: 62,
            color: AppTheme.action,
            opacity: 0.12,
            rotationDegrees: -14,
          ),
          const PawWatermark(
            top: 206,
            left: -6,
            size: 44,
            color: AppTheme.action,
            opacity: 0.1,
            rotationDegrees: 18,
          ),
          Positioned(
            top: 60,
            right: 96,
            child: AppIcon(AppIcons.heart(AppTheme.action, 0.16), size: 26),
          ),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 246,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: DesignImage(
                            AppAssets.signIn,
                            width: 300,
                            shadow: true,
                            semanticLabel: 'Waving golden puppy',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 14, 26, 34),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome Back! 👋',
                              textAlign: TextAlign.center,
                              style: AppTheme.h1,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Login to continue your pet's health journey",
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyText.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            AppField(
                              hint: 'Email address',
                              icon: AppIcon(AppIcons.mail(), size: 20),
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            AppField(
                              hint: 'Password',
                              icon: AppIcon(AppIcons.lock(), size: 19),
                              controller: _password,
                              obscure: _obscure,
                              textInputAction: TextInputAction.done,
                              trailing: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: AppIcon(
                                  _obscure
                                      ? AppIcons.eyeOff()
                                      : AppIcons.eye(),
                                  size: 20,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(2, 16, 2, 22),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _RememberMe(
                                    value: _remember,
                                    onChanged: (v) =>
                                        setState(() => _remember = v),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        context.push(AppRoutes.forgotPassword),
                                    child: Text(
                                      'Forgot password?',
                                      style: AppTheme.font(
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: AppTheme.action,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppButton(label: 'Log In', onPressed: _signIn),
                            const SizedBox(height: 22),
                            const OrDivider(),
                            const SizedBox(height: 16),
                            const SocialRow(),
                            const SizedBox(height: 20),
                            InlineLink(
                              prefix: "Don't have an account?",
                              action: 'Sign up',
                              onTap: () => context.go(AppRoutes.signUp),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(top: 8, right: 24, child: _LanguageChip()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkbox + label. The design shows it checked by default.
class _RememberMe extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RememberMe({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppTheme.action : AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: value ? null : Border.all(color: AppTheme.dotInactive),
            ),
            alignment: Alignment.center,
            child: value ? AppIcon(AppIcons.check(), size: 12) : null,
          ),
          const SizedBox(width: 9),
          Text(
            'Remember me',
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w500,
              color: AppTheme.bodyStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating white "EN" language selector.
class _LanguageChip extends StatelessWidget {
  const _LanguageChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.floatShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.globe(), size: 15),
          const SizedBox(width: 6),
          Text(
            'EN',
            style: AppTheme.font(
              size: 13,
              weight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(width: 6),
          AppIcon(AppIcons.chevronDown(), size: 11),
        ],
      ),
    );
  }
}
