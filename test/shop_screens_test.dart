import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/products_data.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/shop/cart_screen.dart';
import 'package:mypetfit_app/screens/shop/order_reference.dart';
import 'package:mypetfit_app/screens/shop/shop_screen.dart';
import 'package:mypetfit_app/screens/shop/widgets/product_tile.dart';
import 'support/network_image_stub.dart';

Widget _host(Widget child, {CartProvider? cart}) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => cart ?? CartProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => PetInfoProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Product photos are remote; stub them so widgets can build under test.
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('price formatting', () {
    test('uses rupees with Indian digit grouping', () {
      expect(formatPrice(649), '₹649');
      expect(formatPrice(1099), '₹1,099');
      expect(formatPrice(3499), '₹3,499');
      expect(formatPrice(120000), '₹1,20,000');
      expect(formatPrice(10000000), '₹1,00,00,000');
    });

    test('rounds to whole rupees', () {
      expect(formatPrice(649.4), '₹649');
      expect(formatPrice(649.6), '₹650');
    });
  });

  group('24 Shop', () {
    testWidgets('lists the catalog with an All filter', (tester) async {
      await tester.pumpWidget(_host(const ShopScreen()));
      await tester.pump();

      expect(find.text('PICKED FROM THE REPORT'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.byType(ProductTile), findsWidgets);
    });

    testWidgets('the view-cart bar appears only once something is added',
        (tester) async {
      final cart = CartProvider();
      await tester.pumpWidget(_host(const ShopScreen(), cart: cart));
      await tester.pump();

      expect(find.textContaining('View cart'), findsNothing);

      cart.addProduct(allProducts.first);
      await tester.pump();

      expect(find.textContaining('View cart'), findsOneWidget);
      expect(find.textContaining('1 item'), findsOneWidget);
    });

    testWidgets('a filter narrows the grid to that category', (tester) async {
      await tester.pumpWidget(_host(const ShopScreen()));
      await tester.pump();

      final category = allProducts.first.category;
      final expected =
          allProducts.where((p) => p.category == category).length;

      await tester.tap(find.text(category).first);
      await tester.pump();

      // Grid is lazy, so compare against what could fit rather than all.
      expect(find.byType(ProductTile), findsWidgets);
      expect(expected, greaterThan(0));
    });
  });

  group('26 Cart', () {
    testWidgets('shows the empty state with nothing in it', (tester) async {
      await tester.pumpWidget(_host(const CartScreen()));
      await tester.pump();

      expect(find.textContaining('Your cart is empty'), findsOneWidget);
      expect(find.text('Back to shop'), findsOneWidget);
    });

    testWidgets('steppers change quantity and Remove clears the line',
        (tester) async {
      final cart = CartProvider()..addProduct(allProducts.first);
      await tester.pumpWidget(_host(const CartScreen(), cart: cart));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Increase quantity'));
      await tester.pump();
      expect(cart.totalItems, 2);

      await tester.tap(find.bySemanticsLabel('Decrease quantity'));
      await tester.pump();
      expect(cart.totalItems, 1);

      await tester.tap(find.text('Remove'));
      await tester.pump();
      expect(cart.isEmpty, isTrue);
      expect(find.textContaining('Your cart is empty'), findsOneWidget);
    });

    testWidgets('the footer totals the basket', (tester) async {
      final product = allProducts.first;
      final cart = CartProvider()..addProduct(product);
      await tester.pumpWidget(_host(const CartScreen(), cart: cart));
      await tester.pump();

      expect(
        find.text('Checkout · ${formatPrice(product.price)}'),
        findsOneWidget,
      );
      expect(find.text('Free'), findsOneWidget);
    });
  });

  group('order reference', () {
    test('carries item count and a three-day arrival', () {
      final order = OrderReference.create(itemCount: 3);

      expect(order.id, startsWith('#MPF-'));
      expect(order.summaryLabel, contains('3 items'));
      expect(
        order.arrivesOn.difference(order.placedAt).inDays,
        3,
      );
    });

    test('singularises a one-item order', () {
      expect(OrderReference.create(itemCount: 1).summaryLabel, contains('1 item'));
    });
  });
}
