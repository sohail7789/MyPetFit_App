import '../models/product.dart';
import '../models/score_result.dart';

// ─────────────────────────────────────────────────────────────────────────
//  PRODUCT CATALOG
//
//  Sourced from mypetfit.in (the three products live at time of writing).
//  Names, prices, descriptions and benefit bullets are taken from the
//  product pages; `whyPicked` compresses each page's own description into
//  one line and should be reviewed before launch.
//
//  Prices are marked "Tentative" on the website — confirm before shipping.
//
//  `recommendedFor` currently lists every band so nothing is hidden from
//  any user. Narrow it once the product team decides which score bands each
//  supplement should be surfaced to.
// ─────────────────────────────────────────────────────────────────────────

const _allBands = <HealthCategory>[
  HealthCategory.critical,
  HealthCategory.needsImprovement,
  HealthCategory.good,
  HealthCategory.excellent,
];

const List<Product> allProducts = [
  Product(
    id: 'calm-your-pet',
    name: 'Calm Your Pet',
    description:
        'Natural neuro-calming formulation designed to support relaxation '
        'and emotional wellness in pets without causing sedation. The '
        'formulation maintains alertness and natural personality while '
        'promoting calm.',
    whyPicked:
        'Neuro-calming support for stress and anxiety, without sedation.',
    bullets: [
      'Helps reduce stress and anxiety',
      'Supports calm behaviour',
      'Non-sedative formulation',
      'Maintains alertness and responsiveness',
      'Daily emotional wellness support',
    ],
    price: 799,
    emoji: '🌿',
    imageUrl:
        'https://www.mypetfit.in/MPF-%20Calm%20Your%20Pet%20%28NS%29.png',
    category: 'Calming',
    tag: 'Calming',
    recommendedFor: _allBands,
  ),
  Product(
    id: 'extend-lifespan',
    name: "Extend Your Pet's Lifespan",
    description:
        'A premium longevity-focused nutraceutical formulation designed to '
        'support healthy ageing in pets. The supplement targets '
        'inflammation, oxidative stress, metabolism, and mobility to improve '
        'long-term quality of life.',
    whyPicked:
        'Targets inflammation, oxidative stress, metabolism and mobility for '
        'healthy ageing.',
    bullets: [
      'Supports healthy ageing',
      'Joint and mobility support',
      'Helps reduce oxidative stress',
      'Supports metabolic wellness',
      'Daily longevity support',
    ],
    price: 1499,
    emoji: '⏳',
    imageUrl:
        "https://www.mypetfit.in/MPF%20-%20Extend%20Your%20Pet%27s%20Lifespan.png",
    category: 'Longevity',
    tag: 'Longevity',
    recommendedFor: _allBands,
  ),
  Product(
    id: 'calmx-pet-companion',
    name: 'CalmX Pet Companion',
    description:
        'CalmX Pet Companion is a clinically positioned calming supplement '
        'developed for pets experiencing anxiety, stress-related behaviour, '
        'and nervous system imbalance. It promotes calmness without '
        'drowsiness and supports long-term emotional health.',
    whyPicked:
        'Calming support for anxiety and nervous-system balance, non-drowsy.',
    bullets: [
      'Supports calm alertness',
      'Helps manage stress response',
      'Nervous system support',
      'Non-drowsy calming solution',
      'High palatability soft-chew format',
    ],
    price: 999,
    emoji: '🐾',
    imageUrl:
        'https://www.mypetfit.in/MPF%20-%20CalmX%20Pet%20Companion%20%28NS%29.png',
    category: 'Calming',
    tag: 'Calming',
    recommendedFor: _allBands,
  ),
];
