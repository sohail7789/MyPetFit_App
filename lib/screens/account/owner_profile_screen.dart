import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/settings_tile.dart';
import 'account_screen.dart' show SectionLabelText;

/// Screen 33c — Owner profile.
///
/// Identity comes from two places and this screen has to reconcile them:
/// [AuthProvider] holds the sign-in account, while [OwnerInfo] holds the
/// contact details captured during the assessment (the ones that go on the
/// report a vet receives). The editable record is [OwnerInfo]; the sign-in
/// email is shown read-only, because changing it here would not move the
/// actual account and presenting it as editable would be a lie.
class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetInfoProvider>();
    final auth = context.watch<AuthProvider>();
    final address = context.watch<AddressProvider>().address;

    final owner = pets.ownerInfo;
    final name = owner?.name.trim().isNotEmpty == true
        ? owner!.name.trim()
        : auth.displayName.trim();
    final petCount = pets.petCount;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The design puts Edit in the header rather than as a button
            // below the details.
            ScreenHeader(
              title: 'Owner profile',
              onBack: () => context.backOr(AppRoutes.account),
              trailing: _HeaderAction(
                label: 'Edit',
                onTap: () => context.push(AppRoutes.ownerEdit),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F1F9),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.all(6),
                        child: const DesignImage(AppAssets.emoHappy),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name.isEmpty ? 'Your profile' : name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.h2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$petCount ${petCount == 1 ? 'pet' : 'pets'}',
                              style: AppTheme.font(
                                size: 13.5,
                                color: AppTheme.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Column(
                      children: [
                        _Row(label: 'Full name', value: owner?.name ?? ''),
                        _Row(
                          label: 'Contact number',
                          value: owner?.contactNumber ?? '',
                        ),
                        _Row(label: 'Email', value: owner?.email ?? ''),
                        // Only worth showing when it differs from the contact
                        // email — otherwise it just reads as a duplicate row.
                        if (auth.email.trim().isNotEmpty &&
                            auth.email.trim().toLowerCase() !=
                                (owner?.email ?? '').trim().toLowerCase())
                          _Row(
                            label: 'Sign-in email',
                            value: auth.email,
                            note: 'Managed by your account',
                          ),
                        _Row(
                          label: 'Veterinarian',
                          value: owner?.vetName ?? '',
                        ),
                        _Row(
                          label: 'Vet contact',
                          value: owner?.vetContact ?? '',
                        ),
                        _Row(
                          label: 'Language',
                          value: context.watch<LocaleProvider>().current.name,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 2, 4, 0),
                    child: SectionLabelText('Delivery'),
                  ),
                  const SizedBox(height: 10),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        icon: Icons.location_on_outlined,
                        label: address == null
                            ? 'Add a delivery address'
                            : 'Delivery address',
                        onTap: () => context.push(AppRoutes.addresses),
                      ),
                      SettingsTile(
                        icon: Icons.pets_rounded,
                        label: 'My pets',
                        onTap: () => context.push(AppRoutes.pets),
                      ),
                    ],
                  ),
                  if (address != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                      child: Text(
                        address.multiline,
                        style: AppTheme.font(
                          size: 12.5,
                          color: AppTheme.muted,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's header-level "Edit" link.
class _HeaderAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            label,
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w700,
              color: AppTheme.action,
            ),
          ),
        ),
      ),
    );
  }
}

/// Label on the left, value right-aligned. Mirrors the pet profile rows.
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final bool last;

  const _Row({
    required this.label,
    required this.value,
    this.note,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderSoft)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.font(size: 13.5, color: AppTheme.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  empty ? 'Not set' : value.trim(),
                  textAlign: TextAlign.right,
                  style: AppTheme.font(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: empty ? AppTheme.muted : AppTheme.ink,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    textAlign: TextAlign.right,
                    style: AppTheme.font(size: 11.5, color: AppTheme.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
