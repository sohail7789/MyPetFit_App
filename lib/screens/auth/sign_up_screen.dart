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

  /// One node per field, created once and owned here.
  ///
  /// Focus is handed from node to node when Return is pressed. The keyboard
  /// only closes when focus leaves the group entirely, so moving between
  /// fields no longer tears the input view down and builds it back up.
  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;

  /// True while a sign-up request is in flight.
  ///
  /// Account creation is the one operation here that must never run twice:
  /// the second call reaches Firebase after the first has already claimed
  /// the address and comes back `email-already-in-use`, reporting a failure
  /// for an account that was created perfectly well. The guard is state
  /// rather than a debounce because the window is however long the network
  /// takes, not a fixed number of milliseconds.
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _username, _email, _password]) {
      c.dispose();
    }
    for (final f in [
      _firstFocus,
      _lastFocus,
      _usernameFocus,
      _emailFocus,
      _passwordFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  /// Google and Apple create the account on first use, so signing up
  /// through them is the same call as signing in.
  Future<void> _signUpWithGoogle() =>
      _social(() => context.read<AuthProvider>().signInWithGoogle());

  Future<void> _signUpWithApple() =>
      _social(() => context.read<AuthProvider>().signInWithApple());

  Future<void> _social(Future<void> Function() run) async {
    try {
      await run();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _signUp() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    // Resolved before the await. The router redirects away the moment the
    // session flips, so by the time this returns the messenger reached
    // through `context` could belong to the next screen — which is exactly
    // how a sign-up error came to be painted over Owner details.
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<AuthProvider>().signUp(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );
      // No navigation here either. A new account has no consent, owner or
      // pet, so the router's own landing decision sends them to /consent —
      // the same place, without racing the redirect.
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          // AuthService maps the Firebase codes to sentences; this strips
          // the Exception wrapper the way the social handler already does,
          // so nobody is shown a bracketed `[firebase_auth/…]` string.
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      // Only if this screen is still mounted — after a successful sign-up
      // the redirect has already replaced it.
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The keyboard inset is applied to the scroll view below rather than to
    // the Scaffold. Letting the Scaffold resize shrank the body, and with it
    // the backdrop's expanded Stack — so the puppy, positioned from the
    // bottom, climbed with the keyboard and settled back when it closed.
    // Holding the body at full height keeps the artwork where it was drawn
    // and removes the relayout that made focus changes jump.
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                // The inset the Scaffold is no longer applying. The form
                // still scrolls clear of the keyboard; only the backdrop
                // stays put.
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
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
                              icon: AppIcon(
                                AppIcons.person(context.c.muted),
                                size: 18,
                              ),
                              controller: _first,
                              focusNode: _firstFocus,
                              height: AppTheme.fieldHeightCompact,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _lastFocus.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              hint: 'Last name',
                              controller: _last,
                              focusNode: _lastFocus,
                              height: AppTheme.fieldHeightCompact,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _usernameFocus.requestFocus(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppField(
                        hint: 'Username',
                        icon: AppIcon(
                          AppIcons.username(context.c.muted),
                          size: 19,
                        ),
                        controller: _username,
                        focusNode: _usernameFocus,
                        height: AppTheme.fieldHeightCompact,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                      ),
                      const SizedBox(height: 12),
                      AppField(
                        hint: 'Email address',
                        icon: AppIcon(AppIcons.mail(context.c.muted), size: 20),
                        controller: _email,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        height: AppTheme.fieldHeightCompact,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 12),
                      AppField(
                        hint: 'Password',
                        icon: AppIcon(AppIcons.lock(context.c.muted), size: 19),
                        controller: _password,
                        focusNode: _passwordFocus,
                        obscure: _obscure,
                        height: AppTheme.fieldHeightCompact,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signUp(),
                        onChanged: (_) => setState(() {}),
                        trailing: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: AppIcon(
                            _obscure
                                ? AppIcons.eyeOff(context.c.muted)
                                : AppIcons.eye(context.c.muted),
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PasswordStrength.of(_password.text),
                      const SizedBox(height: 20),
                      AppButton(
                        label: _submitting ? 'Creating account…' : 'Sign Up',
                        variant: AppButtonVariant.start,
                        // Null while in flight: the button stops accepting
                        // taps rather than merely looking busy.
                        onPressed: _submitting ? null : _signUp,
                      ),
                      const SizedBox(height: 18),
                      const OrDivider(),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        // Both were previously rendered with no handlers at
                        // all — two controls that looked like the fastest way
                        // in and did nothing when pressed.
                        child: SocialRow(
                          height: 52,
                          maxWidth: 210,
                          onGoogle: _signUpWithGoogle,
                          onApple: _signUpWithApple,
                        ),
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
