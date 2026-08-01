import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
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
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Reminders',
              onBack: () => context.pop(),
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
                      color: AppTheme.muted,
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

/// The design offers English and Hindi. Only the selection is stored — the
/// app is not localised yet.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'en';

  static const _languages = [
    (code: 'en', glyph: 'En', name: 'English', native: 'Default'),
    (code: 'hi', glyph: 'हि', name: 'Hindi', native: 'हिन्दी'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: 'Language', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  for (final language in _languages) ...[
                    _LanguageRow(
                      glyph: language.glyph,
                      name: language.name,
                      native: language.native,
                      selected: _selected == language.code,
                      onTap: () => setState(() => _selected = language.code),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Translations are not shipped yet — the app currently '
                    'displays in English regardless of this setting.',
                    style: AppTheme.font(
                      size: 12.5,
                      color: AppTheme.muted,
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

class _LanguageRow extends StatelessWidget {
  final String glyph;
  final String name;
  final String native;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.glyph,
    required this.name,
    required this.native,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.tintPanel : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: selected ? AppTheme.action : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1F9),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                glyph,
                style: AppTheme.font(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppTheme.action,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTheme.font(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    native,
                    style: AppTheme.font(size: 12.5, color: AppTheme.body),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppTheme.action : AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.action : AppTheme.dotInactive,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
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
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: 'Orders', onBack: () => context.pop()),
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
                      Text('No orders yet', style: AppTheme.h2),
                      const SizedBox(height: 10),
                      Text(
                        'Your order history will appear here once the store '
                        'is connected.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyText,
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
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Notifications',
              onBack: () => context.pop(),
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
                      Text('Nothing here yet', style: AppTheme.h2),
                      const SizedBox(height: 10),
                      Text(
                        'Reminders about assessments, vaccinations and orders '
                        'will land here once notifications are connected.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyText,
                      ),
                      const SizedBox(height: 22),
                      AppCard(
                        background: const Color(0xFFFCFBFD),
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
                                  color: AppTheme.bodyStrong,
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
