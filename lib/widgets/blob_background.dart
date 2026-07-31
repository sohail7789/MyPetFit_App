import 'package:flutter/material.dart';
import '../config/theme.dart';

enum BlobVariant { topRight, bottomLeft, scattered, corners }

/// Decorative pastel blobs painted as a background. Pure CustomPaint, no
/// asset dependency. Different screens pick different variants so the
/// background never feels repetitive (PDF page 6 instruction).
class BlobBackground extends StatelessWidget {
  final BlobVariant variant;
  final Widget child;
  final Color? backgroundColor;

  const BlobBackground({
    super.key,
    required this.child,
    this.variant = BlobVariant.topRight,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppTheme.darkBlueBg : Colors.white);

    return Container(
      color: bg,
      child: Stack(
        children: [
          // RepaintBoundary isolates the blob canvas so a child animation
          // (fade/slide on the welcome screen, etc.) doesn't cause the whole
          // background to repaint every frame — big win in debug mode on
          // software-rendered Android emulators.
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BlobPainter(variant: variant, isDark: isDark),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final BlobVariant variant;
  final bool isDark;

  _BlobPainter({required this.variant, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Guard: nothing to paint on a zero-size canvas.
    if (size.isEmpty) return;

    // Avoid MaskFilter.blur — it uses software Skia on Android emulators
    // and causes first-frame stalls (blank screen). Use layered transparent
    // circles instead to achieve a similar soft-edge blob look.
    final opacity = isDark ? 0.12 : 0.35;

    void blob(Offset center, double radius, Color color) {
      // Two concentric circles at decreasing alpha give a soft-edge look
      // without any Skia blur. Kept to 2 draw calls per blob so first-frame
      // cost stays under a frame budget on software-rendered emulators.
      canvas.drawCircle(
        center,
        radius * 1.25,
        Paint()..color = color.withValues(alpha: opacity * 0.35),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }

    switch (variant) {
      case BlobVariant.topRight:
        blob(Offset(size.width * 0.95, size.height * 0.05),
            size.width * 0.45, AppTheme.lightAzure);
        blob(Offset(size.width * 0.78, size.height * 0.18),
            size.width * 0.22, AppTheme.lightGreen);
        break;
      case BlobVariant.bottomLeft:
        blob(Offset(size.width * 0.05, size.height * 0.95),
            size.width * 0.45, AppTheme.softLavender);
        blob(Offset(size.width * 0.22, size.height * 0.82),
            size.width * 0.22, AppTheme.softPeach);
        break;
      case BlobVariant.scattered:
        blob(Offset(size.width * 0.1, size.height * 0.1),
            size.width * 0.25, AppTheme.lightAzure);
        blob(Offset(size.width * 0.95, size.height * 0.4),
            size.width * 0.30, AppTheme.lightGreen);
        blob(Offset(size.width * 0.2, size.height * 0.85),
            size.width * 0.28, AppTheme.softPeach);
        break;
      case BlobVariant.corners:
        blob(Offset(0, 0), size.width * 0.4, AppTheme.lightAzure);
        blob(Offset(size.width, size.height), size.width * 0.45,
            AppTheme.lightGreen);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.isDark != isDark;
}
