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
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/settings_tile.dart';

/// Screen 36 — Delete account.
///
/// The design gates the destructive action behind typing DELETE; that gate is
/// kept, and the wipe clears every local provider before signing out.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

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

  Future<void> _delete() async {
    // Resolved before the first await so nothing reaches for a stale context.
    final router = GoRouter.of(context);
    final quiz = context.read<QuizProvider>();
    final cart = context.read<CartProvider>();
    final pets = context.read<PetInfoProvider>();
    final address = context.read<AddressProvider>();
    final auth = context.read<AuthProvider>();
    final startup = context.read<AppStartupProvider>();

    await quiz.resetAll();
    await cart.reset();
    await pets.reset();
    await address.reset();
    // initialize() refuses to run again once it has reported ready, so
    // without this the next person to sign in on this device inherits
    // that verdict and none of their own data is ever fetched.
    startup.reset();
    await auth.signOut();
    router.go(AppRoutes.accountDeleted);
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
                    label: 'Delete my account',
                    variant: AppButtonVariant.danger,
                    height: AppTheme.ctaHeightCompact,
                    onPressed: _ready ? _delete : null,
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
