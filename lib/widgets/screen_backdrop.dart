import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Full-bleed vertical gradient behind a screen, with optional paw
/// watermarks layered on top of it.
///
/// Each screen in the design carries its own gradient stops, so they are
/// passed in rather than tokenised.
class ScreenBackdrop extends StatelessWidget {
  final List<Color> colors;
  final List<double>? stops;

  /// Watermarks and other decoration drawn above the gradient but below
  /// [child] — typically [PawWatermark]s.
  final List<Widget> decoration;

  final Widget child;

  const ScreenBackdrop({
    super.key,
    required this.colors,
    this.stops,
    this.decoration = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ),
      ),
      child: Stack(
        // Every child here is positioned (watermarks and the filled body), so
        // without an explicit expand the Stack collapses to its content and
        // the gradient stops short of the bottom of the screen.
        fit: StackFit.expand,
        children: [
          ...decoration,
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// The rounded tinted hero panel behind the sign-in artwork —
/// `height:340px; border-radius:0 0 40px 40px`.
class HeroPanel extends StatelessWidget {
  final double height;
  final List<Color> colors;

  const HeroPanel({
    super.key,
    required this.height,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
      ),
    );
  }
}

/// The pagination dots on the onboarding pages: the active dot stretches to
/// a 26×8 pill, inactive stay 8×8.
class PageDots extends StatelessWidget {
  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;

  const PageDots({
    super.key,
    required this.count,
    required this.index,
    this.activeColor = AppTheme.action,
    this.inactiveColor = AppTheme.dotInactive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: i == index ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}
