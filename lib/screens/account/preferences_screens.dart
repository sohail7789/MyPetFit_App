import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../services/reminder_scheduler.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/settings_tile.dart';
import 'account_screen.dart' show SectionLabelText;

// ─── Reminders & notifications ─────────────────────────────────────────────

/// Reminder preferences.
///
/// One toggle, and it works. This screen used to show five — vaccination,
/// deworming, order updates and weekly tips alongside the retake — all held
/// in widget state that popping the screen discarded, under a line claiming
/// they were saved. Four of them also described things the app has no data
/// for: [PetInfo] carries no vaccination or deworming dates, and ordering is
/// closed, so none of them could ever have fired.
///
/// What remains is derived from a date the app does hold — the last
/// assessment — and is scheduled on the device by [ReminderScheduler].
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  /// True while a permission prompt is open, so the switch cannot be driven
  /// twice into two prompts.
  bool _busy = false;

  /// Turning the reminder on asks for notification permission first.
  ///
  /// Permission is requested here rather than at launch: this is the moment
  /// the user has asked for the thing the permission is for, which is both
  /// the only honest time to ask and the time it is most likely granted. A
  /// refusal leaves the preference off rather than storing an intent that
  /// silently does nothing.
  Future<void> _onChanged(bool wanted) async {
    if (_busy) return;

    final reminders = context.read<RemindersProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (!wanted) {
      await reminders.setAssessmentRetake(false);
      return;
    }

    setState(() => _busy = true);
    try {
      final granted = await context.read<ReminderScheduler>().requestPermission();
      if (!mounted) return;

      if (!granted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are turned off for MyPetFit. Enable them in '
              'your device settings to get retake reminders.',
            ),
          ),
        );
        return;
      }

      await reminders.setAssessmentRetake(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<RemindersProvider>();

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Reminders',
              onBack: () => context.backOr(AppRoutes.account),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  const SectionLabelText('Health'),
                  const SizedBox(height: 10),
                  SettingsGroup(
                    children: [
                      SettingsSwitchTile(
                        label: 'Assessment retake',
                        hint: 'Every 3 months, for each pet',
                        value: reminders.assessmentRetake,
                        onChanged: _onChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reminders.assessmentRetake
                        ? "You'll get a reminder when each pet's assessment "
                              'is three months old. Pets without an '
                              'assessment yet are not counted until they '
                              'have one.'
                        : 'A reminder when each pet’s fitness assessment is '
                              'due again. Scheduled on this device — nothing '
                              'is sent to you from anywhere else.',
                    style: AppTheme.font(
                      size: 12.5,
                      color: context.c.muted,
                      height: 1.55,
                    ),
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

// ─── Language ──────────────────────────────────────────────────────────────

/// Language preference. Backed by [LocaleProvider], the same source the
/// sign-in chip reads, so the two can never show different selections.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Language',
              onBack: () => context.backOr(AppRoutes.account),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  for (final language in LocaleProvider.supported) ...[
                    LanguageRow(
                      language: language,
                      selected: locale.code == language.code,
                      onTap: language.available
                          ? () => context
                              .read<LocaleProvider>()
                              .select(language.code)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Hindi and Marathi are being translated — including all 45 '
                    'assessment questions — and will switch on here once ready.',
                    style: AppTheme.font(
                      size: 12.5,
                      color: context.c.muted,
                      height: 1.55,
                    ),
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

// ─── Orders ────────────────────────────────────────────────────────────────

/// Order history. There is no order backend yet, so this reflects only what
/// the current session placed rather than showing invented past orders.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: 'Orders', onBack: () => context.backOr(AppRoutes.account)),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DesignImage(
                        AppAssets.orderTracking,
                        width: 150,
                        shadow: true,
                      ),
                      const SizedBox(height: 18),
                      Text('No orders yet', style: context.t.h2),
                      const SizedBox(height: 10),
                      Text(
                        'Your order history will appear here once the store '
                        'is connected.',
                        textAlign: TextAlign.center,
                        style: context.t.bodyText,
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        label: cart.isEmpty
                            ? 'Browse the shop'
                            : 'View your cart',
                        onPressed: () => cart.isEmpty
                            ? context.go(AppRoutes.shop)
                            : context.push(AppRoutes.cart),
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

// ─── Notifications inbox ───────────────────────────────────────────────────

/// Screen 31b — Notifications inbox.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Notifications',
              onBack: () => context.backOr(AppRoutes.account),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DesignImage(
                        AppAssets.emoSleep,
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 14),
                      Text('Nothing here yet', style: context.t.h2),
                      const SizedBox(height: 10),
                      // Retake reminders are delivered by the device, not
                      // collected into an in-app feed, so this no longer
                      // promises that they will "land here". Naming
                      // vaccinations and orders was a second promise: the
                      // app holds no vaccination dates and ordering is
                      // closed.
                      Text(
                        'Retake reminders arrive as device notifications. '
                        'Choose whether to get them in Reminders.',
                        textAlign: TextAlign.center,
                        style: context.t.bodyText,
                      ),
                      const SizedBox(height: 22),
                      AppCard(
                        background: context.c.surfaceLow,
                        child: Row(
                          children: [
                            const DesignImage(
                              AppAssets.emoTilt,
                              width: 34,
                              height: 34,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Choose what you want to hear about in '
                                'Reminders.',
                                style: AppTheme.font(
                                  size: 13,
                                  color: context.c.bodyStrong,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
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
