import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/design_image.dart';
import '../../../widgets/screen_backdrop.dart';

/// Shared structure for screens 07–09: a back button, centred title and
/// supporting copy, the puppy artwork filling the middle, and a form block
/// pinned to the bottom.
///
/// The body scrolls and the art collapses when the keyboard is up, so the
/// bottom form stays reachable on short screens.
class AuthArtLayout extends StatelessWidget {
  final List<Color> gradient;
  final List<Widget> decoration;
  final String title;
  final Widget subtitle;
  final String art;
  final double artWidth;
  final String artLabel;
  final VoidCallback onBack;

  /// Form block pinned below the artwork.
  final List<Widget> children;

  const AuthArtLayout({
    super.key,
    required this.gradient,
    this.decoration = const [],
    required this.title,
    required this.subtitle,
    required this.art,
    required this.artWidth,
    required this.artLabel,
    required this.onBack,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackdrop(
        colors: gradient,
        stops: const [0, 0.6, 1],
        decoration: decoration,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircleIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            size: 44,
                            floating: true,
                            semanticLabel: 'Back',
                            onPressed: onBack,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(34, 26, 34, 0),
                        child: Column(
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: context.t.h1,
                            ),
                            const SizedBox(height: 12),
                            subtitle,
                          ],
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: DesignImage(
                              art,
                              width: artWidth,
                              shadow: true,
                              semanticLabel: artLabel,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 0, 26, 46),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Back to Login" — the centred text action closing screens 07 and 09.
class BackToLogin extends StatelessWidget {
  final VoidCallback onTap;

  const BackToLogin({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          'Back to Login',
          style: AppTheme.font(
            size: 15,
            weight: FontWeight.w700,
            color: context.c.actionText,
          ),
        ),
      ),
    );
  }
}
