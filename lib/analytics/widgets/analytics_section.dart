import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// A heading that reveals its detail on request.
///
/// **A disclosure primitive, and nothing else.** It knows about a title, a
/// summary to show while closed, a child to build when open, and how to say
/// which of the two it is. It knows nothing about insights, milestones,
/// categories, reports or pets — which is what lets the same component serve
/// a veterinarian portal and a web dashboard, and what keeps the decision
/// about *what* to disclose with the surface that understands the content.
///
/// **The child is a builder, not a widget.** A widget passed in would already
/// have been built by the caller, so a closed section would cost exactly what
/// an open one does and the whole point would be lost. Nothing below a closed
/// heading is constructed: not the widgets, not their semantics nodes.
///
/// **The state is the platform's, not a word in a label.** [Semantics.expanded]
/// is what a screen reader reads, and it says "collapsed" in the user's own
/// language rather than in ours — an English word baked into the label would
/// be spoken twice and translated never.
///
/// Provider-free, Firebase-free, and it calculates nothing.
class AnalyticsSection extends StatefulWidget {
  final String title;

  /// One line of framing under the title. Shown in both states, because it
  /// describes the section rather than its contents.
  final String? subtitle;

  /// What stands in for the detail while the section is closed.
  ///
  /// Shown only while closed: once the detail is open it would be repeating
  /// something visible a few pixels below. This is where a surface puts what
  /// must never be behind a tap — a caution worth reading now, the newest
  /// record — and it is the caller's job to make sure that summary adds
  /// something rather than restating a headline from higher up the page.
  final Widget? collapsedSummary;

  /// The detail. Called only while the section is open.
  final WidgetBuilder builder;

  final bool initiallyExpanded;

  /// Optional words beside the chevron. A chevron alone is enough for a
  /// section whose title says what is inside; a list that hides eleven older
  /// records deserves to say so.
  final String? expandLabel;
  final String? collapseLabel;

  const AnalyticsSection({
    super.key,
    required this.title,
    required this.builder,
    this.subtitle,
    this.collapsedSummary,
    this.initiallyExpanded = false,
    this.expandLabel,
    this.collapseLabel,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  late bool _expanded = widget.initiallyExpanded;

  /// Long enough to read as a movement, short enough not to be waited on.
  static const _duration = Duration(milliseconds: 180);

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    // Motion is the first thing people switch off when it makes them unwell,
    // and a health record is not the place to insist on it.
    final reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final motion = reducedMotion ? Duration.zero : _duration;

    final action = _expanded ? widget.collapseLabel : widget.expandLabel;

    final content = _expanded
        ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: widget.builder(context),
          )
        : widget.collapsedSummary == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: widget.collapsedSummary,
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // One node, assembled from two sources: the label and the expanded
        // state are stated here, while the button role, the tap action and
        // focus traversal come from the [InkWell] and are real rather than
        // asserted. [MergeSemantics] folds them together so a screen reader
        // meets a single control instead of a label beside a button.
        MergeSemantics(
          child: Semantics(
            button: true,
            // The flag, not a word. The platform speaks the state, in the
            // reader's own language.
            expanded: _expanded,
            label: widget.subtitle == null
                ? widget.title
                : '${widget.title}. ${widget.subtitle}',
            child: InkWell(
              onTap: _toggle,
              // Flat, like every other tappable surface in the app. The
              // InkWell is here for focus and keyboard activation, not for a
              // ripple on a health record.
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: ExcludeSemantics(
                child: ConstrainedBox(
                  // The whole heading is the target, and never smaller than a
                  // fingertip however short the title is.
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: AppTheme.font(
                                  size: 16,
                                  weight: FontWeight.w800,
                                  color: context.c.ink,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle!,
                                  style: AppTheme.font(
                                    size: 12.5,
                                    color: context.c.muted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (action != null) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              action,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppTheme.font(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: context.c.actionText,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: motion,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: context.c.muted,
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
        // No animator at all under reduced motion, rather than one told to
        // take no time: AnimatedSize re-dirties itself mid-layout when its
        // duration is zero, and "immediately" is better expressed by not
        // asking anything to animate.
        if (reducedMotion)
          content
        else
          AnimatedSize(
            duration: motion,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: content,
          ),
      ],
    );
  }
}
