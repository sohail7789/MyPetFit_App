import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<List<Product>> getProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => Product.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }
}