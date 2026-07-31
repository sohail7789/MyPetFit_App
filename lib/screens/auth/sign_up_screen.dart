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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _submitting = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await context.read<AuthProvider>().signUp(
          username: _usernameController.text,
          email: _emailController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          password: _passwordController.text,
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
                    'Create your\naccount.',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppTheme.heading(isDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'It only takes a minute.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: AppSpacing.section),
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'First name',
                          ),
                          validator: (v) => AuthValidators.required(v,
                              field: 'First name'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Last name',
                          ),
                          validator: (v) =>
                              AuthValidators.required(v, field: 'Last name'),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Sign up',
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
                          'Already have an account? ',
                          style:
                              theme.textTheme.bodyMedium?.copyWith(color: muted),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.signIn),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign in',
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
