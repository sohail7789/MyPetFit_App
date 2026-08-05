import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String purpose;

  final double price;
  final double mrp;

  final String currency;
  final String brand;
  final String category;
  final String productType;

  final String sku;
  final String slug;

  final String imageUrl;
  final String weight;

  final bool active;
  final bool featured;
  final bool inStock;
  final bool subscriptionAvailable;

  final int stock;
  final int discountPercentage;
  final int reviewCount;

  final double rating;

  final List<String> keyBenefits;
  final List<String> idealUsage;
  final List<String> targetPets;

  final Timestamp? createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.purpose,
    required this.price,
    required this.mrp,
    required this.currency,
    required this.brand,
    required this.category,
    required this.productType,
    required this.sku,
    required this.slug,
    required this.imageUrl,
    required this.weight,
    required this.active,
    required this.featured,
    required this.inStock,
    required this.subscriptionAvailable,
    required this.stock,
    required this.discountPercentage,
    required this.reviewCount,
    required this.rating,
    required this.keyBenefits,
    required this.idealUsage,
    required this.targetPets,
    this.createdAt,
  });

  /// Short uppercase label on the product image, e.g. "Supplement".
  ///
  /// Derived, not stored: [productType] is the design's tag when a product
  /// carries one, and [category] is the sensible fallback when it doesn't.
  String get displayTag => productType.trim().isNotEmpty ? productType : category;

  /// Whether the price is a genuine markdown worth striking through.
  bool get hasDiscount => mrp > price && price > 0;

  factory Product.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      purpose: map['purpose'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] ?? 'INR',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      productType: map['productType'] ?? '',
      sku: map['sku'] ?? '',
      slug: map['slug'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      weight: map['weight'] ?? '',
      active: map['active'] ?? true,
      featured: map['featured'] ?? false,
      inStock: map['inStock'] ?? true,
      subscriptionAvailable:
          map['subscriptionAvailable'] ?? false,
      stock: map['stock'] ?? 0,
      discountPercentage:
          map['discountPercentage'] ?? 0,
      reviewCount: map['reviewCount'] ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      keyBenefits:
          List<String>.from(map['keyBenefits'] ?? []),
      idealUsage:
          List<String>.from(map['idealUsage'] ?? []),
      targetPets:
          List<String>.from(map['targetPets'] ?? []),
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'purpose': purpose,
      'price': price,
      'mrp': mrp,
      'currency': currency,
      'brand': brand,
      'category': category,
      'productType': productType,
      'sku': sku,
      'slug': slug,
      'imageUrl': imageUrl,
      'weight': weight,
      'active': active,
      'featured': featured,
      'inStock': inStock,
      'subscriptionAvailable': subscriptionAvailable,
      'stock': stock,
      'discountPercentage': discountPercentage,
      'reviewCount': reviewCount,
      'rating': rating,
      'keyBenefits': keyBenefits,
      'idealUsage': idealUsage,
      'targetPets': targetPets,
      'createdAt': createdAt,
    };
  }
}