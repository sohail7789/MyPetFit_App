import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/products_data.dart';
import '../../models/product.dart';
import '../../models/product_palette.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import 'widgets/product_tile.dart';

/// Screen 25 — product detail.
class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final product =
        allProducts.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        backgroundColor: context.c.surface,
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Text('Product not found', style: context.t.bodyText),
        ),
      );
    }

    final cart = context.watch<CartProvider>();
    final palette = ProductPalette.of(context, product.category);
    final quantity = cart.quantityOf(product.id);

    return Scaffold(
      backgroundColor: context.c.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(product: product, palette: palette),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 12),
              children: [
                Text(
                  product.name,
                  style: AppTheme.font(
                    size: 23,
                    weight: FontWeight.w800,
                    color: context.c.ink,
                    letterSpacing: -0.7,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPrice(product.price),
                  style: AppTheme.font(
                    size: 22,
                    weight: FontWeight.w800,
                    color: context.c.actionText,
                  ),
                ),
                // "Why it's in the picks" — only once the catalog carries
                // that copy; the description stands in until then.
                const SizedBox(height: 14),
                _WhyCard(
                  text: product.hasWhy ? product.whyPicked : product.description,
                ),
                if (product.hasBullets) ...[
                  const SizedBox(height: 18),
                  Text(
                    'What it does',
                    style: context.t.cardTitle,
                  ),
                  const SizedBox(height: 10),
                  for (final bullet in product.bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _Bullet(text: bullet),
                    ),
                ],
                if (product.rating != null) ...[
                  const SizedBox(height: 16),
                  _Rating(rating: product.rating!),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.c.surface,
              border: Border(top: BorderSide(color: context.c.borderSoft)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
            // Once it's in the cart the bar becomes a stepper plus a way
            // through to the cart, so the quantity can be corrected here
            // rather than only on the cart screen.
            child: quantity == 0
                ? AppButton(
                    label: 'Add to cart · ${formatPrice(product.price)}',
                    height: AppTheme.ctaHeightCompact,
                    onPressed: () => cart.setQuantity(product, 1),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 132,
                        child: QuantityControl(
                          quantity: quantity,
                          barHeight: AppTheme.ctaHeightCompact,
                          onChanged: (q) => cart.setQuantity(product, q),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'View cart',
                          variant: AppButtonVariant.tinted,
                          height: AppTheme.ctaHeightCompact,
                          onPressed: () => context.push(AppRoutes.cart),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Product product;
  final ProductPalette palette;

  const _Hero({required this.product, required this.palette});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 230 + topInset,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: palette.gradient(context, start: 0, end: 0.7),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(60, 24, 60, 20),
                child: ProductArt(product: product, pawSize: 86),
              ),
            ),
          ),
          Positioned(
            top: topInset + 12,
            left: 22,
            child: CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 42,
              floating: true,
              semanticLabel: 'Back',
              onPressed: () => context.backOr(AppRoutes.shop),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.c.onAccent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                product.displayTag.toUpperCase(),
                style: AppTheme.font(
                  size: 11,
                  weight: FontWeight.w800,
                  color: palette.accent,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  final String text;

  const _WhyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: context.c.tintPanel,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DesignImage(AppAssets.emoTilt, width: 34, height: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHY IT’S IN THE PICKS',
                  style: AppTheme.font(
                    size: 12,
                    weight: FontWeight.w800,
                    color: context.c.startText,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(text, style: context.t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2, right: 10),
          child: Icon(Icons.check_rounded, size: 15, color: context.c.successText),
        ),
        Expanded(child: Text(text, style: context.t.bodySmall)),
      ],
    );
  }
}

class _Rating extends StatelessWidget {
  final double rating;

  const _Rating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 5; i++)
            Icon(
              Icons.star_rounded,
              size: 14,
              color: i < rating.round() ? context.c.star : context.c.dotInactive,
            ),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: AppTheme.font(
              size: 13,
              weight: FontWeight.w700,
              color: context.c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
