import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/category_order.dart';
import '../../models/pet_info.dart';
import '../../models/score_band.dart';
import '../../models/score_result.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../services/report_pdf.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/photo_slot.dart';

/// Screen 23 — Fitness report card, and 23b/32b when opened from history.
///
/// One screen serves both because a past report card is the same document
/// with a different [ScoreResult] behind it. [historyIndex] selects which:
/// null renders the live result, an index reads that entry out of
/// [QuizProvider.assessmentHistory].
class ReportCardScreen extends StatefulWidget {
  /// Index into [QuizProvider.assessmentHistory]. Null means the current
  /// result — the one just calculated, or the last one completed.
  final int? historyIndex;

  /// Whether this device can print, asked once on entry.
  ///
  /// Injectable purely so a test can build the print control at all: the real
  /// check reaches the printing plugin, which never answers under
  /// `flutter test`, so the button was simply absent from every widget test
  /// and its accessibility went uncovered. Production passes nothing and gets
  /// [ReportPdf.canPrint] exactly as before.
  @visibleForTesting
  final Future<bool> Function()? canPrint;

  const ReportCardScreen({super.key, this.historyIndex, this.canPrint});

  bool get isHistorical => historyIndex != null;

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countUp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool _remind = true;
  bool _sharing = false;
  bool _printing = false;

  /// Whether this device can print. Null until asked.
  ///
  /// Resolved once rather than on every build, and the control stays hidden
  /// until the answer arrives — a print button that opens nothing is worse
  /// than one that is absent.
  bool? _canPrint;

  /// The report this screen is showing, captured the first time it resolves.
  ///
  /// [historyIndex] addresses a position in [QuizProvider.assessmentHistory],
  /// and that list is bound to the *active* pet and trimmed as it grows.
  /// Re-reading it on every rebuild meant switching pets with a report open
  /// swapped the document underneath the reader — same index, different
  /// animal — and a trim shifted every index by one. A historical report is
  /// a record: once opened, it is the one that stays on screen.
  ScoreResult? _shown;

  /// The score recorded before [_shown], captured at the same moment.
  ///
  /// Frozen with the report rather than looked up per build. The record was
  /// already frozen; its comparison was not, and it was read from
  /// [QuizProvider.assessmentHistory] — a list bound to the *active* pet.
  /// Switching pets with a report open therefore left the right animal, the
  /// right score and a delta measured against a different animal's history:
  /// Bruno's 70 against Mia's 20 read as "Up 50" on a page still headed
  /// Bruno. A trim moved it the same way, by shifting the neighbouring index.
  int? _previous;

  @override
  void initState() {
    super.initState();
    _countUp.forward();
    _resolvePrinting();
  }

  Future<void> _resolvePrinting() async {
    final can = await (widget.canPrint ?? ReportPdf.canPrint)();
    if (mounted) setState(() => _canPrint = can);
  }

