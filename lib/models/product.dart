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

  /// Assessment categories this product is recommended for, named exactly as
  /// `healthCategories` names them — "Skin & Coat Health" and so on.
  ///
  /// Merchandising decides this, not the app: nothing is inferred from the
  /// name, description or category, so a product appears against an area
  /// only because someone put it there. A product may serve several areas.
  ///
  /// Empty for any document written before the field existed, which means it
  /// is never recommended rather than being wrongly recommended everywhere.
  final List<String> recommendedFor;

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
    this.recommendedFor = const [],
    this.createdAt,
  });

  /// Short uppercase label on the product image, e.g. "Supplement".
  ///
  /// Derived, not stored: [productType] is the design's tag when a product
  /// carries one, and [category] is the sensible fallback when it doesn't.
  String get displayTag => productType.trim().isNotEmpty ? productType : category;

  /// Whether the price is a genuine markdown worth striking through.
  bool get hasDiscount => mrp > price && price > 0;

  /// Percentage off, for the savings badge.
  ///
  /// Prefers the stored [discountPercentage] so merchandising can round it
  /// however it likes, and derives one from the prices when that is unset —
  /// a struck-through MRP with no percentage next to it looks unfinished.
  int get savingsPercent {
    if (discountPercentage > 0) return discountPercentage;
    if (!hasDiscount) return 0;
    return (((mrp - price) / mrp) * 100).round();
  }

  /// Stock is low enough to be worth telling the shopper about.
  bool get isLowStock => inStock && stock > 0 && stock <= 5;

  factory Product.fromMap(
    String id,
    Map<String, dynamic> rawMap,
  ) {
    // Field names are typed by hand in the Firebase console, so a stray
    // space rides along now and then — "name " instead of "name". The
    // lookup then misses and the field silently reads as empty, which is
    // far harder to spot than a wrong value: a product simply loses its
    // name everywhere at once. Trimming the keys costs nothing and turns
    // that class of typo into a non-event.
    final map = {
      for (final e in rawMap.entries) e.key.trim(): e.value,
    };

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
      recommendedFor:
          List<String>.from(map['recommendedFor'] ?? []),
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
      'recommendedFor': recommendedFor,
      'createdAt': createdAt,
    };
  }
}