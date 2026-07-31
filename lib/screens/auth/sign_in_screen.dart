import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/floating_paws_background.dart';
import '../../widgets/mypetfit_logo.dart';
import '../../widgets/primary_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _submitting = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await context.read<AuthProvider>().signIn(
          _usernameController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    context.go(AppRoutes.consent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppTheme.mutedText(isDark);

    return Scaffold(
      body: FloatingPawsBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  // The logo PNG is a full lockup (mark + wordmark +
                  // tagline); at 56px it collapsed into an illegible smudge.
                  // The text wordmark stays crisp and is theme-aware.
                  const MyPetFitLogo.compact(fontSize: 22),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    'Welcome back.',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppTheme.heading(isDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sign in to continue where you left off.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: AuthValidators.username,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: AuthValidators.password,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.interactive(isDark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Sign in',
                    onPressed: _submitting ? null : _submit,
                    isLoading: _submitting,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Row(
                    children: [
                      Expanded(child: Divider(color: muted.withValues(alpha: 0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'or',
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                      Expanded(child: Divider(color: muted.withValues(alpha: 0.2))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                      icon: Text(
                        'G',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.interactive(isDark),
                        ),
                      ),
                      label: Text(
                        'Continue with Google',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.heading(isDark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style:
                              theme.textTheme.bodyMedium?.copyWith(color: muted),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.signUp),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign up',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.interactive(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
