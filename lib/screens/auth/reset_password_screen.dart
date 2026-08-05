import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/password_strength.dart';
import 'widgets/auth_art_layout.dart';

/// Screen 09 — Create new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _password.text.isNotEmpty && _password.text == _confirm.text;

  @override
  Widget build(BuildContext context) {
    return AuthArtLayout(
      gradient: [
        context.c.surface,
        context.c.surfaceLow,
        context.c.surfaceRaised,
      ],
      title: 'Create new password',
      subtitle: Text(
        "Make it strong — Bruno's health history lives behind it.",
        textAlign: TextAlign.center,
        style: context.t.bodyText,
      ),
      art: AppAssets.resetPassword,
      artWidth: 280,
      artLabel: 'Playful puppy',
      onBack: () => context.backOr(AppRoutes.signIn),
      children: [
        AppField(
          hint: 'New password',
          icon: AppIcon(AppIcons.lock(context.c.muted), size: 19),
          controller: _password,
          obscure: _obscure,
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
        AppField(
          hint: 'Confirm password',
          icon: AppIcon(AppIcons.lock(context.c.muted), size: 19),
          controller: _confirm,
          obscure: _obscure,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        PasswordStrength.of(_password.text),
        const SizedBox(height: 18),
        AppButton(
          label: 'Save new password',
          onPressed: _canSave ? () => context.go(AppRoutes.signIn) : null,
        ),
        const SizedBox(height: 14),
        BackToLogin(onTap: () => context.go(AppRoutes.signIn)),
      ],
    );
  }
}
