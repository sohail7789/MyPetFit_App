import 'package:flutter/material.dart';

/// The paw glyph used throughout the design — as a faint background
/// watermark, as the product-tile placeholder, and as a bullet mark.
///
/// Traced from the 24×24 SVG in the design files: four toe circles plus a
/// pad, filled with a single colour.
class PawMark extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  /// Rotation in radians, matching the tilted watermarks in the design.
  final double rotation;

  const PawMark({
    super.key,
    required this.size,
    required this.color,
    this.opacity = 1,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget paw = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PawPainter(color.withValues(alpha: opacity)),
      ),
    );

    if (rotation != 0) {
      paw = Transform.rotate(angle: rotation, child: paw);
    }
    return paw;
  }
}

class _PawPainter extends CustomPainter {
  final Color color;

  const _PawPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // The source artwork is authored on a 24×24 grid.
    final s = size.width / 24.0;
    canvas.scale(s);

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    // Four toes.
    canvas.drawCircle(const Offset(6, 8), 2.2, paint);
    canvas.drawCircle(const Offset(10.5, 5.4), 2.2, paint);
    canvas.drawCircle(const Offset(15.5, 5.4), 2.2, paint);
    canvas.drawCircle(const Offset(19, 8.6), 2.2, paint);

    // Pad.
    final pad = Path()
      ..moveTo(12.5, 10)
      ..relativeCubicTo(3.3, 0, 5.9, 2.3, 5.9, 5.1)
      ..relativeCubicTo(0, 2.4, -1.9, 3.7, -4.3, 3.7)
      ..relativeLineTo(-3.3, 0)
      ..relativeCubicTo(-2.4, 0, -4.3, -1.3, -4.3, -3.7)
      ..cubicTo(6.5, 12.3, 9.2, 10, 12.5, 10)
      ..close();
    canvas.drawPath(pad, paint);
  }

  @override
  bool shouldRepaint(_PawPainter oldDelegate) => oldDelegate.color != color;
}

/// A single positioned paw watermark, as used on the onboarding and auth
/// screens. Wrap screens in a [Stack] and drop these in behind the content.
class PawWatermark extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;
  final double rotationDegrees;

  const PawWatermark({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
    this.rotationDegrees = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: PawMark(
          size: size,
          color: color,
          opacity: opacity,
          rotation: rotationDegrees * 3.1415926535 / 180,
        ),
      ),
    );
  }
}
