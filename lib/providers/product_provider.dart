import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService _service =
      FirestoreService();

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

      debugPrint(
          'Products Loaded : ${_products.length}');

      for (final product in _products) {
        debugPrint(product.name);
      }
    } catch (e) {
      _error = e.toString();

      debugPrint(_error);
    }

    _loading = false;

    notifyListeners();
  }
}