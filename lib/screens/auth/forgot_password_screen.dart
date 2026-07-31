import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/floating_paws_background.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.signIn);
    }
  }

  Future<void> _submit() async {
    // Previously this fired regardless of input — an empty or malformed
    // address would still report "Reset link sent!".
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reset link sent to ${_emailController.text.trim()}'),
      ),
    );
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: FloatingPawsBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // Back control — matches the circular surface button used
                  // on the dashboard rather than a solid navy disc that
                  // fought with the page.
                  _BackButton(isDark: isDark, onTap: _dismiss),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    'Forgot password?',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppTheme.heading(isDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Enter your email and we\'ll send you a link to reset your password.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText(isDark),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Send reset link',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextButton(
                      onPressed: _dismiss,
                      child: Text(
                        'Back to sign in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.interactive(isDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _BackButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(isDark),
      shape: CircleBorder(
        side: BorderSide(color: AppTheme.hairline(isDark), width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: AppTheme.heading(isDark),
          ),
        ),
      ),
    );
  }
}
