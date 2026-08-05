import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Which of the six product panel colourways a category uses.
///
/// Stored rather than the colours themselves: each swatch resolves
/// differently in light and dark, so the pairing has to survive until there
/// is a [BuildContext] to resolve it against.
enum ProductSwatch { blue, orange, green, indigo, rose, violet }

/// Tint and accent for a product's image panel.
///
/// The design assigns a colour per product type; those are mapped onto the
/// catalog's own categories here, so adding a product needs no palette edit.
class ProductPalette {
  final Color tint;
  final Color accent;

  const ProductPalette({required this.tint, required this.accent});

  static const _byCategory = <String, ProductSwatch>{
    'Dental': ProductSwatch.blue,
    'Grooming': ProductSwatch.orange,
    'Nutrition': ProductSwatch.green,
    'Supplements': ProductSwatch.indigo,
    'Toys': ProductSwatch.rose,
    'Accessories': ProductSwatch.violet,
    'Calming': ProductSwatch.rose,
    'Longevity': ProductSwatch.indigo,
  };

  static const _fallback = ProductSwatch.indigo;

  /// Resolves [category]'s colourway against the active appearance.
  ///
  /// Accents read the `…Text` variants: these sit on a tinted panel rather
  /// than a filled one, so dark needs the brightened value to stay legible.
  static ProductPalette of(BuildContext context, String category) {
    final c = context.c;
    return switch (_byCategory[category] ?? _fallback) {
      ProductSwatch.blue =>
        ProductPalette(tint: c.productBlueTint, accent: c.info),
      ProductSwatch.orange =>
        ProductPalette(tint: c.productOrangeTint, accent: c.warningText),
      ProductSwatch.green =>
        ProductPalette(tint: c.productGreenTint, accent: c.successText),
      ProductSwatch.indigo =>
        ProductPalette(tint: c.productIndigoTint, accent: c.actionText),
      ProductSwatch.rose =>
        ProductPalette(tint: c.productRoseTint, accent: c.startText),
      ProductSwatch.violet =>
        ProductPalette(tint: c.productVioletTint, accent: c.actionText),
    };
  }

  /// The design fades the card surface into the tint rather than filling flat.
  LinearGradient gradient(
    BuildContext context, {
    double start = 0.04,
    double end = 0.96,
  }) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.c.surface, tint],
        stops: [start, end],
      );
}
