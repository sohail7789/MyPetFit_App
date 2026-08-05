import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/settings_tile.dart';
import 'account_screen.dart' show SectionLabelText;

// ─── Reminders & notifications ─────────────────────────────────────────────

/// Toggle state for the reminder screen. Local-only until notifications are
/// wired to a backend.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _values = <String, bool>{
    'retake': true,
    'vacc': true,
    'deworm': false,
    'orders': true,
    'tips': false,
  };

  @override
  Widget build(BuildContext context) {
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
                      _tile('retake', 'Assessment retake', 'Every 3 months'),
                      _tile(
                        'vacc',
                        'Vaccination due',
                        "Based on the dates in your pet's records",
                      ),
                      _tile(
                        'deworm',
                        'Deworming & tick control',
                        'Monthly schedule',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionLabelText('App'),
                  const SizedBox(height: 10),
                  SettingsGroup(
                    children: [
                      _tile(
                        'orders',
                        'Order updates',
                        'Dispatch, delivery and returns',
                      ),
                      _tile(
                        'tips',
                        'Weekly wellness tips',
                        'One tip a week, no spam',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Push notifications are not connected yet — these '
                    'preferences are saved for when they are.',
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

  Widget _tile(String key, String label, String hint) => SettingsSwitchTile(
        label: label,
        hint: hint,
        value: _values[key]!,
        onChanged: (v) => setState(() => _values[key] = v),
      );
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
                      Text(
                        'Reminders about assessments, vaccinations and orders '
                        'will land here once notifications are connected.',
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
