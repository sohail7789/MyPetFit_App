import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/paw_mark.dart';
import 'widgets/auth_art_layout.dart';

/// Screen 07 — Forgot password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthArtLayout(
      gradient: const [
        Color(0xFFFFFFFF),
        Color(0xFFFBFAFD),
        Color(0xFFF2EFF7),
      ],
      decoration: const [
        PawWatermark(
          bottom: 96,
          left: -10,
          size: 76,
          color: AppTheme.action,
          opacity: 0.07,
          rotationDegrees: -22,
        ),
        PawWatermark(
          bottom: 180,
          right: 16,
          size: 50,
          color: AppTheme.action,
          opacity: 0.07,
          rotationDegrees: 16,
        ),
      ],
      title: 'Forgot Password?',
      subtitle: Text(
        "No worries! Enter your email address and we'll send you a link to reset it.",
        textAlign: TextAlign.center,
        style: AppTheme.bodyText,
      ),
      art: AppAssets.forgotPassword,
      artWidth: 334,
      artLabel: 'Puppy holding an envelope',
      onBack: () => context.pop(),
      children: [
        AppField(
          hint: 'Email address',
          icon: AppIcon(AppIcons.mail(), size: 20),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          height: 58,
        ),
        const SizedBox(height: 18),
        AppButton(
          label: 'Send Reset Link',
          icon: AppIcon(AppIcons.send(), size: 19),
          onPressed: () => context.push(AppRoutes.verifyCode),
        ),
        const SizedBox(height: 22),
        BackToLogin(onTap: () => context.go(AppRoutes.signIn)),
      ],
    );
  }
}
