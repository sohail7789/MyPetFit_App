import '../models/product.dart';
import '../models/score_result.dart';

// ─────────────────────────────────────────────────────────────────────────
//  PRODUCT CATALOG
//
//  This is the single place to edit the shop. Add, remove, or change
//  entries below — nothing else in the app needs to be touched.
//
//  FIELDS
//    id             Unique, never reuse or change once live. Cart contents
//                   are persisted by id, so changing one drops it from
//                   existing users' carts.
//    name           Shown on the card. Keep under ~40 chars so it fits two
//                   lines without truncating.
//    description    Full sentence. Shown on the product detail/summary.
//    price          Number, no currency symbol (the UI adds "$").
//    emoji          Shown while the photo loads and if it fails. Always set
//                   one, even when imageUrl is present.
//    imageUrl       OPTIONAL remote photo. MUST be https (plain http is
//                   blocked on both Android and iOS). Square images around
//                   600x600 look best. Omit the line entirely for no photo.
//    recommendedFor Which quiz outcomes surface this product. Options:
//                     HealthCategory.critical
//                     HealthCategory.needsImprovement
//                     HealthCategory.good
//                     HealthCategory.excellent
//                   List as many as apply. An empty list means the product
//                   only appears under "All Products".
//    category       Filter chip label on the All Products screen. Reuse an
//                   existing value to avoid creating a new chip:
//                     Nutrition | Supplements | Accessories
//                     Dental    | Grooming    | Toys
//    rating         0.0–5.0, shown next to the star.
//
//  TEMPLATE — copy this block for each new product:
//
//    Product(
//      id: 'p21',
//      name: 'Product Name',
//      description: 'One clear sentence about what it does.',
//      price: 24.99,
//      emoji: '🦴',
//      imageUrl: 'https://your-host.com/images/product.jpg',
//      recommendedFor: [HealthCategory.good],
//      category: 'Nutrition',
//      rating: 4.5,
//    ),
//
// ─────────────────────────────────────────────────────────────────────────

