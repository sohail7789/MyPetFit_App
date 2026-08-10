import 'package:flutter/material.dart';
import '../config/theme.dart';

/// One label-and-value line inside a details card.
///
/// The app had three copies of this row — the owner profile's, the pet
/// profile's and the analytics card's — each spelling out its own sizes and
/// its own flex split. They drifted, which is why the same idea rendered at
/// different sizes and with different alignment depending on which screen you
/// were looking at. This is the one implementation; the sizes come from
/// [rowLabel] and [rowValue] rather than from literals here.
///
/// The rule it implements, everywhere it is used:
///
/// * the label is left-aligned and starts at the card's left content edge
/// * the value is right-aligned and *ends* at the card's right content edge,
///   however short it is — "Male" and "English" terminate exactly where a
///   long value does, rather than floating mid-row
/// * both are vertically centred against each other
/// * a value too long to share the line takes a line of its own, still
///   right-aligned, rather than breaking mid-word
class InfoRow extends StatelessWidget {
  final String label;

  /// The value. Empty renders [emptyText] in the muted style.
  final String value;

  /// A second, smaller line under the value.
  final String? note;

  /// Suppresses the divider — pass true on the last row in a card.
  final bool last;

  /// What stands in for an empty value.
  final String emptyText;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.last = false,
    this.emptyText = 'Not set',
  });

  /// Gap between the label and the value when they share a line.
  static const double _gap = 16;

  /// Width [text] wants on one line, at the reader's own text scale.
  ///
  /// Measured rather than estimated: the same row that fits at the platform
  /// default stops fitting a couple of accessibility steps up, and the layout
  /// has to follow the text rather than assume the width it had at 1.0.
  ///
  /// Public because the settings rows need the same measurement to decide
  /// whether a label and its control can share a line — one helper rather
  /// than a second copy of the same TextPainter dance.
  static double widthOf(String text, TextStyle style, TextScaler scaler) =>
      _widthOf(text, style, scaler);

  static double _widthOf(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: scaler,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final shown = value.trim();
    final isEmpty = shown.isEmpty;
    final valueText = isEmpty ? emptyText : shown;

    final labelStyle = context.t.rowLabel;
    final valueStyle = isEmpty ? context.t.rowValueEmpty : context.t.rowValue;

    final valueWidget = Text(
      valueText,
      textAlign: TextAlign.right,
      style: valueStyle,
    );

    final noteWidget = note == null
        ? null
        : Text(note!, textAlign: TextAlign.right, style: context.t.rowNote);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: context.c.borderSoft)),
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          final fits = _widthOf(label, labelStyle, scaler) +
                  _gap +
                  _widthOf(valueText, valueStyle, scaler) <=
              constraints.maxWidth;

          // Stacked. An email is one unbreakable token, so a value wider than
          // the column left for it gets broken *mid-word* — `…@gm / ail.com`,
          // which reads as corruption rather than as wrapping. Giving it a
          // full line keeps it whole, at the same size, still ending on the
          // same right edge as every other value in the card.
          if (!fits) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 4),
                valueWidget,
                if (noteWidget != null) ...[
                  const SizedBox(height: 2),
                  noteWidget,
                ],
              ],
            );
          }

          return Row(
            // Centre, not start: the two sides are one line of information and
            // should sit on the same optical baseline. Top-aligning them left
            // a short value hanging above a label that had wrapped.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Deliberately *not* Flexible. `Flexible` defaults to `flex: 1`,
              // so a Flexible label and an Expanded value split the row in
              // half and a short value's box stopped at the middle — which is
              // precisely the "values floating mid-row" symptom. Unflexed, the
              // label takes its intrinsic width and [Expanded] below claims
              // everything that is left, so every value ends on the same
              // edge. It cannot overflow here: this branch only runs when the
              // measurement above proved both fit.
              Text(label, style: labelStyle),
              const SizedBox(width: _gap),
              // Expanded, so the value's box always reaches the right content
              // edge — that is what makes "Male" and a long email terminate in
              // the same place instead of the short one floating mid-row.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    valueWidget,
                    if (noteWidget != null) ...[
                      const SizedBox(height: 2),
                      noteWidget,
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
