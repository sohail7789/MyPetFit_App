import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/products_data.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  static const _key = 'cart_items';

  final List<CartItem> _items = [];
  bool _isLoaded = false;

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

  /// Load persisted cart. Any product ids that no longer exist in the
  /// catalog are silently dropped.
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
          final product = _lookupProduct(id);
          if (product == null) continue;
          _items.add(CartItem(product: product, quantity: qty));
        }
      } catch (_) {
        // Corrupt payload — start empty.
      }
    }
    _isLoaded = true;
    notifyListeners();
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
    _persist();
    notifyListeners();
  }

  /// Wipe both in-memory state and the persisted key. Called on sign-out.
  Future<void> reset() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  Product? _lookupProduct(String id) {
    for (final p in allProducts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _items
        .map((i) => {'productId': i.product.id, 'quantity': i.quantity})
        .toList();
    await prefs.setString(_key, jsonEncode(payload));
  }
}
