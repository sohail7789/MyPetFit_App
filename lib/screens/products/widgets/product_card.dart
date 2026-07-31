import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(product.id);
    final quantity = cart.quantityOf(product.id);
    final accent = isDark ? AppTheme.accentBlue : AppTheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product photo (falls back to the emoji when absent/failed)
          SizedBox(
            width: double.infinity,
            height: 92,
            child: ProductImage(product: product, emojiSize: 44),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 15, color: Colors.amber[600]),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: inCart
                        ? _QuantityStepper(
                            quantity: quantity,
                            accent: accent,
                            isDark: isDark,
                            onDecrement: () {
                              HapticFeedback.selectionClick();
                              cart.updateQuantity(product.id, quantity - 1);
                            },
                            onIncrement: () {
                              HapticFeedback.selectionClick();
                              cart.addProduct(product);
                            },
                          )
                        : _AddButton(
                            accent: accent,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              cart.addProduct(product);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tinted "Add to Cart" pill — consistent accent in both modes
/// (the old FilledButton.tonal picked a muddy seeded M3 container color).
class _AddButton extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _AddButton({
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: accent.withValues(alpha: isDark ? 0.20 : 0.10),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Center(
          child: Text(
            'Add to Cart',
            style: theme.textTheme.labelMedium?.copyWith(color: accent),
          ),
        ),
      ),
    );
  }
}

/// Quantity stepper with ≥36px tap targets (the old zero-constraint
/// IconButtons were ~24px — an accessibility failure).
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final Color accent;
  final bool isDark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.accent,
    required this.isDark,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppTheme.hairline(isDark), width: 0.5),
      ),
      child: Row(
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  style: theme.textTheme.titleSmall?.copyWith(color: accent),
                ),
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18),
      ),
    );
  }
}
