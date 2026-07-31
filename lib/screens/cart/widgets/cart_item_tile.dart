import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/cart_item.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/product_image.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.read<CartProvider>();
    final accent = isDark ? AppTheme.accentBlue : AppTheme.primary;

    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        cart.removeProduct(item.product.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ProductImage(
                    product: item.product,
                    emojiSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${item.product.price.toStringAsFixed(2)} each',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _RoundStepButton(
                          icon: Icons.remove_rounded,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            cart.updateQuantity(
                                item.product.id, item.quantity - 1);
                          },
                        ),
                        SizedBox(
                          width: 36,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: AppMotion.fast,
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                      scale: anim, child: child),
                              child: Text(
                                '${item.quantity}',
                                key: ValueKey(item.quantity),
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                          ),
                        ),
                        _RoundStepButton(
                          icon: Icons.add_rounded,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            cart.addProduct(item.product);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '\$${item.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 32px circular stepper button — proper tap target with a hairline ring
/// (the old zero-constraint IconButtons were ~24px).
class _RoundStepButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _RoundStepButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: CircleBorder(
        side: BorderSide(color: AppTheme.hairline(isDark), width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}
