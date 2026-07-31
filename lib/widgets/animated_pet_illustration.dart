import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';

enum PetScene { dogWalking, dogSuccess, dogError, dogWaiting, dogRunning }

/// Animated pet illustration backed by a **bundled** Lottie asset.
///
/// This used to call `Lottie.network(...)` against lottiefiles.com. That was
/// broken in production: the `INTERNET` permission is only declared in the
/// debug/profile manifests, so in a release build every fetch failed and the
/// widget rendered a grey fallback icon — including on all three onboarding
/// pages, which is the first thing a new user sees. Bundled assets also mean
/// no third-party CDN dependency, no network round-trip before first paint,
/// and nothing extra to declare on the Play Data Safety form.
///
/// To give each scene its own animation, drop more `.json` files into
/// `assets/animations/`, register them in `pubspec.yaml`, and map them in
/// [_assetFor].
class AnimatedPetIllustration extends StatelessWidget {
  final PetScene scene;
  final double size;

  /// Tint for the fallback glyph. Also used for the dark-mode backdrop wash.
  final Color? accent;

  /// Background circle color (light mode).
  final Color? pastel;

  const AnimatedPetIllustration({
    super.key,
    required this.scene,
    this.size = 180,
    this.accent,
    this.pastel,
  });

  static String _assetFor(PetScene scene) {
    // Only one animation is bundled today; every scene maps to it. Replace
    // individual entries as scene-specific files are added.
    switch (scene) {
      case PetScene.dogWalking:
      case PetScene.dogRunning:
      case PetScene.dogWaiting:
      case PetScene.dogSuccess:
      case PetScene.dogError:
        return 'assets/animations/dog_walking.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent = accent ?? AppTheme.interactive(isDark);

    // In dark mode a solid pastel disc glows; use a low-alpha accent wash.
    final Color? backdrop = pastel == null
        ? null
        : (isDark ? effectiveAccent.withValues(alpha: 0.14) : pastel);

    return Container(
      width: size,
      height: size,
      decoration: backdrop != null
          ? BoxDecoration(color: backdrop, shape: BoxShape.circle)
          : null,
      child: ClipOval(
        child: Lottie.asset(
          _assetFor(scene),
          fit: BoxFit.contain,
          repeat: true,
          errorBuilder: (context, error, stackTrace) =>
              _Fallback(size: size, accent: effectiveAccent),
        ),
      ),
    );
  }
}

/// Shown only if the bundled asset itself fails to decode. Styled to match
/// the design system rather than the old bare grey glyph.
class _Fallback extends StatelessWidget {
  final double size;
  final Color accent;

  const _Fallback({required this.size, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size * 0.52,
        height: size * 0.52,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '🐾',
          style: TextStyle(fontSize: size * 0.24),
        ),
      ),
    );
  }
}
