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
  /// Average review score. Null when no rating has been published — the UI
  /// hides the rating row rather than showing a made-up number.
  final double? rating;

  /// One line explaining why the report surfaced this product, shown on the
  /// shop card and the detail page ("Why it's in Bruno's picks").
  ///
  /// Left empty until product copy is written — the UI hides the block rather
  /// than showing placeholder text.
  final String whyPicked;

  /// Three short "What it does" claims on the detail page. Empty hides the
  /// section.
  final List<String> bullets;

  /// Short uppercase tag on the product image, e.g. "Oral care". Falls back
  /// to [category] when unset.
  final String? tag;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    this.imageUrl,
    required this.recommendedFor,
    required this.category,
    this.rating,
    this.whyPicked = '',
    this.bullets = const [],
    this.tag,
  });

  /// Label shown on the product image chip.
  String get displayTag => tag ?? category;

  bool get hasWhy => whyPicked.trim().isNotEmpty;
  bool get hasBullets => bullets.isNotEmpty;

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
        rating: (map['rating'] as num?)?.toDouble(),
        whyPicked: map['whyPicked'] as String? ?? '',
        bullets:
            ((map['bullets'] as List?) ?? const []).whereType<String>().toList(),
        tag: map['tag'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'emoji': emoji,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'recommendedFor': recommendedFor.map((c) => c.name).toList(),
        'category': category,
        if (rating != null) 'rating': rating,
        if (whyPicked.isNotEmpty) 'whyPicked': whyPicked,
        if (bullets.isNotEmpty) 'bullets': bullets,
        if (tag != null) 'tag': tag,
      };
}
