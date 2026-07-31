import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/products_data.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import 'product_recommendation_screen.dart' show productGridDelegate;
import 'widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedCategory;

  List<String> get _categories {
    final cats = allProducts.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == null) return allProducts;
    return allProducts
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  void _select(String? category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        actions: [
          Badge(
            label: Text('${cart.totalItems}'),
            isLabelVisible: cart.totalItems > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_rounded),
              onPressed: () => context.push(AppRoutes.cart),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      showCheckmark: false,
                      onSelected: (_) => _select(null),
                    ),
                  ),
                  ..._categories.map((cat) => Padding(
                        padding:
                            const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          showCheckmark: false,
                          onSelected: (_) => _select(
                              _selectedCategory == cat ? null : cat),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              // Animate the filter change instead of hard-swapping.
              child: AnimatedSwitcher(
                duration: AppMotion.base,
                switchInCurve: AppMotion.curve,
                switchOutCurve: AppMotion.curve,
                child: GridView.builder(
                  key: ValueKey(_selectedCategory),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: productGridDelegate,
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) =>
                      ProductCard(product: _filteredProducts[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
