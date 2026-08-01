import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Tint and accent for a product's image panel.
///
/// The design assigns a colour per product type; those are mapped onto the
/// catalog's own categories here, so adding a product needs no palette edit.
class ProductPalette {
  final Color tint;
  final Color accent;

  const ProductPalette({required this.tint, required this.accent});

  static const _byCategory = <String, ProductPalette>{
    'Dental': ProductPalette(tint: Color(0xFFEAF3FC), accent: AppTheme.info),
    'Grooming':
        ProductPalette(tint: Color(0xFFFDF4EE), accent: AppTheme.warning),
    'Nutrition':
        ProductPalette(tint: Color(0xFFF1F8F3), accent: AppTheme.success),
    'Supplements':
        ProductPalette(tint: Color(0xFFF3F0F9), accent: AppTheme.action),
    'Toys': ProductPalette(tint: Color(0xFFF7EFF4), accent: AppTheme.start),
    'Accessories':
        ProductPalette(tint: Color(0xFFEFEEF8), accent: AppTheme.action),
    'Calming': ProductPalette(tint: Color(0xFFF7EFF4), accent: AppTheme.start),
    'Longevity':
        ProductPalette(tint: Color(0xFFF3F0F9), accent: AppTheme.action),
  };

  static const _fallback =
      ProductPalette(tint: Color(0xFFF3F0F9), accent: AppTheme.action);

  static ProductPalette of(String category) =>
      _byCategory[category] ?? _fallback;

  /// The design fades white into the tint rather than filling flat.
  LinearGradient gradient({double start = 0.04, double end = 0.96}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, tint],
        stops: [start, end],
      );
}
