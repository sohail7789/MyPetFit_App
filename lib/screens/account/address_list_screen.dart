import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/settings_tile.dart';

/// Screen 33d — Delivery addresses.
///
/// Tapping a card makes it the default; the design marks that one with a
/// filled radio and a DEFAULT badge. Edit and Remove sit inside each card and
/// stop the tap from also selecting it.
class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final addresses = provider.addresses;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Delivery address',
              onBack: () => context.backOr(AppRoutes.account),
            ),
            Expanded(
              child: addresses.isEmpty
                  ? _Empty(
                      onAdd: () => context.push(AppRoutes.addressNew),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                      children: [
                        for (final address in addresses) ...[
                          _AddressCard(
                            address: address,
                            isDefault: address.id == provider.defaultId,
                            onSelect: () => context
                                .read<AddressProvider>()
                                .setDefault(address.id),
                            onEdit: () => context
                                .push(AppRoutes.addressEdit(address.id)),
                            onRemove: () => _confirmRemove(context, address),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 2),
                        AppButton(
                          label: 'Add new address',
                          variant: AppButtonVariant.outline,
                          height: 52,
                          onPressed: () => context.push(AppRoutes.addressNew),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        title: Text('Remove this address?', style: AppTheme.h3),
        content: Text(
          '${address.label.display} · ${address.formatted}',
          style: AppTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppTheme.font(
                size: 14,
                weight: FontWeight.w700,
                color: AppTheme.body,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Remove',
              style: AppTheme.font(
                size: 14,
                weight: FontWeight.w700,
                color: AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<AddressProvider>().remove(address.id);
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;

  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 48,
              color: AppTheme.dotInactive,
            ),
            const SizedBox(height: 14),
            Text('No addresses yet', style: AppTheme.h2),
            const SizedBox(height: 10),
            Text(
              'Add one so orders have somewhere to go. You can save a few '
              'and pick between them at checkout.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 22),
            AppButton(label: 'Add an address', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final bool isDefault;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onSelect,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isDefault,
      label: '${address.label.display} address',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            color: isDefault ? AppTheme.tintPanel : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: isDefault ? AppTheme.action : AppTheme.border,
              width: isDefault ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isDefault ? AppTheme.action : AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDefault ? AppTheme.action : AppTheme.dotInactive,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isDefault
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              address.label.display,
                              style: AppTheme.font(
                                size: 14.5,
                                weight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.tint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'DEFAULT',
                                  style: AppTheme.font(
                                    size: 10,
                                    weight: FontWeight.w800,
                                    color: AppTheme.action,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.fullName,
                          style: AppTheme.font(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address.multiline,
                          style: AppTheme.font(
                            size: 13,
                            color: AppTheme.body,
                            height: 1.5,
                          ),
                        ),
                        if (address.phone.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            address.phone,
                            style: AppTheme.font(
                              size: 13,
                              color: AppTheme.body,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Inside the card, so they read as belonging to this entry —
              // and each swallows the tap so it doesn't also select it.
              Row(
                children: [
                  const SizedBox(width: 26),
                  _CardAction(label: 'Edit', onTap: onEdit),
                  const SizedBox(width: 4),
                  _CardAction(
                    label: 'Remove',
                    color: AppTheme.danger,
                    onTap: onRemove,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CardAction({
    required this.label,
    required this.onTap,
    this.color = AppTheme.action,
  });

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
              size: 13,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
