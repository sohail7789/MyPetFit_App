import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import 'widgets/product_tile.dart';

/// Screen 26 — Cart.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

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
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Your cart', style: AppTheme.h2)),
                  if (!cart.isEmpty)
                    Text(
                      '${cart.totalItems} '
                      '${cart.totalItems == 1 ? 'item' : 'items'}',
                      style: AppTheme.font(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppTheme.muted,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? const _EmptyCart()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _CartRow(
                        item: cart.items[i],
                        onIncrease: () => cart.updateQuantity(
                          cart.items[i].product.id,
                          cart.items[i].quantity + 1,
                        ),
                        onDecrease: () => cart.updateQuantity(
                          cart.items[i].product.id,
                          cart.items[i].quantity - 1,
                        ),
                        onRemove: () =>
                            cart.removeProduct(cart.items[i].product.id),
                      ),
                    ),
            ),
            if (!cart.isEmpty) _CartFooter(subtotal: cart.totalPrice),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartRow({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumb(product: item.product, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppTheme.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatPrice(item.totalPrice),
                  style: AppTheme.font(
                    size: 13,
                    weight: FontWeight.w800,
                    color: AppTheme.action,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StepButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrease,
                      semanticLabel: 'Decrease quantity',
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: AppTheme.font(
                          size: 14,
                          weight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrease,
                      semanticLabel: 'Increase quantity',
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onRemove,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          'Remove',
                          style: AppTheme.font(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 16, color: AppTheme.action),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignImage(AppAssets.emoQuestion, width: 110, height: 110),
            const SizedBox(height: 10),
            Text(
              'Your cart is empty — add something from the picks.',
              textAlign: TextAlign.center,
              style: AppTheme.font(size: 14, color: AppTheme.body),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Back to shop',
              height: 44,
              expand: false,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final double subtotal;

  const _CartFooter({required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryRow(label: 'Subtotal', value: formatPrice(subtotal)),
          const SizedBox(height: 10),
          const SummaryRow(label: 'Delivery', value: 'Free', valueIsFree: true),
          const SizedBox(height: 14),
          AppButton(
            label: 'Checkout · ${formatPrice(subtotal)}',
            height: AppTheme.ctaHeightCompact,
            onPressed: () => context.push(AppRoutes.checkout),
          ),
        ],
      ),
    );
  }
}

/// Label/value line used in the cart and checkout summaries.
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueIsFree;
  final double size;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueIsFree = false,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.font(size: size, color: AppTheme.body)),
        Text(
          value,
          style: AppTheme.font(
            size: size,
            weight: FontWeight.w700,
            color: valueIsFree ? AppTheme.success : AppTheme.ink,
          ),
        ),
      ],
    );
  }
}
