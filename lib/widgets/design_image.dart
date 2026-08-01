import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'paw_mark.dart';

/// Artwork from the design's `assets/v3/` set.
///
/// The exported artwork is added to the repo separately, so a missing file is
/// an expected state during the rebuild rather than a crash: it falls back to
/// a soft tinted paw block of the same footprint, keeping layout honest.
class DesignImage extends StatelessWidget {
  /// Full asset path — use the constants on [AppAssets].
  final String path;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Applies the design's `drop-shadow(0 24px 26px rgba(42,44,90,.15))`.
  final bool shadow;

  final String? semanticLabel;

  const DesignImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.shadow = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stack) => _Missing(
        path: path,
        width: width,
        height: height,
      ),
    );

    if (shadow) {
      // The design uses CSS `drop-shadow()`, which follows the artwork's alpha
      // channel. A BoxShadow would instead shadow the whole rectangle and show
      // as a grey slab behind transparent PNGs, so the shadow is built by
      // blurring a tinted copy of the image itself.
      image = Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 18),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  AppTheme.ink.withValues(alpha: 0.28),
                  BlendMode.srcIn,
                ),
                child: image,
              ),
            ),
          ),
          image,
        ],
      );
    }
    return image;
  }
}

class _Missing extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;

  const _Missing({required this.path, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final w = width ?? height ?? 120;
    final h = height ?? width ?? 120;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppTheme.tint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      alignment: Alignment.center,
      child: PawMark(
        size: (w < h ? w : h) * 0.42,
        color: AppTheme.action,
        opacity: 0.22,
      ),
    );
  }
}
