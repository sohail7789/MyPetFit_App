import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  /// The catalog source. Injectable so tests (and any future local/offline
  /// source) can supply products without reaching Firestore.
  final FirestoreService _service;

  ProductProvider({FirestoreService? service})
      : _service = service ?? FirestoreService();

  List<Product> _products = [];

  bool _loading = false;

  String? _error;

  List<Product> get products => _products;

  bool get loading => _loading;

  String? get error => _error;

  Future<void> loadProducts() async {
    try {
      _loading = true;

      notifyListeners();

      _products =
          await _service.getProducts();
    } catch (e) {
      // Kept as a flag, not a message: the shop shows its own wording and
      // reads this only to tell "could not load" from "nothing published".
      _error = e.toString();

      // A catalog that will not load is an ordinary offline condition with a
      // retry already on screen, so it is not reported to Crashlytics. It is
      // logged for a developer and nowhere else — the previous version
      // printed the whole catalog, name by name, into release logs on every
      // load.
      if (kDebugMode) {
        debugPrint('Catalog load failed: $e');
      }
    }

    _loading = false;

    notifyListeners();
  }
}