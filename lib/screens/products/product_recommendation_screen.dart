import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/products_data.dart';
import '../../providers/cart_provider.dart';
import '../../providers/quiz_provider.dart';
import 'widgets/product_card.dart';

/// Shared grid geometry for product grids — max-extent based so it scales
/// from small phones (2 columns) to tablets without overflow.
const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 230,
  mainAxisExtent: 276,
  crossAxisSpacing: AppSpacing.md,
  mainAxisSpacing: AppSpacing.md,
);

class ProductRecommendationScreen extends StatelessWidget {
  const ProductRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quiz = context.watch<QuizProvider>();
    final cart = context.watch<CartProvider>();
    final result = quiz.result;

    final recommendedProducts = result != null
        ? allProducts
            .where((p) => p.recommendedFor.contains(result.category))
            .toList()
        : allProducts;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('Recommended for You'),
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
            if (result != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: result.category.color
                      .withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: result.category.color.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(result.category.icon,
                        color: result.category.color, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Based on your score: ${result.percentageScore}/100',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: result.category.color,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: recommendedProducts.isEmpty
                  ? _EmptyProducts(isDark: isDark)
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: productGridDelegate,
                      itemCount: recommendedProducts.length,
                      itemBuilder: (context, index) =>
                          ProductCard(product: recommendedProducts[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.allProducts),
                child: const Text('View All Products'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final bool isDark;
  const _EmptyProducts({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.tint(
                  isDark, AppTheme.accentBlue, AppTheme.lightAzure),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: isDark ? AppTheme.accentBlue : AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('No recommendations yet',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Browse the full catalog instead.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
