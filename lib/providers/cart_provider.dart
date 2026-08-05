import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  static const _key = 'cart_items';

  final List<CartItem> _items = [];
  bool _isLoaded = false;

  /// Saved `productId -> quantity` pairs that haven't been matched to a
  /// product yet.
  ///
  /// The catalog now comes from Firestore, so it arrives after the cart has
  /// read its own storage. Only ids and quantities are persisted — never the
  /// product itself — so a price or name edited in Firestore is picked up on
  /// the next launch instead of the cart quoting a stale figure back.
  final Map<String, int> _pending = {};

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isLoaded => _isLoaded;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool isInCart(String productId) =>
      _items.any((item) => item.product.id == productId);

  int quantityOf(String productId) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  /// Reads the persisted cart into [_pending]. The rows only become visible
  /// once [hydrate] has matched them against a loaded catalog.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        for (final entry in list) {
          final map = entry as Map<String, dynamic>;
          final id = map['productId'] as String? ?? '';
          final qty = (map['quantity'] as num?)?.toInt() ?? 0;
          if (id.isEmpty || qty <= 0) continue;
          _pending[id] = qty;
        }
      } catch (_) {
        // Corrupt payload — start empty.
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Matches anything [init] read against [catalog].
  ///
  /// Safe to call on every catalog change: an id already in the cart is
  /// skipped, and ids the catalog doesn't carry stay pending rather than
  /// being dropped — a failed or partial load shouldn't quietly empty
  /// someone's cart. They resolve if a later load includes them.
  void hydrate(List<Product> catalog) {
    if (_pending.isEmpty || catalog.isEmpty) return;

    var matched = false;
    for (final product in catalog) {
      final quantity = _pending[product.id];
      if (quantity == null) continue;
      _pending.remove(product.id);
      if (_items.any((i) => i.product.id == product.id)) continue;
      _items.add(CartItem(product: product, quantity: quantity));
      matched = true;
    }
    if (matched) notifyListeners();
  }

  void addProduct(Product product) {
    final idx = _items.indexWhere((item) => item.product.id == product.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    } else {
      _items.add(CartItem(product: product));
    }
    _persist();
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _pending.remove(productId);
    _persist();
    notifyListeners();
  }

  /// Sets [product]'s quantity outright, adding it if it isn't in the cart
  /// yet and removing it at zero. The quantity steppers drive this, so they
  /// don't have to care whether the row already exists.
  void setQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeProduct(product.id);
      return;
    }
    final idx = _items.indexWhere((item) => item.product.id == product.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    _persist();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
      _persist();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    // Also drop anything still waiting on the catalog, otherwise an
    // unhydrated row would survive the clear and reappear on next launch.
    _pending.clear();
    _persist();
    notifyListeners();
  }

  /// Wipe both in-memory state and the persisted key. Called on sign-out.
  Future<void> reset() async {
    _items.clear();
    _pending.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  /// Writes the visible rows *and* anything still waiting on the catalog, so
  /// a launch that never reached Firestore doesn't erase the saved cart.
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final visible = {for (final i in _items) i.product.id};
    final payload = [
      for (final i in _items)
        {'productId': i.product.id, 'quantity': i.quantity},
      // A row the user has acted on takes precedence over the same id still
      // sitting in _pending, so the same product is never written twice.
      for (final entry in _pending.entries)
        if (!visible.contains(entry.key))
          {'productId': entry.key, 'quantity': entry.value},
    ];
    await prefs.setString(_key, jsonEncode(payload));
  }
}
