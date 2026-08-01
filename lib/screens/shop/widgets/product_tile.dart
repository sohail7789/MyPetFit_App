import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';
import '../../../models/product_palette.dart';
import '../../../widgets/paw_mark.dart';

/// Formats a price the way the design does — rupees, Indian digit grouping,
/// no decimals.
String formatPrice(double value) {
  final whole = value.round().toString();
  if (whole.length <= 3) return '${AppConstants.currencySymbol}$whole';

  // Indian grouping: last three digits, then pairs.
  final last3 = whole.substring(whole.length - 3);
  var rest = whole.substring(0, whole.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${AppConstants.currencySymbol}${groups.join(',')},$last3';
}

/// Product artwork over the category tint. Falls back to the design's paw
/// motif while the photo loads, if the product has none, or if the fetch
/// fails — product photos are remote until the catalog moves to Firebase.
class ProductArt extends StatelessWidget {
  final Product product;
  final double pawSize;
  final BoxFit fit;

  const ProductArt({
    super.key,
    required this.product,
    required this.pawSize,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProductPalette.of(product.category);
    final paw = PawMark(size: pawSize, color: palette.accent, opacity: 0.5);

    if (!product.hasImage) return paw;

    return Image.network(
      product.imageUrl!,
      fit: fit,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : paw,
      errorBuilder: (context, error, stack) => paw,
    );
  }
}

/// The tinted square used on cart rows.
class ProductThumb extends StatelessWidget {
  final Product product;
  final double size;
  final double radius;
  final double pawSize;

  const ProductThumb({
    super.key,
    required this.product,
    required this.size,
    this.radius = 14,
    this.pawSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProductPalette.of(product.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.tint,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ProductArt(product: product, pawSize: pawSize),
      ),
    );
  }
}

/// One card in the two-column recommendations grid.
class ProductTile extends StatelessWidget {
  final Product product;
  final bool inCart;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  const ProductTile({
    super.key,
    required this.product,
    required this.inCart,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProductPalette.of(product.category);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: SizedBox(
              height: 104,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: palette.gradient()),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ProductArt(product: product, pawSize: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Tag(
                      label: product.displayTag,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onOpen,
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AppTheme.ink,
                        height: 1.25,
                      ),
                    ),
                  ),
                  // The design shows a "why" line here; hidden until the
                  // catalog carries that copy.
                  if (product.hasWhy) ...[
                    const SizedBox(height: 6),
                    Text(
                      product.whyPicked,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 11.5,
                        color: AppTheme.body,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPrice(product.price),
                          style: AppTheme.font(
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      _AddButton(inCart: inCart, onTap: onAdd),
                    ],
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.font(
          size: 10,
          weight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool inCart;
  final VoidCallback onTap;

  const _AddButton({required this.inCart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: inCart ? 12 : 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inCart ? AppTheme.tint : AppTheme.action,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inCart) ...[
              const Icon(Icons.check_rounded, size: 13, color: AppTheme.action),
              const SizedBox(width: 4),
            ],
            Text(
              inCart ? 'Added' : 'Add',
              style: AppTheme.font(
                size: 12,
                weight: FontWeight.w800,
                color: inCart ? AppTheme.action : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
