import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Animated floating paw prints + pet silhouettes background.
/// Lightweight and non-distracting — uses low opacity, slow drift.
class FloatingPawsBackground extends StatefulWidget {
  final Widget child;

  const FloatingPawsBackground({super.key, required this.child});

  @override
  State<FloatingPawsBackground> createState() =>
      _FloatingPawsBackgroundState();
}

class _FloatingPawsBackgroundState extends State<FloatingPawsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background color
        Positioned.fill(
          child: Container(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        // Animated floating elements.
        //
        // RepaintBoundary keeps this continuously-animating canvas on its
        // own layer — without it, every one of the 12s loop's frames marks
        // the whole subtree (including the form on top) for repaint.
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _FloatingPawsPainter(
                    phase: _controller.value,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                );
              },
            ),
          ),
        ),
        // Child content
        widget.child,
      ],
    );
  }
}

class _FloatingPawsPainter extends CustomPainter {
  final double phase;
  final bool isDark;

  _FloatingPawsPainter({required this.phase, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Dark mode needs more alpha for the same perceived presence — a 0.08
    // wash that reads as a soft watermark on white is nearly gone on
    // near-black. (Both branches used to carry identical values.)
    final pawColor = AppTheme.secondary
        .withValues(alpha: isDark ? 0.14 : 0.08);
    final accentColor = AppTheme.accentBlue
        .withValues(alpha: isDark ? 0.12 : 0.06);

    // Floating paw prints at different positions/speeds
    final paws = <_FloatingItem>[
      _FloatingItem(0.12, 0.15, 18, 0.7, pawColor),
      _FloatingItem(0.85, 0.25, 14, 1.1, accentColor),
      _FloatingItem(0.25, 0.55, 20, 0.5, pawColor),
      _FloatingItem(0.72, 0.65, 16, 0.9, accentColor),
      _FloatingItem(0.50, 0.80, 12, 1.3, pawColor),
      _FloatingItem(0.08, 0.85, 15, 0.6, accentColor),
      _FloatingItem(0.92, 0.50, 13, 1.0, pawColor),
      _FloatingItem(0.40, 0.10, 17, 0.8, accentColor),
    ];

    for (final paw in paws) {
      final drift = math.sin((phase * paw.speed + paw.xFrac) * math.pi * 2) * 12;
      final yDrift = math.cos((phase * paw.speed + paw.yFrac) * math.pi * 2) * 8;
      final x = paw.xFrac * size.width + drift;
      final y = paw.yFrac * size.height + yDrift;
      final rotation = math.sin(phase * math.pi * 2 * paw.speed) * 0.3;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      _drawPawPrint(canvas, paw.size, paw.color);
      canvas.restore();
    }

    // A few soft circles (toy-like)
    final toyColor =
        AppTheme.accentPink.withValues(alpha: isDark ? 0.10 : 0.06);

    final toyDrift1 = math.sin(phase * math.pi * 2 * 0.4) * 15;
    canvas.drawCircle(
      Offset(size.width * 0.78 + toyDrift1, size.height * 0.12),
      22, Paint()..color = toyColor,
    );

    final toyDrift2 = math.cos(phase * math.pi * 2 * 0.6) * 10;
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.72 + toyDrift2),
      18, Paint()..color = toyColor,
    );
  }

  void _drawPawPrint(Canvas canvas, double size, Color color) {
    final paint = Paint()..color = color;

    // Main pad — heart-ish: wider at the top, slightly tapered at the
    // bottom. RRect with asymmetric radii reads more like a real dog
    // pad than a plain oval.
    final padPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(0, size * 0.22),
          width: size * 0.72,
          height: size * 0.6,
        ),
        topLeft: Radius.circular(size * 0.42),
        topRight: Radius.circular(size * 0.42),
        bottomLeft: Radius.circular(size * 0.22),
        bottomRight: Radius.circular(size * 0.22),
      ));
    canvas.drawPath(padPath, paint);

    // Toes — oval pads, tilted so they fan outward like real canine toes.
    // (Circles read as bear / cartoon paw; tilted ovals read as dog.)
    const toes = <List<double>>[
      // [cx_frac, cy_frac, w_frac, h_frac, rotation_rad]
      [-0.27, -0.22, 0.20, 0.26, -0.32],
      [-0.10, -0.40, 0.18, 0.26, -0.10],
      [0.10, -0.40, 0.18, 0.26, 0.10],
      [0.27, -0.22, 0.20, 0.26, 0.32],
    ];
    for (final toe in toes) {
      canvas.save();
      canvas.translate(toe[0] * size, toe[1] * size);
      canvas.rotate(toe[4]);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: toe[2] * size,
          height: toe[3] * size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingPawsPainter old) => old.phase != phase;
}

class _FloatingItem {
  final double xFrac;
  final double yFrac;
  final double size;
  final double speed;
  final Color color;

  const _FloatingItem(this.xFrac, this.yFrac, this.size, this.speed, this.color);
}