const List<Product> allProducts = [
  // Critical + Needs Improvement products
  Product(
    id: 'p1',
    name: 'Emergency Nutrition Pack',
    description: 'High-calorie recovery formula for pets needing nutritional support.',
    price: 34.99,
    emoji: '🥫',
    recommendedFor: [HealthCategory.critical],
    category: 'Nutrition',
    rating: 4.8,
  ),
  Product(
    id: 'p2',
    name: 'Immune Boost Supplement',
    description: 'Veterinary-grade immune system support with vitamins and antioxidants.',
    price: 29.99,
    emoji: '💊',
    recommendedFor: [HealthCategory.critical, HealthCategory.needsImprovement],
    category: 'Supplements',
    rating: 4.7,
  ),
  Product(
    id: 'p3',
    name: 'Recovery Diet Food',
    description: 'Easily digestible, nutrient-rich food for pets recovering from illness.',
    price: 42.99,
    emoji: '🍖',
    recommendedFor: [HealthCategory.critical],
    category: 'Nutrition',
    rating: 4.6,
  ),
  Product(
    id: 'p4',
    name: 'Calming Aid Treats',
    description: 'Natural calming treats to reduce anxiety and stress in pets.',
    price: 19.99,
    emoji: '🌿',
    recommendedFor: [HealthCategory.critical, HealthCategory.needsImprovement],
    category: 'Supplements',
    rating: 4.5,
  ),
  Product(
    id: 'p5',
    name: 'Vet Visit Prep Kit',
    description: 'Everything you need to prepare for a productive vet visit.',
    price: 15.99,
    emoji: '🩺',
    recommendedFor: [HealthCategory.critical],
    category: 'Accessories',
    rating: 4.3,
  ),

  // Needs Improvement products
  Product(
    id: 'p6',
    name: 'Joint Support Supplement',
    description: 'Glucosamine and chondroitin formula for healthy joints and mobility.',
    price: 27.99,
    emoji: '🦴',
    recommendedFor: [HealthCategory.needsImprovement, HealthCategory.good],
    category: 'Supplements',
    rating: 4.7,
  ),
  Product(
    id: 'p7',
    name: 'Dental Chew Value Pack',
    description: 'Daily dental chews that reduce tartar and freshen breath.',
    price: 22.99,
    emoji: '🦷',
    recommendedFor: [HealthCategory.needsImprovement, HealthCategory.good],
    category: 'Dental',
    rating: 4.5,
  ),
  Product(
    id: 'p8',
    name: 'Premium Diet Food',
    description: 'Balanced nutrition with real meat, vegetables, and essential vitamins.',
    price: 49.99,
    emoji: '🥩',
    recommendedFor: [HealthCategory.needsImprovement],
    category: 'Nutrition',
    rating: 4.6,
  ),
  Product(
    id: 'p9',
    name: 'Interactive Puzzle Toy Set',
    description: 'Mental stimulation toys to keep your pet engaged and sharp.',
    price: 24.99,
    emoji: '🧩',
    recommendedFor: [HealthCategory.needsImprovement, HealthCategory.good],
    category: 'Toys',
    rating: 4.4,
  ),
  Product(
    id: 'p10',
    name: 'Grooming Essentials Kit',
    description: 'Complete grooming set with brush, nail clipper, and shampoo.',
    price: 32.99,
    emoji: '✂️',
    recommendedFor: [HealthCategory.needsImprovement, HealthCategory.good],
    category: 'Grooming',
    rating: 4.5,
  ),

  // Good products
  Product(
    id: 'p11',
    name: 'Multivitamin Chews',
    description: 'Daily multivitamin treats for overall health maintenance.',
    price: 18.99,
    emoji: '🍬',
    recommendedFor: [HealthCategory.good, HealthCategory.excellent],
    category: 'Supplements',
    rating: 4.6,
  ),
  Product(
    id: 'p12',
    name: 'Outdoor Activity Harness',
    description: 'Comfortable, durable harness for walks and outdoor adventures.',
    price: 35.99,
    emoji: '🏃',
    recommendedFor: [HealthCategory.good, HealthCategory.excellent],
    category: 'Accessories',
    rating: 4.7,
  ),
  Product(
    id: 'p13',
    name: 'Dental Spray',
    description: 'Easy-to-use dental spray for daily oral hygiene maintenance.',
    price: 14.99,
    emoji: '💨',
    recommendedFor: [HealthCategory.good],
    category: 'Dental',
    rating: 4.3,
  ),
  Product(
    id: 'p14',
    name: 'Skin & Coat Formula',
    description: 'Omega-3 rich supplement for a shiny coat and healthy skin.',
    price: 23.99,
    emoji: '✨',
    recommendedFor: [HealthCategory.good, HealthCategory.needsImprovement],
    category: 'Supplements',
    rating: 4.5,
  ),
  Product(
    id: 'p15',
    name: 'Digestive Health Probiotic',
    description: 'Probiotic supplement for healthy gut flora and digestion.',
    price: 21.99,
    emoji: '🦠',
    recommendedFor: [HealthCategory.good, HealthCategory.needsImprovement],
    category: 'Supplements',
    rating: 4.4,
  ),

  // Excellent products
  Product(
    id: 'p16',
    name: 'Organic Treat Box',
    description: 'Premium organic treats made with wholesome natural ingredients.',
    price: 28.99,
    emoji: '🎁',
    recommendedFor: [HealthCategory.excellent],
    category: 'Nutrition',
    rating: 4.8,
  ),
  Product(
    id: 'p17',
    name: 'Smart Activity Tracker',
    description: 'Track your pet\'s activity, sleep, and health metrics.',
    price: 59.99,
    emoji: '📱',
    recommendedFor: [HealthCategory.excellent, HealthCategory.good],
    category: 'Accessories',
    rating: 4.6,
  ),
  Product(
    id: 'p18',
    name: 'Luxury Grooming Set',
    description: 'Premium grooming tools with ergonomic design and carrying case.',
    price: 54.99,
    emoji: '💎',
    recommendedFor: [HealthCategory.excellent],
    category: 'Grooming',
    rating: 4.7,
  ),
  Product(
    id: 'p19',
    name: 'Premium Orthopedic Bed',
    description: 'Memory foam bed for ultimate comfort and joint support.',
    price: 79.99,
    emoji: '🛏️',
    recommendedFor: [HealthCategory.excellent, HealthCategory.good],
    category: 'Accessories',
    rating: 4.9,
  ),
  Product(
    id: 'p20',
    name: 'Adventure Toy Bundle',
    description: 'Collection of durable, engaging toys for active pets.',
    price: 39.99,
    emoji: '🎾',
    recommendedFor: [HealthCategory.excellent, HealthCategory.good],
    category: 'Toys',
    rating: 4.5,
  ),
];
