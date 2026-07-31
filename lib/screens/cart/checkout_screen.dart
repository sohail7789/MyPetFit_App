import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/primary_button.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final freeColor =
        isDark ? const Color(0xFF5DD08A) : AppTheme.successColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            ...cart.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      Text(item.product.emoji),
                                      const SizedBox(
                                          width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          '${item.product.name} x${item.quantity}',
                                          style:
                                              theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        '\$${item.totalPrice.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const Divider(height: AppSpacing.xxl),
                            _SummaryRow(
                              label: 'Subtotal',
                              value:
                                  '\$${cart.totalPrice.toStringAsFixed(2)}',
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SummaryRow(
                              label: 'Shipping',
                              value: 'Free',
                              valueColor: freeColor,
                              isDark: isDark,
                            ),
                            const Divider(height: AppSpacing.xxl),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '\$${cart.totalPrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: isDark
                                        ? AppTheme.accentBlue
                                        : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: PrimaryButton(
                label: 'Place Order',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  cart.clearCart();
                  context.go(AppRoutes.orderSuccess);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedText(isDark),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight:
                valueColor != null ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
