import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/products_data.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import 'widgets/product_tile.dart';

/// Screen 24 — recommended products.
///
/// The design's copy frames these as picks driven by the report, so when an
/// assessment exists the list leads with products matching its band.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _all = 'All';
  String _filter = _all;

  List<String> get _filters {
    final categories = {for (final p in allProducts) p.category}.toList()
      ..sort();
    return [_all, ...categories];
  }

  List<Product> _visible(QuizProvider quiz) {
    final band = quiz.result?.category;

    // Recommended first when we have a score, then the rest of the catalog.
    final ordered = band == null
        ? allProducts
        : [
            ...allProducts.where((p) => p.recommendedFor.contains(band)),
            ...allProducts.where((p) => !p.recommendedFor.contains(band)),
          ];

    if (_filter == _all) return ordered;
    return ordered.where((p) => p.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final quiz = context.watch<QuizProvider>();
    // The design personalises this ("Bruno's picks"); fall back to a neutral
    // heading before a pet profile exists.
    final pet = context.watch<PetInfoProvider>().activePet;
    final heading = (pet?.name.trim().isNotEmpty ?? false)
        ? "${pet!.name}'s picks"
        : 'Recommended for you';
    final products = _visible(quiz);

    return Scaffold(
      backgroundColor: AppTheme.surface,
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
            _FilterRow(
              filters: _filters,
              selected: _filter,
              onSelect: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing in this category yet.',
                        style: AppTheme.bodyText,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        // Fits image (104) + 2-line name + 2-line why-line
                        // + price row without overflowing.
                        mainAxisExtent: 252,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final product = products[i];
                        return ProductTile(
                          product: product,
                          inCart: cart.items
                              .any((c) => c.product.id == product.id),
                          onOpen: () => context.push(
                            '${AppRoutes.productDetail}/${product.id}',
                          ),
                          onAdd: () => cart.addProduct(product),
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
                    color: AppTheme.start,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.h3.copyWith(letterSpacing: -0.8),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F1F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 21,
                  color: AppTheme.action,
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
                      color: AppTheme.start,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: AppTheme.font(
                        size: 11,
                        weight: FontWeight.w800,
                        color: Colors.white,
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
                color: active ? AppTheme.action : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                border: Border.all(
                  color: active ? AppTheme.action : AppTheme.border,
                ),
              ),
              child: Text(
                filter,
                style: AppTheme.font(
                  size: 13,
                  weight: FontWeight.w700,
                  color: active ? Colors.white : AppTheme.body,
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
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppTheme.ctaHeightCompact,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.action,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.ctaShadow,
          ),
          child: Text(
            'View cart · $count ${count == 1 ? 'item' : 'items'} · '
            '${formatPrice(subtotal)}',
            style: AppTheme.button,
          ),
        ),
      ),
    );
  }
}
