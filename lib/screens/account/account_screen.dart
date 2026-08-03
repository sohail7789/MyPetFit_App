import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import '../../widgets/settings_tile.dart';

/// Screen 31 — Account.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    // Resolved before the first await so nothing reaches for a stale context.
    final router = GoRouter.of(context);
    final quiz = context.read<QuizProvider>();
    final cart = context.read<CartProvider>();
    final address = context.read<AddressProvider>();
    final auth = context.read<AuthProvider>();

    await quiz.resetAll();
    await cart.reset();
    // The delivery address is per-user; leaving it behind would hand the
    // next person to sign in on this device someone else's home address.
    await address.reset();
    await auth.signOut();
    router.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pets = context.watch<PetInfoProvider>();
    final petCount = pets.petCount;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('Account', style: AppTheme.h2),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                children: [
                  _ProfileCard(
                    name: auth.displayName.trim().isEmpty
                        ? 'Your profile'
                        : auth.displayName,
                    subtitle: [
                      if (auth.email.isNotEmpty) auth.email,
                      '$petCount ${petCount == 1 ? 'pet' : 'pets'}',
                    ].join(' · '),
                    // The design's profile card carries an "Edit" link; it
                    // belongs on the owner profile, not My pets.
                    onEdit: () => context.push(AppRoutes.ownerProfile),
                  ),
                  const SizedBox(height: 14),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Owner profile',
                        onTap: () => context.push(AppRoutes.ownerProfile),
                      ),
                      SettingsTile(
                        icon: Icons.pets_rounded,
                        label: 'My pets',
                        onTap: () => context.push(AppRoutes.pets),
                      ),
                      SettingsTile(
                        icon: Icons.inventory_2_outlined,
                        label: 'Orders',
                        onTap: () => context.push(AppRoutes.orders),
                      ),
                      SettingsTile(
                        icon: Icons.location_on_outlined,
                        label: 'Delivery address',
                        onTap: () => context.push(AppRoutes.address),
                      ),
                      SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Reminders & notifications',
                        onTap: () => context.push(AppRoutes.reminders),
                      ),
                      SettingsTile(
                        icon: Icons.language_rounded,
                        label: 'Language — '
                            '${context.watch<LocaleProvider>().current.name}',
                        onTap: () => context.push(AppRoutes.language),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 2, 4, 0),
                    child: SectionLabelText('Legal & data'),
                  ),
                  const SizedBox(height: 10),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        icon: Icons.article_outlined,
                        label: 'Terms of Service',
                        onTap: () => context.push(AppRoutes.terms),
                      ),
                      SettingsTile(
                        icon: Icons.shield_outlined,
                        label: 'Privacy Policy',
                        onTap: () => context.push(AppRoutes.privacy),
                      ),
                      SettingsTile(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete account',
                        destructive: true,
                        onTap: () => context.push(AppRoutes.deleteAccount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Log out',
                    variant: AppButtonVariant.outline,
                    height: 52,
                    onPressed: () => _logOut(context),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MyPetFit v1.0 · Made with care for pets',
                    textAlign: TextAlign.center,
                    style: AppTheme.font(
                      size: 12,
                      color: AppTheme.placeholder,
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

/// Uppercase group label ("LEGAL & DATA").
class SectionLabelText extends StatelessWidget {
  final String text;

  const SectionLabelText(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTheme.overline);
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFD),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1F9),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(5),
            child: const DesignImage(AppAssets.emoHappy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    size: 16,
                    weight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(size: 13, color: AppTheme.body),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Edit',
                style: AppTheme.font(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.action,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
