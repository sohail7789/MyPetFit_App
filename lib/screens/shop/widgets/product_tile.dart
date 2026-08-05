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
    final palette = ProductPalette.of(context, product.category);
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
    final palette = ProductPalette.of(context, product.category);
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

  /// How many of this product are in the cart. Zero renders the Add button.
  final int quantity;

  final VoidCallback onOpen;

  /// Called with the requested new quantity. Zero removes the product.
  final ValueChanged<int> onQuantityChanged;

  const ProductTile({
    super.key,
    required this.product,
    required this.quantity,
    required this.onOpen,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProductPalette.of(context, product.category);

    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: context.c.border),
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
                      decoration: BoxDecoration(gradient: palette.gradient(context)),
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
                  // Expanded rather than a trailing Spacer: this block both
                  // absorbs slack and gives up height when the grid row is
                  // tighter than the copy would like, so the price and
                  // stepper below can never be pushed past the card's edge.
                  Expanded(
                    child: GestureDetector(
                      onTap: onOpen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The name is unconstrained so it always gets both
                          // its lines in full. Only the secondary "why" copy
                          // below is Flexible, so when the row is tight that
                          // is what gives way — a half-cropped product name
                          // is the one thing here a shopper can't work with.
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: context.c.ink,
                              height: 1.25,
                            ),
                          ),
                          // The design shows a "why" line here; hidden until
                          // the catalog carries that copy.
                          if (product.hasWhy) ...[
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                product.whyPicked,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.font(
                                  size: 11.5,
                                  color: context.c.body,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price above the control rather than beside it. Sharing a
                  // row meant the price got whatever width the button left
                  // over, and "₹799" broke across two lines as "₹79 / 9" the
                  // moment the button widened. Stacking also gives the
                  // stepper a full-width, thumb-sized target.
                  Text(
                    formatPrice(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      size: 15,
                      weight: FontWeight.w800,
                      color: context.c.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  QuantityControl(
                    quantity: quantity,
                    onChanged: onQuantityChanged,
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
        color: context.c.onAccent.withValues(alpha: 0.85),
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

/// Add button that becomes a −/+ stepper once the product is in the cart.
///
/// Previously the tile only ever offered "Add": tapping again re-added, and
/// there was no way back out except the cart screen. Both states occupy the
/// same 38px-tall strip so the tile doesn't reflow when it flips.
class QuantityControl extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  /// Overrides the strip height so the control can sit level with a CTA on
  /// the product detail bar. Defaults to the grid tile's [height].
  final double? barHeight;

  /// Largest quantity the stepper will reach. Deliberately modest — these are
  /// supplements, and a mis-tap shouldn't order twenty tins.
  static const int maxQuantity = 10;

  /// The strip's height, in both states. Exposed so grid delegates can budget
  /// for it instead of hardcoding a matching number.
  static const double height = 38;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    final strip = barHeight ?? height;

    if (quantity <= 0) {
      return Semantics(
        button: true,
        label: 'Add to cart',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(1),
          child: Container(
            height: strip,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.c.action,
              borderRadius: BorderRadius.circular(strip / 2),
            ),
            child: Text(
              'Add',
              style: AppTheme.font(
                size: 13,
                weight: FontWeight.w800,
                color: context.c.onAccent,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: strip,
      decoration: BoxDecoration(
        color: context.c.tint,
        borderRadius: BorderRadius.circular(strip / 2),
        border: Border.all(color: context.c.actionText.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _StepButton(
            size: strip,
            icon: quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            semanticLabel: quantity == 1 ? 'Remove from cart' : 'Decrease',
            onTap: () => onChanged(quantity - 1),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                maxLines: 1,
                style: AppTheme.font(
                  size: 14,
                  weight: FontWeight.w800,
                  color: context.c.actionText,
                ),
              ),
            ),
          ),
          _StepButton(
            size: strip,
            icon: Icons.add_rounded,
            semanticLabel: 'Increase',
            onTap: quantity >= maxQuantity
                ? null
                : () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double size;

  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 17,
            color: onTap == null
                ? context.c.actionText.withValues(alpha: 0.35)
                : context.c.actionText,
          ),
        ),
      ),
    );
  }
}
