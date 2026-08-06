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
import '../../widgets/password_strength.dart';
import '../../widgets/paw_mark.dart';
import '../../widgets/screen_backdrop.dart';
import '../../widgets/social_buttons.dart';

/// Screen 06 — Create Account.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_first, _last, _username, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _signUp() async {
    try {
      await context.read<AuthProvider>().signUp(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully'),
        ),
      );
      // No navigation here either. A new account has no consent, owner or
      // pet, so the router's own landing decision sends them to /consent —
      // the same place, without racing the redirect.
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackdrop(
        colors: [
          context.c.surface,
          context.c.surfaceLow,
          context.c.surfaceRaised,
        ],
        stops: const [0, 0.62, 1],
        decoration: [
          PawWatermark(
            top: 96,
            right: -10,
            size: 66,
            color: context.c.startLight,
            opacity: 0.1,
            rotationDegrees: 16,
          ),
          Positioned(
            bottom: 6,
            right: -6,
            child: IgnorePointer(
              child: DesignImage(
                AppAssets.signUp,
                width: 186,
                shadow: true,
                semanticLabel: 'Puppy resting with a ball',
              ),
            ),
          ),
        ],
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          size: 44,
                          floating: true,
                          semanticLabel: 'Back',
                          onPressed: () => context.go(AppRoutes.onboarding),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Create Account',
                        style: context.t.h1.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 274),
                        child: Text(
                          'Join MyPetFit and give your pet the best care possible.',
                          style: context.t.bodyText.copyWith(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: AppField(
                              hint: 'First name',
                              icon: AppIcon(AppIcons.person(context.c.muted), size: 18),
                              controller: _first,
                              height: AppTheme.fieldHeightCompact,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              hint: 'Last name',
                              controller: _last,
                              height: AppTheme.fieldHeightCompact,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppField(
                        hint: 'Username',
                        icon: AppIcon(AppIcons.username(context.c.muted), size: 19),
                        controller: _username,
                        height: AppTheme.fieldHeightCompact,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppField(
                        hint: 'Email address',
                        icon: AppIcon(AppIcons.mail(context.c.muted), size: 20),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        height: AppTheme.fieldHeightCompact,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppField(
                        hint: 'Password',
                        icon: AppIcon(AppIcons.lock(context.c.muted), size: 19),
                        controller: _password,
                        obscure: _obscure,
                        height: AppTheme.fieldHeightCompact,
                        onChanged: (_) => setState(() {}),
                        trailing: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: AppIcon(
                            _obscure ? AppIcons.eyeOff(context.c.muted) : AppIcons.eye(context.c.muted),
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PasswordStrength.of(_password.text),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Sign Up',
                        variant: AppButtonVariant.start,
                        onPressed: _signUp,
                      ),
                      const SizedBox(height: 18),
                      const OrDivider(),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SocialRow(height: 52, maxWidth: 210),
                      ),
                      const SizedBox(height: 18),
                      // The puppy sits bottom-right, so this copy is kept
                      // narrow and left-aligned to clear it.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 198),
                        child: InlineLink(
                          prefix: 'Already have an account?\n',
                          action: 'Log in',
                          align: TextAlign.left,
                          onTap: () => context.go(AppRoutes.signIn),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
