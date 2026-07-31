import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/question.dart';

/// Animated category illustration for quiz headers. Uses a pastel circle
/// with a 3D-style floating bounce animation on the category icon.
/// When real PNGs land, populate [_assetMap] and they'll replace the icon.
class CategoryIllustration extends StatefulWidget {
  final QuestionCategory category;
  final int categoryIndex;
  final double size;

  const CategoryIllustration({
    super.key,
    required this.category,
    required this.categoryIndex,
    this.size = 80,
  });

  @override
  State<CategoryIllustration> createState() => _CategoryIllustrationState();
}

class _CategoryIllustrationState extends State<CategoryIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

  static const Map<String, String> _assetMap = {
    // 'skin_coat': 'assets/images/illustrations/category_skin.png',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pastel = AppTheme.categoryPastels[
        widget.categoryIndex % AppTheme.categoryPastels.length];
    final rawAccent = AppTheme.brandAccents[
        widget.categoryIndex % AppTheme.brandAccents.length];
    // Navy accents disappear against dark surfaces — remap for visibility.
    final accent = isDark &&
            (rawAccent == AppTheme.primary ||
                rawAccent == AppTheme.neutralDark)
        ? AppTheme.accentBlue
        : rawAccent;

    final assetPath = _assetMap[widget.category.id];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          // Dark mode: quiet accent wash instead of a glowing pastel disc.
          color: isDark ? accent.withValues(alpha: 0.18) : null,
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    pastel,
                    pastel.withValues(alpha: 0.6),
                  ],
                ),
          shape: BoxShape.circle,
          // One restrained shadow in light mode only — the old double
          // colored glow read as sticker art and lit up dark mode.
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: assetPath != null
            ? ClipOval(child: Image.asset(assetPath, fit: BoxFit.cover))
            : ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.7)],
                ).createShader(bounds),
                child: Icon(
                  widget.category.icon,
                  size: widget.size * 0.5,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
