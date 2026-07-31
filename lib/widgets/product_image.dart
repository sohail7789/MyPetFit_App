import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/product.dart';

/// Renders a product's remote photo with graceful degradation:
///
///   * no URL            → emoji on a tinted backdrop
///   * loading           → emoji + a quiet progress ring (never a blank box)
///   * network / 404 fail → emoji, silently
///
/// Falling back to the emoji rather than a broken-image glyph means a bad
/// or expired URL degrades to the previous design instead of looking broken.
///
/// Uses [Image.network], which is backed by Flutter's in-memory ImageCache.
/// If the catalog grows past a few dozen items, swapping this one widget for
/// `cached_network_image` adds disk caching without touching call sites.
class ProductImage extends StatelessWidget {
  final Product product;

  /// Font size for the emoji fallback.
  final double emojiSize;

  /// Optional fixed dimensions. When null the image fills its parent.
  final double? width;
  final double? height;

  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.product,
    this.emojiSize = 44,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.interactive(isDark);
    final backdrop = AppTheme.tint(isDark, accent, AppTheme.lightAzure);

    Widget emojiFallback() => Container(
          width: width,
          height: height,
          color: backdrop,
          alignment: Alignment.center,
          child: Text(
            product.emoji,
            style: TextStyle(fontSize: emojiSize),
          ),
        );

    if (!product.hasImage) return emojiFallback();

    return Image.network(
      product.imageUrl!,
      width: width,
      height: height,
      fit: fit,
      // Fade the photo in once decoded so it doesn't pop.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.slow,
          curve: AppMotion.curve,
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Stack(
          alignment: Alignment.center,
          children: [
            emojiFallback(),
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent.withValues(alpha: 0.6),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stack) => emojiFallback(),
    );
  }
}
