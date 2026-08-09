import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'app_icons.dart';

/// "or continue with" rule — a hairline either side of centred caption text.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.c.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: AppTheme.font(size: 13, color: context.c.muted),
          ),
        ),
        Expanded(child: Divider(color: context.c.divider)),
      ],
    );
  }
}

/// One of the bordered white social buttons (Google / Apple).
class SocialButton extends StatelessWidget {
  final String label;

  /// Fixed markup for buttons whose mark is the same in both appearances
  /// (Google's is multicolour). Null for Apple, whose monochrome mark has to
  /// be resolved against the active palette at paint time.
  final String? svg;

  final double iconSize;
  final double height;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.label,
    required this.svg,
    this.iconSize = 19,
    this.height = 54,
    this.onPressed,
  });

  const SocialButton.google({
    super.key,
    this.height = 54,
    this.iconSize = 19,
    this.onPressed,
  })  : label = 'Google',
        svg = AppIcons.google;

  const SocialButton.apple({
    super.key,
    this.height = 54,
    this.iconSize = 18,
    this.onPressed,
  })  : label = 'Apple',
        svg = null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(color: context.c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(svg ?? AppIcons.apple(context.c.appleMark), size: iconSize),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.font(
                  size: 15,
                  weight: FontWeight.w600,
                  color: context.c.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Google + Apple pair, side by side.
class SocialRow extends StatelessWidget {
  final double height;
  final double? maxWidth;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  const SocialRow({
    super.key,
    this.height = 54,
    this.maxWidth,
    this.onGoogle,
    this.onApple,
  });

  /// Whether Sign in with Apple can actually complete on this platform.
  ///
  /// Apple's own flow is native to iOS and macOS. Anywhere else the
  /// `sign_in_with_apple` package needs `webAuthenticationOptions` — an Apple
  /// Service ID and a return URL — which this app does not have and does not
  /// need for v1.1.0. Offering the button without them would render a control
  /// that throws the moment it is tapped, which is worse than not offering it.
  ///
  /// Read from [defaultTargetPlatform] rather than `dart:io`'s `Platform` so
  /// this stays compilable for web and overridable in widget tests.
  static bool get _appleAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context) {
    final google = SocialButton.google(height: height, onPressed: onGoogle);

    // Google alone takes the full width rather than sitting in half of it
    // next to a gap where Apple used to be.
    final row = _appleAvailable
        ? Row(
            children: [
              Expanded(child: google),
              const SizedBox(width: 12),
              Expanded(
                child: SocialButton.apple(height: height, onPressed: onApple),
              ),
            ],
          )
        : Row(children: [Expanded(child: google)]);

    if (maxWidth == null) return row;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: row,
    );
  }
}

/// "Already have an account? Log in" — caption plus an inline action.
///
/// The action is a real [TextSpan] rather than a [WidgetSpan] wrapping a
/// [Text]. A WidgetSpan is laid out as an opaque box the text engine cannot
/// see inside, so the link sat off the caption's baseline and never wrapped
/// with it — which is what made these read as pasted-on rather than as part
/// of the sentence. It also gave the link a tap target only as tall as the
/// glyphs; the recognizer below covers the whole run.
class InlineLink extends StatefulWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;
  final TextAlign align;

  const InlineLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
    this.align = TextAlign.center,
  });

  @override
  State<InlineLink> createState() => _InlineLinkState();
}

class _InlineLinkState extends State<InlineLink> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = () => widget.onTap();
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: '${widget.prefix} ${widget.action}'.trim(),
      child: Text.rich(
        TextSpan(
          text: widget.prefix.isEmpty ? null : '${widget.prefix} ',
          style: AppTheme.font(size: 14, color: context.c.body, height: 1.4),
          children: [
            TextSpan(
              text: widget.action,
              recognizer: _recognizer,
              style: AppTheme.font(
                size: 14,
                weight: FontWeight.w700,
                color: context.c.actionText,
                height: 1.4,
              ),
            ),
          ],
        ),
        textAlign: widget.align,
      ),
    );
  }
}
