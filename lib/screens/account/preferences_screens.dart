import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
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

// ─── Appearance ────────────────────────────────────────────────────────────

/// Light / dark selector.
///
/// The design has no appearance control of its own — it ships a light and a
/// dark variant of every screen and leaves the choice to the OS. "System" is
/// therefore the default and the honest match for the design; the two
/// explicit options are here for people whose device-wide setting doesn't
/// suit this app.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  static const _options = <(ThemeMode, IconData, String, String)>[
    (
      ThemeMode.system,
      Icons.brightness_auto_rounded,
      'System',
      'Follow the device setting',
    ),
    (ThemeMode.light, Icons.light_mode_rounded, 'Light', 'Always light'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark', 'Always dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Appearance',
              onBack: () => context.backOr(AppRoutes.account),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  for (final (mode, icon, title, subtitle) in _options) ...[
                    _AppearanceRow(
                      icon: icon,
                      title: title,
                      subtitle: subtitle,
                      selected: theme.mode == mode,
                      onTap: () =>
                          context.read<ThemeProvider>().select(mode),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Dark uses the same layouts on a violet-black ground, with '
                    'the brand indigo brightened so it still reads as the '
                    'action colour.',
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

/// Selectable row matching [LanguageRow]'s treatment, so the two preference
/// screens read as one pattern.
class _AppearanceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.c.tintPanel : context.c.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
            border: Border.all(
              color: selected ? context.c.actionText : context.c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.c.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: context.c.actionText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 15,
                        weight: FontWeight.w700,
                        color: context.c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 12.5,
                        color: context.c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: context.c.actionText,
                ),
            ],
          ),
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
