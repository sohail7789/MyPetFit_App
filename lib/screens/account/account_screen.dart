import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/add_pet_sheet.dart';
import '../../widgets/blob_background.dart';
import '../../widgets/mypetfit_logo.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final petProvider = context.watch<PetInfoProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final owner = petProvider.ownerInfo;

    return Scaffold(
      body: BlobBackground(
        variant: BlobVariant.topRight,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header — the theme toggle lives in Settings below, so it
                // is no longer duplicated up here.
                Row(
                  children: [
                    const MyPetFitLogo.compact(fontSize: 20),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),

                // ─── Identity card ───
                _ProfileCard(
                  owner: owner,
                  fallbackName: auth.displayName,
                  fallbackEmail: auth.email,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ─── Pet profiles ───
                _SectionHeader(
                  title: 'Pet profiles',
                  subtitle: 'Up to ${PetInfoProvider.maxPets} profiles',
                  trailing:
                      '${petProvider.petCount} / ${PetInfoProvider.maxPets}',
                ),
                const SizedBox(height: AppSpacing.md),

                for (int i = 0; i < petProvider.pets.length; i++) ...[
                  _PetCard(
                    pet: petProvider.pets[i],
                    isActive: i == petProvider.activePetIndex,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      petProvider.setActivePet(i);
                    },
                    onDelete: petProvider.petCount > 1
                        ? () => _confirmDelete(context, petProvider, i)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (petProvider.canAddPet)
                  _AddPetButton(
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showAddPetSheet(context, petProvider);
                    },
                  ),

                const SizedBox(height: AppSpacing.xxxl),

                // ─── Preferences ───
                const _SectionHeader(title: 'Preferences'),
                const SizedBox(height: AppSpacing.md),
                _SettingsGroup(
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      iconColor:
                          isDark ? AppTheme.accentBlue : AppTheme.primary,
                      title: 'Dark Mode',
                      isDark: isDark,
                      trailing: CupertinoSwitch(
                        value: isDark,
                        activeTrackColor: AppTheme.primary,
                        onChanged: (_) {
                          HapticFeedback.lightImpact();
                          themeProvider.toggle();
                        },
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppTheme.secondary,
                      title: 'About MyPetFit',
                      isDark: isDark,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.mutedText(isDark),
                        size: 20,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('MyPetFit v1.0')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.section),

                // ─── Account actions ───
                _SettingsGroup(
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppTheme.errorColor,
                      title: 'Sign Out',
                      titleColor: AppTheme.errorColor,
                      isDark: isDark,
                      onTap: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    // Capture the providers *before* the async gap so we don't touch
    // BuildContext after the sheet resolves.
    final cart = context.read<CartProvider>();
    final pets = context.read<PetInfoProvider>();
    final quiz = context.read<QuizProvider>();
    final auth = context.read<AuthProvider>();

    HapticFeedback.mediumImpact();
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Sign out?'),
        message: const Text(
          'This will clear your pets, cart, and assessment history on '
          'this device.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (confirmed != true) return;

    // Clear user-scoped state first, then flip AuthProvider — the router
    // redirect fires on the auth notify and lands the user on /sign-in
    // with no lingering data.
    await cart.reset();
    await pets.reset();
    await quiz.resetAll();
    await auth.signOut();
  }

  void _confirmDelete(
      BuildContext context, PetInfoProvider provider, int index) {
    final petName = provider.pets[index].name;
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Remove $petName?'),
        message: const Text('This can\'t be undone.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.removePet(index);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Private widgets
// ───────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              trailing!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
      ],
    );
  }
}

/// Identity card. Falls back to the signed-in account's name/email when the
/// owner profile hasn't been filled in yet, so the card is never a dead end.
class _ProfileCard extends StatelessWidget {
  final OwnerInfo? owner;
  final String fallbackName;
  final String fallbackEmail;
  final bool isDark;

  const _ProfileCard({
    required this.owner,
    required this.fallbackName,
    required this.fallbackEmail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = owner?.name.isNotEmpty == true
        ? owner!.name
        : (fallbackName.isNotEmpty ? fallbackName : 'Your profile');
    final email = owner?.email.isNotEmpty == true
        ? owner!.email
        : fallbackEmail;
    final phone = owner?.contactNumber ?? '';
    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline(isDark), width: 0.5),
      ),
      child: Row(
        children: [
          // Monogram avatar — reads as a real identity, unlike the old
          // generic person glyph (which was navy-on-navy in dark mode).
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(phone, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetInfo pet;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PetCard({
    required this.pet,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor =
        isDark ? AppTheme.accentPink : AppTheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: AppMotion.gentle,
          curve: AppMotion.curve,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            // Single border that thickens + tints when active. The old
            // version nested a bordered container around a bordered Card,
            // producing a doubled ring.
            border: Border.all(
              color: isActive ? activeColor : AppTheme.hairline(isDark),
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  // Was darkBlueSurface in dark mode — identical to the card
                  // fill, so the avatar vanished. Now always distinct.
                  color: isDark
                      ? AppTheme.darkBlueBg
                      : AppTheme.lightGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  pet.species.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pet.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: activeColor.withValues(
                                  alpha: isDark ? 0.28 : 0.16),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'Active',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: activeColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pet.breed} · ${pet.ageDisplay} · ${pet.weightKg} kg',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppTheme.mutedText(isDark),
                  tooltip: 'Remove ${pet.name}',
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPetButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddPetButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isDark ? AppTheme.accentBlue : AppTheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add another pet',
                style: theme.textTheme.labelLarge?.copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style grouped settings container — rounded surface with hairline
/// dividers between rows and no divider after the last one.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsGroup({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline(isDark), width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 56,
                color: AppTheme.hairline(isDark),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  color: titleColor,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
