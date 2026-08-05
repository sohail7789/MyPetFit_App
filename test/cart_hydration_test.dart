import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';

import 'support/product_fixtures.dart';

/// The shape CartProvider persists.
String _saved(Map<String, int> idsToQuantities) => jsonEncode([
      for (final e in idsToQuantities.entries)
        {'productId': e.key, 'quantity': e.value},
    ]);

Future<String?> _readStore() async =>
    (await SharedPreferences.getInstance()).getString('cart_items');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('restoring a saved cart', () {
    test('rows stay hidden until the catalog arrives', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'gut-probiotic': 2}),
      });

      final cart = CartProvider();
      await cart.init();

      // The catalog is remote, so there is nothing to show yet — but the
      // saved row must not be lost either.
      expect(cart.isEmpty, isTrue);

      cart.hydrate(testCatalog);
      expect(cart.totalItems, 2);
      expect(cart.items.single.product.id, 'gut-probiotic');
    });

    test('takes the price from the catalog, not from storage', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'joint-mobility': 1}),
      });

      final cart = CartProvider();
      await cart.init();
      // Same product, repriced since the cart was saved.
      cart.hydrate([testProduct(id: 'joint-mobility', price: 1499)]);

      expect(cart.totalPrice, 1499);
    });

    test('an id the catalog does not carry stays pending, not dropped',
        () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'gut-probiotic': 1, 'discontinued': 3}),
      });

      final cart = CartProvider();
      await cart.init();
      cart.hydrate(testCatalog);

      expect(cart.totalItems, 1);

      // A later load that does carry it resolves the row rather than having
      // silently discarded it.
      cart.hydrate([testProduct(id: 'discontinued')]);
      expect(cart.totalItems, 4);
    });

    test('a failed load does not erase the saved cart', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'gut-probiotic': 2}),
      });

      final cart = CartProvider();
      await cart.init();
      // Firestore came back empty; hydrate is a no-op.
      cart.hydrate(const []);

      // Adding something else triggers a persist. The unhydrated row has to
      // survive that write, or the next launch loses it.
      cart.addProduct(testProduct(id: 'dental-chews'));
      await Future<void>.delayed(Duration.zero);

      final stored = jsonDecode((await _readStore())!) as List;
      final ids = {for (final e in stored) e['productId']};
      expect(ids, containsAll(<String>['gut-probiotic', 'dental-chews']));
    });

    test('hydrating twice does not duplicate a row', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'gut-probiotic': 1}),
      });

      final cart = CartProvider();
      await cart.init();
      cart.hydrate(testCatalog);
      cart.hydrate(testCatalog);

      expect(cart.totalItems, 1);
    });

    test('clearing drops rows still waiting on the catalog', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'gut-probiotic': 1}),
      });

      final cart = CartProvider();
      await cart.init();
      cart.clearCart();
      await Future<void>.delayed(Duration.zero);

      // Nothing may come back when the catalog eventually lands.
      cart.hydrate(testCatalog);
      expect(cart.isEmpty, isTrue);
      expect(jsonDecode((await _readStore())!), isEmpty);
    });

    test('removing a pending row keeps it gone', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'gut-probiotic': 1}),
      });

      final cart = CartProvider();
      await cart.init();
      cart.removeProduct('gut-probiotic');
      cart.hydrate(testCatalog);

      expect(cart.isEmpty, isTrue);
    });

    test('acting on a pending row does not write it twice', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': _saved({'gut-probiotic': 2}),
      });

      final cart = CartProvider();
      await cart.init();
      // Added before the catalog resolved the saved row of the same product.
      cart.addProduct(testProduct(id: 'gut-probiotic'));
      await Future<void>.delayed(Duration.zero);

      final stored = jsonDecode((await _readStore())!) as List;
      final ids = [for (final e in stored) e['productId']];
      expect(ids, ['gut-probiotic']);
    });

    test('a corrupt payload starts empty rather than throwing', () async {
      SharedPreferences.setMockInitialValues({'cart_items': 'not json'});

      final cart = CartProvider();
      await cart.init();
      cart.hydrate(testCatalog);

      expect(cart.isEmpty, isTrue);
      expect(cart.isLoaded, isTrue);
    });
  });
}
