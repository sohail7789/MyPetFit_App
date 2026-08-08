/// Which products are offered for an area of health.
///
/// Extracted from the dashboard unchanged. Two surfaces now recommend against
/// a pet's weakest area — the dashboard card and the analytics overview — and
/// a second copy of this mapping would be a second chance for them to
/// recommend different things for the same pet on the same day. One function,
/// one rule, both callers.
///
/// It lives in `data/` rather than in `analytics/` on purpose: [Product] is a
/// Firestore-backed type, and the analytics domain must stay free of cloud
/// dependencies so it can run in a portal backend, a digest job or a PDF
/// renderer. Analytics names a category; this turns a category into stock.
library;

import '../models/product.dart';

/// Products tagged for [category], in the order the catalog returned them.
///
/// Deterministic and explicit: matched against each product's
/// `recommendedFor`, so nothing is inferred from a product's name,
/// description or shop category and an item appears only because someone put
/// it there.
///
/// No ranking. Firestore order is merchandising's order, and inventing a sort
/// here would quietly override it.
List<Product> recommendedProducts(List<Product> catalog, String category) =>
    catalog.where((p) => p.recommendedFor.contains(category)).toList();
