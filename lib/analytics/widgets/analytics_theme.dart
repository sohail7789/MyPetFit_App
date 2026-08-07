import 'package:flutter/widgets.dart';

/// Presentation settings shared by the analytics widgets.
///
/// Values that are judgements rather than constants live here so a consumer
/// can hold a different opinion without forking a widget: a veterinarian
/// portal may want a tighter score axis than a consumer app, and a premium
/// dashboard may want a taller chart.
///
/// Immutable, with sensible defaults, so a widget that is handed nothing
/// still behaves well.
@immutable
class AnalyticsTheme {
  /// The smallest score range a trend axis will draw.
  ///
  /// Forty points by default. A tightly fitted axis makes a three-point
  /// wobble fill the card, which reads as a collapse — for a health record
  /// that is a worse failure than a chart that looks uneventful, because it
  /// turns ordinary variation into alarm.
  final double minimumScoreSpan;

  /// Height of the plotted area.
  final double chartHeight;

  /// How long the line takes to draw itself in.
  ///
  /// Ignored when the platform asks for reduced motion — see [TrendGraph].
  final Duration drawDuration;

  /// Smallest tappable size for a chart marker, however small the dot looks.
  final double minimumTapTarget;

  const AnalyticsTheme({
    this.minimumScoreSpan = 40,
    this.chartHeight = 190,
    this.drawDuration = const Duration(milliseconds: 900),
    this.minimumTapTarget = 48,
  });

  /// The theme in scope, or the defaults.
  static AnalyticsTheme of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AnalyticsThemeScope>()
          ?.theme ??
      const AnalyticsTheme();

  AnalyticsTheme copyWith({
    double? minimumScoreSpan,
    double? chartHeight,
    Duration? drawDuration,
    double? minimumTapTarget,
  }) =>
      AnalyticsTheme(
        minimumScoreSpan: minimumScoreSpan ?? this.minimumScoreSpan,
        chartHeight: chartHeight ?? this.chartHeight,
        drawDuration: drawDuration ?? this.drawDuration,
        minimumTapTarget: minimumTapTarget ?? this.minimumTapTarget,
      );

  @override
  bool operator ==(Object other) =>
      other is AnalyticsTheme &&
      other.minimumScoreSpan == minimumScoreSpan &&
      other.chartHeight == chartHeight &&
      other.drawDuration == drawDuration &&
      other.minimumTapTarget == minimumTapTarget;

  @override
  int get hashCode => Object.hash(
        minimumScoreSpan,
        chartHeight,
        drawDuration,
        minimumTapTarget,
      );
}

/// Applies an [AnalyticsTheme] to everything below it.
class AnalyticsThemeScope extends InheritedWidget {
  final AnalyticsTheme theme;

  const AnalyticsThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  @override
  bool updateShouldNotify(AnalyticsThemeScope oldWidget) =>
      oldWidget.theme != theme;
}
