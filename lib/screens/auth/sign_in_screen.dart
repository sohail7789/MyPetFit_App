import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/design_image.dart';
import '../../widgets/language_picker.dart';
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

  /// Authenticates. Nothing else.
  ///
  /// No loading and no navigation: AuthProvider notifying is what moves the
  /// router, which sends us to /startup and on from there. Doing the loading
  /// here and then calling context.go raced that redirect and navigated
  /// twice — and it always landed on /consent, so returning users were sent
  /// back through a step they had already completed.
  Future<void> _signIn() async {
    try {
      await context.read<AuthProvider>().signIn(
            _email.text.trim(),
            _password.text,
          );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }


  /// As with [_signIn] — authenticate, then let the router take over.
  Future<void> _signInWithGoogle() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _signInWithApple() async {
    try {
      await context.read<AuthProvider>().signInWithApple();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: Stack(
        children: [
          HeroPanel(
            height: 340,
            colors: [
              context.c.meterTrack,
              context.c.surfaceRaised,
              context.c.surface,
            ],
          ),
          PawWatermark(
            top: 96,
            left: 22,
            size: 62,
            color: context.c.actionText,
            opacity: 0.12,
            rotationDegrees: -14,
          ),
          PawWatermark(
            top: 206,
            left: -6,
            size: 44,
            color: context.c.actionText,
            opacity: 0.1,
            rotationDegrees: 18,
          ),
          Positioned(
            top: 60,
            right: 96,
            child: AppIcon(AppIcons.heart(context.c.actionText, 0.16), size: 26),
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
                              style: context.t.h1,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Login to continue your pet's health journey",
                              textAlign: TextAlign.center,
                              style: context.t.bodyText.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            AppField(
                              hint: 'Email address',
                              icon: AppIcon(AppIcons.mail(context.c.muted), size: 20),
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            AppField(
                              hint: 'Password',
                              icon: AppIcon(AppIcons.lock(context.c.muted), size: 19),
                              controller: _password,
                              obscure: _obscure,
                              textInputAction: TextInputAction.done,
                              trailing: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: AppIcon(
                                  _obscure
                                      ? AppIcons.eyeOff(context.c.muted)
                                      : AppIcons.eye(context.c.muted),
                                  size: 20,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(2, 16, 2, 22),
                              // Wrap, not Row: at larger font scales the two
                              // labels no longer fit on one line, and a Row
                              // overflows them into each other ("Remember
                              // meForgot password?"). This spaces them apart
                              // when they fit and stacks them when they don't.
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _RememberMe(
                                    value: _remember,
                                    onChanged: (v) =>
                                        setState(() => _remember = v),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        context.push(AppRoutes.forgotPassword),
                                    child: Text(
                                      'Forgot password?',
                                      style: AppTheme.font(
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: context.c.actionText,
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
                            SocialRow(
                              onGoogle: _signInWithGoogle,
                              onApple: _signInWithApple,
                            ),
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
              color: value ? context.c.action : context.c.surface,
              borderRadius: BorderRadius.circular(6),
              border: value ? null : Border.all(color: context.c.dotInactive),
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
              color: context.c.bodyStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating white language selector. Opens the same sheet as the Language
/// row in account settings, so the two always show the same choice.
class _LanguageChip extends StatelessWidget {
  const _LanguageChip();

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleProvider>().current;

    return Semantics(
      button: true,
      label: 'Language: ${language.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showLanguagePicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: context.c.floatShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(AppIcons.globe(context.c.actionText), size: 15),
              const SizedBox(width: 6),
              Text(
                language.glyph,
                style: AppTheme.font(
                  size: 13,
                  weight: FontWeight.w700,
                  color: context.c.ink,
                ),
              ),
              const SizedBox(width: 6),
              AppIcon(AppIcons.chevronDown(context.c.muted), size: 11),
            ],
          ),
        ),
      ),
    );
  }
}
