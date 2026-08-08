import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/address_provider.dart';
import '../../providers/app_startup_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../services/account_deletion.dart';
import '../../services/auth_service.dart' show ReauthenticationRequired;
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_field.dart';
import '../../widgets/design_image.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/settings_tile.dart';

/// Screen 36 — Delete account.
///
/// The design gates the destructive action behind typing DELETE; that gate is
/// kept.
///
/// **This screen used to delete nothing.** It cleared the local providers,
/// signed out and announced "Account deleted" — while the Firebase account
/// and every document under `users/{uid}` remained. That is a false statement
/// to the user about their own data, and it fails both stores' deletion
/// requirements.
///
/// The order below is deliberate: cloud data, then the account, then local
/// state, and only then the confirmation screen. Nothing local is cleared
/// until the deletion has actually succeeded, so a failure leaves the user
/// with their account *and* their data intact, and tells them so.
class DeleteAccountScreen extends StatefulWidget {
  /// The deletion steps, injectable so this destructive flow can be tested
  /// without Firebase. Production passes nothing.
  @visibleForTesting
  final AccountDeletion deletion;

  const DeleteAccountScreen({
    super.key,
    this.deletion = const AccountDeletion(),
  });

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready => _confirm.text.trim().toUpperCase() == 'DELETE';

  /// True while the deletion is in flight, so the button cannot be pressed
  /// twice into a half-deleted account.
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;

    // Resolved before the first await so nothing reaches for a stale context.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final quiz = context.read<QuizProvider>();
    final cart = context.read<CartProvider>();
    final pets = context.read<PetInfoProvider>();
    final address = context.read<AddressProvider>();
    final auth = context.read<AuthProvider>();
    final startup = context.read<AppStartupProvider>();
    final deletion = widget.deletion;

    setState(() => _deleting = true);

    try {
      // Documents first: they are scoped to the uid, so they must go while a
      // session still exists to reach them.
      await deletion.deleteUserData();

      try {
        await deletion.deleteAccount();
      } on ReauthenticationRequired {
        // Recoverable, and the only failure that is. Firebase judged the
        // session too old to delete with; prove who they are and retry.
        final confirmed = await _reauthenticate(deletion);
        if (!confirmed) {
          if (mounted) setState(() => _deleting = false);
          return;
        }
        await deletion.deleteAccount();
      }
    } catch (error) {
      // Nothing local has been touched, so the account is still usable.
      if (mounted) setState(() => _deleting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Your account was not deleted: $error",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // The account is gone. Only now is it true to clear the device.
    await quiz.resetAll();
    await cart.reset();
    await pets.reset();
    await address.reset();
    // initialize() refuses to run again once it has reported ready, so
    // without this the next person to sign in on this device inherits
    // that verdict and none of their own data is ever fetched.
    startup.reset();

    // Deleting the account already ends the Firebase session, so a failure
    // here means the local flags outlived an account that no longer exists —
    // worth clearing, not worth blocking the confirmation over.
    try {
      await auth.signOut();
    } catch (_) {}

    router.go(AppRoutes.accountDeleted);
  }

  /// Asks the user to prove who they are, using the provider they signed up
  /// with. Returns false when they cancel.
  Future<bool> _reauthenticate(AccountDeletion deletion) async {
    final isGoogle = (deletion.providerId ?? '').contains('google');

    if (isGoogle) {
      try {
        await deletion.reauthenticateWithGoogle();
        return true;
      } catch (error) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not confirm your Google account: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    final password = await showDialog<String>(
      context: context,
      builder: (context) => _PasswordPrompt(),
    );
    if (password == null || password.isEmpty) return false;

    try {
      await deletion.reauthenticateWithPassword(password);
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Delete account',
              onBack: () => context.backOr(AppRoutes.account),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                children: [
                  AppCard(
                    background: context.c.bandCriticalTint,
                    borderColor: context.c.bandCriticalLine,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This cannot be undone',
                          style: AppTheme.font(
                            size: 15,
                            weight: FontWeight.w800,
                            color: context.c.critical,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deleting your account permanently removes your '
                          "profile and your pet's health history within 30 "
                          'days. Anonymised research data that has already '
                          'been aggregated cannot be recalled. Order records '
                          'are retained as required by tax law.',
                          style: AppTheme.font(
                            size: 13,
                            color: context.c.bodyStrong,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Type DELETE to confirm',
                    style: AppTheme.font(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Confirmation',
                    hint: 'DELETE',
                    controller: _confirm,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
              child: Column(
                children: [
                  AppButton(
                    label: _deleting
                        ? 'Deleting your account…'
                        : 'Delete my account',
                    variant: AppButtonVariant.danger,
                    height: AppTheme.ctaHeightCompact,
                    onPressed: _ready && !_deleting ? _delete : null,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Keep my account',
                    variant: AppButtonVariant.outline,
                    height: 52,
                    onPressed: () => context.backOr(AppRoutes.account),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 37 — Account deleted.
class AccountDeletedScreen extends StatelessWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: DesignImage(
                  AppAssets.emoQuestion,
                  width: 160,
                  shadow: true,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Your account is deleted',
                textAlign: TextAlign.center,
                style: context.t.h1.copyWith(fontSize: 26, letterSpacing: -1),
              ),
              const SizedBox(height: 12),
              Text(
                "We're sorry to see you go. Your profile and health history "
                'will be fully removed within 30 days.',
                textAlign: TextAlign.center,
                style: context.t.bodyText,
              ),
              const SizedBox(height: 26),
              AppButton(
                label: 'Back to start',
                onPressed: () => context.go(AppRoutes.welcome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirms the account password before a deletion Firebase judged stale.
///
/// Deliberately spare: this is not a sign-in form, it is the last thing
/// standing between someone and losing their pet's health record, so it says
/// what it is for and offers an obvious way out.
class _PasswordPrompt extends StatefulWidget {
  @override
  State<_PasswordPrompt> createState() => _PasswordPromptState();
}

class _PasswordPromptState extends State<_PasswordPrompt> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.c.surface,
      title: Text('Confirm your password', style: context.t.h2),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You've been signed in a while, so please confirm your password "
            'before your account is deleted.',
            style: context.t.bodyText,
          ),
          const SizedBox(height: 14),
          AppField(
            hint: 'Your password',
            controller: _password,
            obscure: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_password.text),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
