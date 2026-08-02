import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/score_band.dart';
import '../../models/score_result.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../services/report_pdf.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';

/// Screen 23 — Fitness report card.
class ReportCardScreen extends StatefulWidget {
  const ReportCardScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _countUp.forward();
  }

  /// Renders the report card to PDF and opens the system share sheet, so it
  /// can go to the vet over WhatsApp, mail, Drive — whatever the owner uses.
  Future<void> _shareReport(ScoreResult result) async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final pets = context.read<PetInfoProvider>();
    // Captured before the await: on iPad the share sheet needs the rect of
    // the control that opened it or it throws.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    try {
      await ReportPdf.share(
        result: result,
        pet: pets.activePet,
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

  String get _today {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')} '
        '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final result = quiz.result;

    if (result == null) {
      // Reached without a completed assessment — send them to take one.
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No report yet',
                  textAlign: TextAlign.center,
                  style: AppTheme.h2,
                ),
                const SizedBox(height: 10),
                Text(
                  'Complete the assessment to see your report card.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Start the assessment',
                  onPressed: () => context.go(AppRoutes.consent),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final band = result.category;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FITNESS REPORT CARD',
                    style: AppTheme.overline.copyWith(letterSpacing: 1.2),
                  ),
                  Text(
                    _today,
                    style: AppTheme.font(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                children: [
                  _BandHero(
                    result: result,
                    countUp: _countUp,
                    previous: _previousScore(quiz),
                  ),
                  const SizedBox(height: 18),
                  _Breakdown(scores: result.categoryScores),
                  const SizedBox(height: 20),
                  AppCard(
                    background: const Color(0xFFFCFBFD),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What to do next',
                          style: AppTheme.font(
                            size: 14,
                            weight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          band.bandAdvice,
                          style: AppTheme.font(
                            size: 13,
                            color: AppTheme.bodyStrong,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ShareButton(
                    busy: _sharing,
                    onPressed: _sharing ? null : () => _shareReport(result),
                  ),
                  const SizedBox(height: 12),
                  _RemindToggle(
                    value: _remind,
                    onChanged: (v) => setState(() => _remind = v),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.borderSoft)),
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
                        child: AppButton(
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

  /// The score before this one, when there is any history to compare against.
  int? _previousScore(QuizProvider quiz) {
    final history = quiz.assessmentHistory;
    if (history.length < 2) return null;
    return history[1].percentageScore;
  }
}

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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: band.bandTint,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: band.bandLine),
      ),
      child: Column(
        children: [
          // Good and Excellent celebrate; the lower bands show the vet still,
          // where motion would read wrong. Both are stills for now — see
          // ScoringScreen for why the clips are parked.
          if (band.isPositive)
            const DesignImage(
              AppAssets.greatJob,
              width: 132,
              shadow: true,
              semanticLabel: 'Celebrating puppy',
            )
          else
            const DesignImage(
              AppAssets.vetAlert,
              width: 132,
              shadow: true,
              semanticLabel: 'Concerned puppy',
            ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: countUp,
            builder: (context, _) {
              final shown = (result.percentageScore * countUp.value).round();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$shown',
                    style: AppTheme.font(
                      size: 86,
                      weight: FontWeight.w800,
                      color: AppTheme.ink,
                      letterSpacing: -4.5,
                      height: 0.88,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 9),
                    child: Text(
                      '%',
                      style: AppTheme.font(
                        size: 26,
                        weight: FontWeight.w800,
                        color: AppTheme.body,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: band.bandLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: band.bandColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(band.bandGlyph, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  band.label,
                  style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
          ),
          // The design shows a trend line; it only makes sense once there is
          // a previous assessment to compare against.
          if (previous != null) ...[
            const SizedBox(height: 10),
            _Trend(delta: result.percentageScore - previous!),
          ],
          const SizedBox(height: 12),
          Text(
            band.bandCopy,
            textAlign: TextAlign.center,
            style: AppTheme.font(
              size: 13,
              color: AppTheme.bodyStrong,
              height: 1.6,
            ),
          ),
        ],
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
        style: AppTheme.font(
          size: 13,
          weight: FontWeight.w800,
          color: AppTheme.muted,
        ),
      );
    }

    final up = delta > 0;
    final color = up ? AppTheme.success : AppTheme.warning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          '${up ? 'Up' : 'Down'} ${delta.abs()} since your last assessment',
          style: AppTheme.font(
            size: 13,
            weight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  final Map<String, double> scores;

  const _Breakdown({required this.scores});

  @override
  Widget build(BuildContext context) {
    final entries = scores.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category breakdown',
              style: AppTheme.font(
                size: 16,
                weight: FontWeight.w800,
                color: AppTheme.ink,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '${entries.length} categories',
              style: AppTheme.font(
                size: 12,
                weight: FontWeight.w600,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BreakdownRow(
              name: entry.key,
              percent: entry.value,
            ),
          ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String name;
  final double percent;

  const _BreakdownRow({required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = categoryBarColor(percent);
    final rounded = percent.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTheme.font(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$rounded%',
              style: AppTheme.font(
                size: 12,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (percent / 100).clamp(0, 1)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 12,
              backgroundColor: const Color(0xFFEDEBF4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.action, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.action),
                  ),
                )
              else
                const Icon(
                  Icons.ios_share_rounded,
                  size: 17,
                  color: AppTheme.action,
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
                    color: AppTheme.action,
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
      background: const Color(0xFFFCFBFD),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Remind me to retake in 3 months',
              style: AppTheme.font(
                size: 13.5,
                weight: FontWeight.w700,
                color: AppTheme.ink,
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
        color: value ? AppTheme.action : AppTheme.dotInactive,
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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.35),
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
