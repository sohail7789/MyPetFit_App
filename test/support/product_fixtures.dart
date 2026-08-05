import 'dart:async';

import 'package:mypetfit_app/models/product.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/services/firestore_service.dart';

/// Builds a product with sensible defaults, so a test only spells out the
/// fields it actually cares about.
Product testProduct({
  required String id,
  String? name,
  String category = 'Supplements',
  String productType = 'Supplement',
  double price = 649,
  double mrp = 799,
  String purpose = 'Supports steady digestion after loose stools.',
  List<String> keyBenefits = const ['Settles the gut', 'Daily use'],
  bool featured = false,
  double rating = 0,
  int reviewCount = 0,
  String imageUrl = '',
}) =>
    Product(
      id: id,
      name: name ?? 'Product $id',
      description: 'A description for $id.',
      purpose: purpose,
      price: price,
      mrp: mrp,
      currency: 'INR',
      brand: 'MyPetFit',
      category: category,
      productType: productType,
      sku: 'SKU-$id',
      slug: id,
      imageUrl: imageUrl,
      weight: '200 g',
      active: true,
      featured: featured,
      inStock: true,
      subscriptionAvailable: false,
      stock: 10,
      discountPercentage: 0,
      reviewCount: reviewCount,
      rating: rating,
      keyBenefits: keyBenefits,
      idealUsage: const ['Daily'],
      targetPets: const ['Dog'],
    );

/// A small catalog spanning two categories, one of them featured.
final List<Product> testCatalog = [
  testProduct(
    id: 'gut-probiotic',
    name: 'Gut Probiotic Powder',
    category: 'Nutrition',
    featured: true,
    rating: 4.5,
    reviewCount: 1284,
  ),
  testProduct(
    id: 'joint-mobility',
    name: 'Joint Mobility Supplement',
    category: 'Supplements',
    price: 1099,
  ),
  testProduct(
    id: 'dental-chews',
    name: 'Daily Dental Chews',
    category: 'Dental',
    price: 649,
  ),
];

/// Stands in for Firestore, returning whatever catalog a test hands it.
class FakeCatalogService implements FirestoreService {
  FakeCatalogService(this.products, {this.error});

  final List<Product> products;
  final Object? error;

  @override
  Future<List<Product>> getProducts() async {
    if (error != null) throw error!;
    return products;
  }
}

/// A [ProductProvider] already holding [catalog], as if the load had landed.
Future<ProductProvider> loadedCatalog([List<Product>? catalog]) async {
  final provider = loadedTestCatalog(catalog);
  await provider.loadProducts();
  return provider;
}

/// The synchronous form, for `MultiProvider`'s `create:` which can't await.
/// The fetch resolves on the next microtask, so the first `pump` has it.
ProductProvider loadedTestCatalog([List<Product>? catalog]) {
  final provider =
      ProductProvider(service: FakeCatalogService(catalog ?? testCatalog));
  unawaited(provider.loadProducts());
  return provider;
}

/// A catalog source whose fetch never settles, for asserting on the
/// loading state.
class PendingCatalogService implements FirestoreService {
  final _completer = Completer<List<Product>>();

  @override
  Future<List<Product>> getProducts() => _completer.future;
}

/// A [ProductProvider] stuck mid-load.
ProductProvider pendingCatalog() {
  final provider = ProductProvider(service: PendingCatalogService());
  // Deliberately not awaited — the fetch never completes.
  unawaited(provider.loadProducts());
  return provider;
}

/// A provider that never touches Firestore, for screens that merely need one
/// in scope. Constructing a bare [ProductProvider] in a test would reach for
/// `FirebaseFirestore.instance` and throw.
ProductProvider emptyCatalog() =>
    ProductProvider(service: FakeCatalogService(const []));
