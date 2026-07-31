import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/primary_button.dart';
import 'widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _confirmClearAll(BuildContext context, CartProvider cart) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Clear cart?'),
        message: const Text('All items will be removed.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, cart),
              child: const Text(
                'Clear All',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppTheme.tint(isDark, AppTheme.accentBlue,
                            AppTheme.lightAzure),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 40,
                        color:
                            isDark ? AppTheme.accentBlue : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Your cart is empty',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Products you add will show up here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText(isDark),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(
                      label: 'Browse Products',
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      physics: const BouncingScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          CartItemTile(item: cart.items[index]),
                    ),
                  ),
                  // Summary bar — hairline top border instead of a shadow,
                  // consistent with the app's flat design system.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(isDark),
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.hairline(isDark),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total (${cart.totalItems} items)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedText(isDark),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: AppMotion.base,
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                      opacity: anim, child: child),
                              child: Text(
                                '\$${cart.totalPrice.toStringAsFixed(2)}',
                                key: ValueKey(cart.totalPrice),
                                style:
                                    theme.textTheme.headlineSmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.accentBlue
                                      : AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          label: 'Proceed to Checkout',
                          onPressed: () =>
                              context.push(AppRoutes.checkout),
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
