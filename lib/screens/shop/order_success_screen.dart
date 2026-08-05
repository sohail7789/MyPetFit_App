import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import 'order_reference.dart';

/// Screen 28 — Order placed.
///
/// Placing the order clears the cart, so backing into checkout can't submit
/// the same basket twice.
class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  late final OrderReference _order;

  @override
  void initState() {
    super.initState();
    _order = OrderReference.create(
      itemCount: context.read<CartProvider>().totalItems,
    );
    // Deferred so the clear happens after this frame's build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartProvider>().clearCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [context.c.surface, context.c.surfaceRaised],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: DesignImage(
                    AppAssets.orderPlaced,
                    width: 280,
                    shadow: true,
                    semanticLabel: 'Puppy with a delivery box',
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Order placed!',
                  textAlign: TextAlign.center,
                  style: context.t.h1.copyWith(fontSize: 27, letterSpacing: -1),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: 'Your picks are on the way.\nOrder ',
                    children: [
                      TextSpan(
                        text: _order.id,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.c.ink,
                        ),
                      ),
                      const TextSpan(text: ' · arriving '),
                      TextSpan(
                        text: _order.arrivalLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.c.ink,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    size: 14.5,
                    color: context.c.body,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 26),
                AppButton(
                  label: 'Track order',
                  height: AppTheme.ctaHeightCompact,
                  onPressed: () => context.push(
                    AppRoutes.orderTracking,
                    extra: _order,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Continue shopping',
                  variant: AppButtonVariant.outline,
                  height: 52,
                  onPressed: () => context.go(AppRoutes.shop),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