  /// Sends the same document [share] would send to the print dialog.
  Future<void> _printReport(ScoreResult result) async {
    if (_printing) return;
    setState(() => _printing = true);

    final pets = context.read<PetInfoProvider>();
    final pet = _petFor(result, pets);

    try {
      await ReportPdf.printDocument(
        result: result,
        pet: pet,
        owner: pets.ownerInfo,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't print the report: $error"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  /// The stored report to render, resolved once.
  ///
  /// Returns null until something resolves, so a screen reached before the
  /// history has loaded still picks the report up on a later build rather
  /// than freezing an empty state forever.
  ScoreResult? _resolve(QuizProvider quiz) {
    if (_shown != null) return _shown;

    final index = widget.historyIndex;
    final history = quiz.assessmentHistory;

    final resolved = index == null
        ? quiz.result
        : (index >= 0 && index < history.length ? history[index] : null);

    // Nothing resolved yet — the history may still be loading, and freezing
    // a null here would leave an empty state on screen forever.
    if (resolved == null) return null;

    _previous = _previousScoreFor(resolved, history);
    return _shown = resolved;
  }

  /// The score recorded before [shown], for the pet [shown] belongs to.
  ///
  /// Matched by pet and instant rather than by list position. A neighbouring
  /// index is only meaningful in the list it was read from, and that list is
  /// rebuilt, refiltered and trimmed underneath this screen; an instant and
  /// an owner are properties of the record itself.
  ///
  /// Records written before results were scoped per pet carry a null id, and
  /// compare equal to each other — which is right, because those installs
  /// only ever had one pet.
  static int? _previousScoreFor(ScoreResult shown, List<ScoreResult> history) {
    ScoreResult? previous;

    for (final candidate in history) {
      if (candidate.petId != shown.petId) continue;
      if (!candidate.completedAt.isBefore(shown.completedAt)) continue;

      if (previous == null ||
          candidate.completedAt.isAfter(previous.completedAt)) {
        previous = candidate;
      }
    }

    return previous?.percentageScore;
  }

  /// The pet [result] was recorded against.
  ///
  /// By id, not by whichever pet happens to be selected: a report opened for
  /// one pet while another is active would otherwise be labelled — and
  /// exported — under the wrong animal. Records written before results were
  /// scoped per pet carry no id and fall back to the active pet, which is
  /// the only pet those installs ever had.
  PetInfo? _petFor(ScoreResult result, PetInfoProvider pets) {
    final id = result.petId;
    if (id == null) return pets.activePet;

    for (final pet in pets.pets) {
      if (pet.id == id) return pet;
    }
    return null;
  }

  /// Renders the report card to PDF and opens the system share sheet, so it
  /// can go to the vet over WhatsApp, mail, Drive — whatever the owner uses.
  Future<void> _shareReport(ScoreResult result) async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final pets = context.read<PetInfoProvider>();
    // The pet this report belongs to, not the selected one — otherwise a
    // past report exported while another pet is active carried that pet's
    // name over the first pet's scores.
    final pet = _petFor(result, pets);
    // Captured before the await: on iPad the share sheet needs the rect of
    // the control that opened it or it throws.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    try {
      await ReportPdf.share(
        result: result,
        pet: pet,
        owner: pets.ownerInfo,
        origin: origin,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't prepare the report: $error"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void dispose() {
    _countUp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    // The history is read only to resolve the record, once. Nothing in this
    // build reads it again — see [_previous].
    final result = _resolve(quiz);

    if (result == null) {
      // Reached without a completed assessment — send them to take one.
      return Scaffold(
        backgroundColor: context.c.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No report yet',
                  textAlign: TextAlign.center,
                  style: context.t.h2,
                ),
                const SizedBox(height: 10),
                Text(
                  'Complete the assessment to see your report card.',
                  textAlign: TextAlign.center,
                  style: context.t.bodyText,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Start the assessment',
                  // The questionnaire, not the consent form. Reaching this
                  // screen at all means the router already cleared the
                  // consent gate.
                  onPressed: () => context.go(AppRoutes.quiz),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final band = result.category;

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The date left the header and moved into the metadata card:
            // when it sat beside the title it competed with it, and it is
            // supporting detail, not the headline.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Text(
                'FITNESS REPORT CARD',
                style: context.t.overline.copyWith(letterSpacing: 1.2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, _gapLg, 22, 8),
                children: [
                  _BandHero(
                    result: result,
                    countUp: _countUp,
                    // Captured with the record, never re-read: see [_previous].
                    previous: _previous,
                  ),
                  const SizedBox(height: _gapLg),
                  _AssessedPet(
                    pet: _petFor(result, context.watch<PetInfoProvider>()),
                    completedAt: result.completedAt,
                  ),
                  const SizedBox(height: _gapXl),
                  _Breakdown(scores: result.categoryScores),
                  const SizedBox(height: _gapXl),
                  AppCard(
                    background: context.c.surfaceLow,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What to do next',
                          style: AppTheme.font(
                            size: 14,
                            weight: FontWeight.w800,
                            color: context.c.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          band.bandAdvice,
                          style: AppTheme.font(
                            size: 13,
                            color: context.c.bodyStrong,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _gapMd),
                  _ShareButton(
                    busy: _sharing,
                    onPressed: _sharing ? null : () => _shareReport(result),
                  ),
                  // Only where the platform can actually print.
                  if (_canPrint ?? false) ...[
                    const SizedBox(height: _gapSm),
                    _PrintButton(
                      busy: _printing,
                      onPressed: _printing ? null : () => _printReport(result),
                    ),
                  ],
                  // The reminder is a forward-looking setting, so it belongs
                  // on the live report rather than on an archived one.
                  if (!widget.isHistorical) ...[
                    const SizedBox(height: 12),
                    _RemindToggle(
                      value: _remind,
                      onChanged: (v) => setState(() => _remind = v),
                    ),
                  ],
                  const SizedBox(height: 6),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.c.surface,
                border: Border(top: BorderSide(color: context.c.borderSoft)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
              child: Column(
                children: [
                  AppButton(
                    label: 'See recommended products',
                    height: AppTheme.ctaHeightCompact,
                    onPressed: () => context.go(AppRoutes.shop),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        // An archived report is a record, not a starting
                        // point — offering "Retake" here reads as though it
                        // would redo *that* assessment.
                        child: widget.isHistorical
                            ? AppButton(
                                label: 'All reports',
                                variant: AppButtonVariant.outline,
                                height: 50,
                                onPressed: () =>
                                    context.backOr(AppRoutes.reportHistory),
                              )
                            : AppButton(
                                label: 'Retake',
                                variant: AppButtonVariant.outline,
                                height: 50,
                                onPressed: () {
                                  context.read<QuizProvider>().reset();
                                  context.go(AppRoutes.quiz);
                                },
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'Dashboard',
                          variant: AppButtonVariant.outline,
                          height: 50,
                          onPressed: () => context.go(AppRoutes.home),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// One spacing scale for the whole report, so the rhythm is consistent
/// rather than a different magic number between every pair of blocks.
const double _gapSm = 8;
const double _gapMd = 12;
const double _gapLg = 16;
const double _gapXl = 22;

/// The score, then the band, then everything else.
///
/// The figure is the answer to "how healthy is my pet", so it is given the
/// most weight on the page; the band explains it; the trend and the copy
/// support it.
class _BandHero extends StatelessWidget {
  final ScoreResult result;
  final Animation<double> countUp;
  final int? previous;

  const _BandHero({
    required this.result,
    required this.countUp,
    required this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final band = result.category;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: band.bandTint(context.c),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: band.bandLine(context.c)),
      ),
      child: Column(
        children: [
          // Good and Excellent celebrate; the lower bands show the vet still,
          // where motion would read wrong. Both are stills for now — see
          // ScoringScreen for why the clips are parked.
          if (band.isPositive)
            const DesignImage(
              AppAssets.greatJob,
              width: 124,
              shadow: true,
              semanticLabel: 'Celebrating puppy',
            )
          else
            const DesignImage(
              AppAssets.vetAlert,
              width: 124,
              shadow: true,
              semanticLabel: 'Concerned puppy',
            ),
          const SizedBox(height: _gapLg),
          _ScoreFigure(percent: result.percentageScore, countUp: countUp),
          const SizedBox(height: _gapLg),
          BandBadge(band: band),
          // The design shows a trend line; it only makes sense once there is
          // a previous assessment to compare against.
          if (previous != null) ...[
            const SizedBox(height: _gapMd),
            _Trend(delta: result.percentageScore - previous!),
          ],
          const SizedBox(height: _gapLg),
          Text(
            band.bandCopy,
            textAlign: TextAlign.center,
            style: AppTheme.font(
              size: 13,
              color: context.c.bodyStrong,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// The headline figure.
///
/// Read to a screen reader as one phrase — "88 percent" — rather than as a
/// bare number and a stray symbol, and laid out so the per-cent sign sits on
/// the figure's baseline at any text scale.
class _ScoreFigure extends StatelessWidget {
  final int percent;
  final Animation<double> countUp;

  const _ScoreFigure({required this.percent, required this.countUp});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$percent percent',
      container: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: countUp,
        builder: (context, _) {
          final shown = (percent * countUp.value).round();
          // FittedBox so the figure gives way on a narrow phone at the 1.3
          // text scale the app clamps to, instead of overflowing the card.
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$shown',
                  style: AppTheme.font(
                    size: 92,
                    weight: FontWeight.w800,
                    color: context.c.ink,
                    letterSpacing: -5,
                    height: 0.85,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5, bottom: 10),
                  child: Text(
                    '%',
                    style: AppTheme.font(
                      size: 26,
                      weight: FontWeight.w800,
                      color: context.c.body,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The health band as a badge: glyph in a filled disc, label beside it.
///
/// Shared by the hero and the category cards so a band reads the same
/// wherever it appears. [compact] is the category-card size.
class BandBadge extends StatelessWidget {
  final HealthCategory band;
  final bool compact;

  const BandBadge({super.key, required this.band, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final disc = compact ? 16.0 : 24.0;

    return Semantics(
      label: 'Health band: ${band.label}',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 15,
          vertical: compact ? 4 : 9,
        ),
        decoration: BoxDecoration(
          color: compact ? band.bandTint(context.c) : context.c.surface,
          borderRadius: BorderRadius.circular(compact ? 20 : 15),
          border: Border.all(color: band.bandLine(context.c)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: disc,
              height: disc,
              decoration: BoxDecoration(
                color: band.bandColor(context.c),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                band.bandGlyph,
                size: compact ? 10 : 14,
                color: context.c.onAccent,
              ),
            ),
            SizedBox(width: compact ? 5 : 9),
            Flexible(
              child: Text(
                band.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.font(
                  size: compact ? 11 : 15,
                  weight: FontWeight.w800,
                  color: compact ? band.bandColor(context.c) : context.c.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Trend extends StatelessWidget {
  final int delta;

  const _Trend({required this.delta});

  @override
  Widget build(BuildContext context) {
    if (delta == 0) {
      return Text(
        'Unchanged since your last assessment',
        textAlign: TextAlign.center,
        style: AppTheme.font(
          size: 13,
          weight: FontWeight.w800,
          color: context.c.muted,
        ),
      );
    }

    final up = delta > 0;
    final color = up ? context.c.successText : context.c.warningText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${up ? 'Up' : 'Down'} ${delta.abs()} since your last assessment',
            textAlign: TextAlign.center,
            style: AppTheme.font(
              size: 13,
              weight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// A glyph for each assessment category.
///
/// Keyed by name because that is how `categoryScores` is keyed. A renamed
/// category falls back to a neutral glyph rather than breaking the card —
/// the questionnaire carries no icon of its own, and giving it one would
/// mean editing the assessment model.
@visibleForTesting
IconData categoryIcon(String name) => switch (name) {
      'Skin & Coat Health' => Icons.spa_outlined,
      'Activity & Fitness Level' => Icons.directions_run_rounded,
      'Oral, Vision & Hearing' => Icons.visibility_outlined,
      'Behavior & Mental Wellness' => Icons.psychology_outlined,
      'Sleep & Nutrition' => Icons.bedtime_outlined,
      'Digestive & Urinary Health' => Icons.water_drop_outlined,
      'Physical & Internal Health' => Icons.favorite_outline_rounded,
      'Medical & Lifestyle Tracking' => Icons.medical_services_outlined,
      _ => Icons.check_circle_outline_rounded,
    };

class _Breakdown extends StatelessWidget {
  final Map<String, double> scores;

  const _Breakdown({required this.scores});

  @override
  Widget build(BuildContext context) {
    // Questionnaire order, not map order — see orderedCategoryScores. A
    // report restored from the cloud can arrive arranged differently.
    final entries = orderedCategoryScores(scores);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Category breakdown',
                style: AppTheme.font(
                  size: 16,
                  weight: FontWeight.w800,
                  color: context.c.ink,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: _gapSm),
            Text(
              '${entries.length} categories',
              style: AppTheme.font(
                size: 12,
                weight: FontWeight.w600,
                color: context.c.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: _gapMd),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == entries.length - 1 ? 0 : _gapMd,
            ),
            child: _CategoryCard(
              name: entries[i].key,
              percent: entries[i].value,
            ),
          ),
      ],
    );
  }
}

/// One category, as its own card: glyph, name, percentage, band and bar.
class _CategoryCard extends StatelessWidget {
  final String name;
  final double percent;

  const _CategoryCard({required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100).toDouble();
    final rounded = clamped.round();
    final color = categoryBarColor(context.c, clamped);
    final band = bandForPercent(clamped);

    return Semantics(
      label: '$name, $rounded percent, ${band.label}',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
          border: Border.all(color: context.c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(categoryIcon(name), size: 18, color: color),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      size: 14,
                      weight: FontWeight.w700,
                      color: context.c.ink,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: _gapSm),
                Text(
                  '$rounded%',
                  style: AppTheme.font(
                    size: 16,
                    weight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Align(
              alignment: Alignment.centerLeft,
              child: BandBadge(band: band, compact: true),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: clamped / 100),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: context.c.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback? onPressed;

  /// Swaps the icon for a spinner while the PDF renders. Generating and
  /// writing the file takes a beat on a mid-range phone, and without this the
  /// button reads as dead — which is how it behaved before it did anything
  /// at all.
  final bool busy;

  const _ShareButton({required this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: context.c.actionText, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(context.c.action),
                  ),
                )
              else
                Icon(
                  Icons.ios_share_rounded,
                  size: 17,
                  color: context.c.actionText,
                ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  busy
                      ? 'Preparing report…'
                      : 'Share report with your vet',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    size: 15,
                    weight: FontWeight.w700,
                    color: context.c.actionText,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemindToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RemindToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      background: context.c.surfaceLow,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Remind me to retake in 3 months',
              style: AppTheme.font(
                size: 13.5,
                weight: FontWeight.w700,
                color: context.c.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _Switch(value: value),
        ],
      ),
    );
  }
}

/// The 44×26 pill switch used across the design.
class _Switch extends StatelessWidget {
  final bool value;

  const _Switch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: value ? context.c.action : context.c.dotInactive,
        borderRadius: BorderRadius.circular(13),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: context.c.onAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.c.ink.withValues(alpha: 0.35),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Who this report is about, and when it was taken.
///
/// The pet record as it stands today, not as it stood at the assessment:
/// [PetInfo] keeps no historical snapshot, so a pet renamed or grown since
/// will read with today's details. The scores above are the archived ones —
/// only the identity is live. Accepted for V1.
class _AssessedPet extends StatelessWidget {
  final PetInfo? pet;
  final DateTime completedAt;

  const _AssessedPet({required this.pet, required this.completedAt});

  @override
  Widget build(BuildContext context) {
    final animal = pet;
    final when = '${reportDate(completedAt)} · ${reportTime(completedAt)}';

    return AppCard(
      background: context.c.surfaceLow,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (animal != null) ...[
            Semantics(
              label: 'Pet: ${animal.name}, ${_petLine(animal)}',
              container: true,
              excludeSemantics: true,
              child: Row(
                children: [
                  PhotoAvatar(photoPath: animal.photoPath, size: 42),
                  const SizedBox(width: _gapMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          animal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                            size: 15,
                            weight: FontWeight.w800,
                            color: context.c.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _petLine(animal),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                            size: 12.5,
                            color: context.c.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _gapMd),
            Divider(height: 1, color: context.c.borderSoft),
            const SizedBox(height: _gapMd),
          ],
          Semantics(
            label: 'Assessed on $when',
            container: true,
            excludeSemantics: true,
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 15,
                  color: context.c.muted,
                ),
                const SizedBox(width: _gapSm),
                Text(
                  'Assessed',
                  style: AppTheme.font(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: context.c.muted,
                  ),
                ),
                const SizedBox(width: _gapMd),
                Expanded(
                  child: Text(
                    when,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: context.c.bodyStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The calendar date a report was completed.
@visibleForTesting
String reportDate(DateTime when) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final d = when.toLocal();
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}

/// The time of day it was completed, in 12-hour form.
///
/// Deliberately not locale-aware: the app has no date formatting anywhere
/// else, and pulling `intl` in for one line would be a dependency decision,
/// not a polish one.
@visibleForTesting
String reportTime(DateTime when) {
  final t = when.toLocal();
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour < 12 ? 'am' : 'pm'}';
}

/// Breed, age and weight on one line, skipping whatever was left blank.
///
/// Local to this screen on purpose. The dashboard formats a pet's age too,
/// but that helper is `@visibleForTesting` — deliberately not a shared API —
/// and promoting it would mean editing a Dashboard file. See the note in the
/// Feature 2 summary: both belong in shared domain code, in their own
/// commit, not smuggled in here.
String _petLine(PetInfo pet) {
  final years = pet.ageYears;
  final months = pet.ageMonths;

  final age = switch ((years, months)) {
    (0, 0) => null,
    (0, final m) => m == 1 ? '1 month' : '$m months',
    (final y, _) when y > 2 || months == 0 => y == 1 ? '1 year' : '$y years',
    (final y, final m) => '$y yr $m mo',
  };

  final weight = pet.weightKg > 0
      ? '${pet.weightKg.toStringAsFixed(pet.weightKg % 1 == 0 ? 0 : 1)} kg'
      : null;

  final parts = [
    if (pet.breed.trim().isNotEmpty) pet.breed.trim(),
    ?age,
    ?weight,
  ];
  return parts.isEmpty ? 'No details recorded' : parts.join(' · ');
}

/// Sends the report to the platform print dialog.
///
/// Quieter than the share button by design: sharing is the common path to a
/// vet, printing is the occasional one to a clinic file, and two equally
/// loud controls would make the choice look harder than it is.
class _PrintButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool busy;

  const _PrintButton({required this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: busy ? 'Preparing the report to print' : 'Print report',
      container: true,
      excludeSemantics: true,
      // Declared on the node: excluding the children's semantics also
      // excludes the detector's tap action, which left this announced as a
      // button that no screen reader could press.
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          // Comfortably past the 48dp minimum touch target, and it holds at
          // larger text scales because the height is a floor, not a fix.
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.c.surfaceLow,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: context.c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(context.c.bodyStrong),
                  ),
                )
              else
                Icon(
                  Icons.print_outlined,
                  size: 17,
                  color: context.c.bodyStrong,
                ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  busy ? 'Preparing…' : 'Print report',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    size: 14.5,
                    weight: FontWeight.w700,
                    color: context.c.bodyStrong,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
