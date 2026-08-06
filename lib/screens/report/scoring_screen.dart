import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/design_image.dart';

/// Screen 22 — "Scoring your answers", plus the celebratory interstitial the
/// design shows on the way to a strong report.
///
/// Branching matches the design:
///   score ≤ 25  → vet alert (23b)
///   score > 50  → celebrate for 1.8s → report card
///   otherwise   → report card
class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  static const _scoringPause = Duration(milliseconds: 1700);
  static const _celebratePause = Duration(milliseconds: 1800);

  Timer? _timer;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_scoringPause, _resolve);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (!mounted) return;

    final quiz = context.read<QuizProvider>();
    final router = GoRouter.of(context);

    // Record the result once, here — the report card just renders it.
    final result = await quiz.calculateResult();

    if (!mounted) return;

    final percent = result.percentageScore;

    if (percent <= 25) {
      router.pushReplacement(AppRoutes.vetAlert);
      return;
    }

    if (percent > 50) {
      setState(() => _celebrating = true);

      _timer = Timer(_celebratePause, () {
        if (!mounted) return;
        router.pushReplacement(AppRoutes.report);
      });

      return;
    }

    router.pushReplacement(AppRoutes.report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _celebrating ? const _Celebrate() : const _Scoring(),
      ),
    );
  }
}

class _Scoring extends StatelessWidget {
  const _Scoring();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.c.surface, context.c.surfaceRaised],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Held on the still: Android's video_player composites onto an
          // opaque surface, so a transparent WebM's alpha resolves to a black
          // box behind the puppy. Swap back to DesignVideo once an encode
          // with baked-in background (or HEVC-with-alpha) is supplied — the
          // width matches the clip's, so nothing shifts.
          const DesignImage(
            AppAssets.analyzing,
            width: 330,
            semanticLabel: 'Puppy analysing the answers',
          ),
          const SizedBox(height: 18),
          Text(
            'Scoring your answers',
            textAlign: TextAlign.center,
            style: context.t.h2,
          ),
          const SizedBox(height: 8),
          Text(
            'Weighing 9 categories against the MyPetFit fitness index…',
            textAlign: TextAlign.center,
            style: AppTheme.font(
              size: 14,
              color: context.c.body,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          const _LoadingDots(),
        ],
      ),
    );
  }
}

/// Three static dots in the design's action / plum / inactive sequence.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    final colors = [
      context.c.action,
      context.c.startLight,
      context.c.dotInactive,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < colors.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == colors.length - 1 ? 0 : 7),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// The pop-in celebration shown before a strong report card.
class _Celebrate extends StatefulWidget {
  const _Celebrate();

  @override
  State<_Celebrate> createState() => _CelebrateState();
}

class _CelebrateState extends State<_Celebrate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.c.surface, context.c.bandGoodTint],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            // Matches the design's mpfPop keyframe.
            scale: CurvedAnimation(
              parent: _pop,
              curve: Curves.elasticOut,
            ).drive(Tween(begin: 0.6, end: 1)),
            child: FadeTransition(
              opacity: _pop,
              child: const DesignImage(
                AppAssets.greatJob,
                width: 270,
                shadow: true,
                semanticLabel: 'Celebrating puppy',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Great job!',
            textAlign: TextAlign.center,
            style: context.t.h1.copyWith(fontSize: 28, letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Text(
            'Your care routine is paying off…',
            textAlign: TextAlign.center,
            style: AppTheme.font(size: 14.5, color: context.c.body),
          ),
        ],
      ),
    );
  }
}
