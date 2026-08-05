import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import 'widgets/product_tile.dart';

/// Screen 24 — recommended products.
///
/// The design's copy frames these as picks driven by the report. The catalog
/// carries no per-band field, so `featured` stands in for that: featured
/// products lead once an assessment exists, and the ordering stays editable
/// from Firestore rather than being compiled in.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _all = 'All';
  String _filter = _all;

  List<String> _filtersOf(List<Product> catalog) {
    final categories = {
      for (final p in catalog)
        if (p.category.isNotEmpty) p.category,
    }.toList()
      ..sort();
    return [_all, ...categories];
  }

  /// Grid tile height. The artwork band is a fixed 104; everything under it
  /// is text plus the stepper, so that part is scaled by the platform font
  /// setting rather than assumed.
  static double _tileExtent(BuildContext context) {
    // Fixed: artwork band, card padding, the stepper strip, and the two gaps
    // (name→why, price→stepper), none of which scale with the font setting.
    const fixed = 104.0 + 23 + QuantityControl.height + 8 + 6;
    // Scales: two lines of name at 13.5/1.25, two of why-copy at 11.5/1.4,
    // and the price line at 15/1.25.
    const scaling = 33.75 + 32.2 + 18.75;
    // Plus a little headroom — the cost of over-allocating is a few px of
    // white space, the cost of under-allocating is cropped copy.
    return fixed + MediaQuery.textScalerOf(context).scale(scaling) + 6;
  }

  List<Product> _visible(List<Product> catalog, QuizProvider quiz) {
    // Featured first once there's a score to justify calling them picks;
    // without one the catalog stands on its own order.
    final ordered = quiz.result == null
        ? catalog
        : [
            ...catalog.where((p) => p.featured),
            ...catalog.where((p) => !p.featured),
          ];

    if (_filter == _all) return ordered;
    return ordered.where((p) => p.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final quiz = context.watch<QuizProvider>();
    final catalog = context.watch<ProductProvider>();
    // The design personalises this ("Bruno's picks"); fall back to a neutral
    // heading before a pet profile exists.
    final pet = context.watch<PetInfoProvider>().activePet;
    final heading = (pet?.name.trim().isNotEmpty ?? false)
        ? "${pet!.name}'s picks"
        : 'Recommended for you';
    final products = _visible(catalog.products, quiz);

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              heading: heading,
              cartCount: cart.totalItems,
              onCart: () => context.push(AppRoutes.cart),
            ),
            // Only worth showing once there is a catalog to filter.
            if (catalog.products.isNotEmpty)
              _FilterRow(
                filters: _filtersOf(catalog.products),
                selected: _filter,
                onSelect: (f) => setState(() => _filter = f),
              ),
            Expanded(
              child: products.isEmpty
                  ? _CatalogPlaceholder(
                      loading: catalog.loading,
                      error: catalog.error,
                      // A category with nothing in it is a different message
                      // from a catalog that hasn't arrived.
                      filtered: catalog.products.isNotEmpty,
                      onRetry: () =>
                          context.read<ProductProvider>().loadProducts(),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        // Image (104) + 2-line name + 2-line why-line +
                        // price + stepper. The text part of that grows with
                        // the platform font scale, so the tile has to grow
                        // with it — a fixed extent clipped the stepper off
                        // the bottom of the card on devices set above 1.0.
                        mainAxisExtent: _tileExtent(context),
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final product = products[i];
                        return ProductTile(
                          product: product,
                          quantity: cart.quantityOf(product.id),
                          onOpen: () => context.push(
                            '${AppRoutes.productDetail}/${product.id}',
                          ),
                          onQuantityChanged: (q) =>
                              cart.setQuantity(product, q),
                        );
                      },
                    ),
            ),
            if (cart.totalItems > 0)
              _ViewCartBar(
                count: cart.totalItems,
                subtotal: cart.totalPrice,
                onTap: () => context.push(AppRoutes.cart),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String heading;
  final int cartCount;
  final VoidCallback onCart;

  const _Header({
    required this.heading,
    required this.cartCount,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKED FROM THE REPORT',
                  style: AppTheme.font(
                    size: 11,
                    weight: FontWeight.w700,
                    color: context.c.startText,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.t.h3.copyWith(letterSpacing: -0.8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CartButton(count: cartCount, onTap: onCart),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CartButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count == 0 ? 'Cart' : 'Cart, $count items',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.c.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 21,
                  color: context.c.actionText,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: context.c.start,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: AppTheme.font(
                        size: 11,
                        weight: FontWeight.w800,
                        color: context.c.onAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in for the grid while the catalog is loading, unreachable, or
/// genuinely empty.
///
/// The three cases read very differently to someone waiting on their picks,
/// so they get their own copy rather than one shared "nothing here".
class _CatalogPlaceholder extends StatelessWidget {
  final bool loading;
  final String? error;

  /// True when a catalog did arrive and the current filter simply matches
  /// nothing — as opposed to having no catalog at all.
  final bool filtered;

  final VoidCallback onRetry;

  const _CatalogPlaceholder({
    required this.loading,
    required this.error,
    required this.filtered,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(context.c.action),
        ),
      );
    }

    if (filtered) {
      return Center(
        child: Text(
          'Nothing in this category yet.',
          style: context.t.bodyText,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error == null
                  ? Icons.inventory_2_outlined
                  : Icons.cloud_off_rounded,
              size: 44,
              color: context.c.dotInactive,
            ),
            const SizedBox(height: 14),
            Text(
              error == null ? 'No products yet' : "Couldn't load the shop",
              style: context.t.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error == null
                  ? 'The catalog is empty right now. Check back once products '
                      'have been published.'
                  : 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: context.t.bodyText,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Try again',
              variant: AppButtonVariant.outline,
              height: 52,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final active = filter == selected;
          return GestureDetector(
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? context.c.action : context.c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                border: Border.all(
                  color: active ? context.c.actionText : context.c.border,
                ),
              ),
              child: Text(
                filter,
                style: AppTheme.font(
                  size: 13,
                  weight: FontWeight.w700,
                  color: active ? context.c.onAccent : context.c.body,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sticky bar that appears once the cart has anything in it.
class _ViewCartBar extends StatelessWidget {
  final int count;
  final double subtotal;
  final VoidCallback onTap;

  const _ViewCartBar({
    required this.count,
    required this.subtotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(top: BorderSide(color: context.c.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppTheme.ctaHeightCompact,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.c.action,
            borderRadius: BorderRadius.circular(28),
            boxShadow: context.c.ctaShadow,
          ),
          child: Text(
            'View cart · $count ${count == 1 ? 'item' : 'items'} · '
            '${formatPrice(subtotal)}',
            style: context.t.button,
          ),
        ),
      ),
    );
  }
}
