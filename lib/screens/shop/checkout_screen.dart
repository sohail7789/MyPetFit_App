import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'cart_screen.dart' show SummaryRow;
import 'widgets/product_tile.dart';

/// Screen 27 — Checkout.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _payment = 0;

  static const _methods = [
    ('UPI', ''),
    ('Card', ''),
    ('Cash on delivery', ''),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final owner = context.watch<PetInfoProvider>().ownerInfo;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => context.backOr(AppRoutes.shop),
                  ),
                  const SizedBox(width: 12),
                  Text('Checkout', style: AppTheme.h2),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                children: [
                  const SectionLabel('Deliver to'),
                  const SizedBox(height: 14),
                  _AddressCard(
                    name: owner?.name.trim().isNotEmpty == true
                        ? owner!.name
                        : 'Add a delivery address',
                    address: (owner?.address?.trim().isNotEmpty ?? false)
                        ? owner!.address!
                        : 'No address on file yet.',
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Payment'),
                  const SizedBox(height: 14),
                  for (var i = 0; i < _methods.length; i++) ...[
                    _PaymentRow(
                      label: _methods[i].$1,
                      hint: _methods[i].$2,
                      selected: _payment == i,
                      onTap: () => setState(() => _payment = i),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 2),
                  AppCard(
                    background: const Color(0xFFFCFBFD),
                    radius: AppTheme.radiusCardSmall,
                    child: Column(
                      children: [
                        SummaryRow(
                          label: 'Items (${cart.totalItems})',
                          value: formatPrice(cart.totalPrice),
                          size: 13,
                        ),
                        const SizedBox(height: 8),
                        const SummaryRow(
                          label: 'Delivery',
                          value: 'Free',
                          valueIsFree: true,
                          size: 13,
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFFEDEBF4)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: AppTheme.font(
                                size: 15,
                                weight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                            Text(
                              formatPrice(cart.totalPrice),
                              style: AppTheme.font(
                                size: 15,
                                weight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.borderSoft)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
              child: AppButton(
                label: 'Place order · ${formatPrice(cart.totalPrice)}',
                variant: AppButtonVariant.start,
                height: AppTheme.ctaHeightCompact,
                onPressed: cart.isEmpty
                    ? null
                    : () => context.push(AppRoutes.orderSuccess),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String name;
  final String address;

  const _AddressCard({required this.name, required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.tintPanel,
        borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
        border: Border.all(color: AppTheme.action, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.location_on_outlined,
              size: 20,
              color: AppTheme.action,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: AppTheme.font(
                    size: 13,
                    color: AppTheme.body,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Change',
            style: AppTheme.font(
              size: 13,
              weight: FontWeight.w700,
              color: AppTheme.action,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentRow({
    required this.label,
    required this.hint,
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
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(
            color: selected ? AppTheme.action : AppTheme.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTheme.font(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
            if (hint.isNotEmpty)
              Text(
                hint,
                style: AppTheme.font(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
