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
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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

  Future<void> _sendResetLink() async {
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final email = _email.text.trim();

      if (email.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter your email address.'),
          ),
        );
        return;
      }

      // Deliberately no "is this address registered?" pre-check.
      //
      // There used to be one, and it queried the `users` collection by
      // email. Two things were wrong with it. It was an anonymous
      // enumeration oracle — the caller is signed out on this screen, so
      // anyone could confirm whether an address had a MyPetFit account. And
      // it required the `users` collection to be listable by an
      // unauthenticated client, which is exactly the access the production
      // Firestore rules are being tightened to remove.
      //
      // It was also redundant: Firebase Auth already decides whether an
      // address can be sent a reset link, and reports it through
      // sendPasswordResetEmail. Ask the authority directly.
      await authProvider.sendPasswordResetEmail(email);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. Please check your inbox.',
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      router.go(AppRoutes.signIn);



    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
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
    return AuthArtLayout(
      gradient: [
        context.c.surface,
        context.c.surfaceLow,
        context.c.surfaceRaised,
      ],
      decoration: [
        PawWatermark(
          bottom: 96,
          left: -10,
          size: 76,
          color: context.c.actionText,
          opacity: 0.07,
          rotationDegrees: -22,
        ),
        PawWatermark(
          bottom: 180,
          right: 16,
          size: 50,
          color: context.c.actionText,
          opacity: 0.07,
          rotationDegrees: 16,
        ),
      ],
      title: 'Forgot Password?',
      subtitle: Text(
        "No worries! Enter your email address and we'll send you a link to reset it.",
        textAlign: TextAlign.center,
        style: context.t.bodyText,
      ),
      art: AppAssets.forgotPassword,
      artWidth: 334,
      artLabel: 'Puppy holding an envelope',
      onBack: () => context.backOr(AppRoutes.signIn),
      children: [
        AppField(
          hint: 'Email address',
          icon: AppIcon(AppIcons.mail(context.c.muted), size: 20),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.done,
          height: 58,
        ),
        const SizedBox(height: 18),
        AppButton(
          label: 'Send Reset Link',
          icon: AppIcon(AppIcons.send(), size: 19),
          onPressed: _sendResetLink,
        ),
        const SizedBox(height: 22),
        BackToLogin(onTap: () => context.go(AppRoutes.signIn)),
      ],
    );
  }
}
