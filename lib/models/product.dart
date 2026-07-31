import 'score_result.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;

  /// Emoji shown while the image loads, and as the fallback when
  /// [imageUrl] is null or fails to load.
  final String emoji;

  /// Remote product photo. Must be **https** — plain http is blocked by
  /// Android's cleartext policy and iOS App Transport Security.
  /// Leave null to show the emoji instead.
  final String? imageUrl;

  final List<HealthCategory> recommendedFor;
  final String category;
  final double rating;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    this.imageUrl,
    required this.recommendedFor,
    required this.category,
    this.rating = 4.0,
  });

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  /// Present so a future Firestore-backed catalog can decode documents
  /// without touching call sites. Unknown categories are ignored rather
  /// than throwing, so one bad row can't break the whole listing.
  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        emoji: map['emoji'] as String? ?? '📦',
        imageUrl: map['imageUrl'] as String?,
        recommendedFor: ((map['recommendedFor'] as List?) ?? const [])
            .map((e) => HealthCategory.values
                .where((c) => c.name == e)
                .firstOrNull)
            .whereType<HealthCategory>()
            .toList(),
        category: map['category'] as String? ?? 'Other',
        rating: (map['rating'] as num?)?.toDouble() ?? 4.0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'emoji': emoji,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'recommendedFor': recommendedFor.map((c) => c.name).toList(),
        'category': category,
        'rating': rating,
      };
}
