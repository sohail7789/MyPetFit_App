import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/score_band.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/paw_mark.dart';

/// Screen 30 — Home dashboard.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final auth = context.watch<AuthProvider>();
    final pet = context.watch<PetInfoProvider>().activePet;

    final owner = auth.firstName.trim().isNotEmpty
        ? auth.firstName
        : auth.displayName;
    final petName = pet?.name.trim() ?? '';
    final title = [
      if (owner.trim().isNotEmpty) owner,
      if (petName.isNotEmpty) petName,
    ].join(' & ');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: AppTheme.font(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title.isEmpty ? 'Welcome back' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                            size: 25,
                            weight: FontWeight.w800,
                            color: AppTheme.ink,
                            letterSpacing: -0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundAction(
                    semanticLabel: 'Notifications',
                    onTap: () => context.push(AppRoutes.inbox),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                      color: AppTheme.action,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RoundAction(
                    semanticLabel: 'Account',
                    onTap: () => context.go(AppRoutes.account),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 21,
                      color: AppTheme.action,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                children: [
                  _ScoreCard(quiz: quiz),
                  if (quiz.hasResumableProgress) ...[
                    const SizedBox(height: 14),
                    _ResumeCard(
                      answered: quiz.answeredCount,
                      total: quiz.totalQuestions,
                      onTap: () => context.push(AppRoutes.quiz),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          art: AppAssets.categoryFace(1),
                          title: 'Retake assessment',
                          subtitle: '45 questions · 6 min',
                          onTap: () {
                            context.read<QuizProvider>().reset();
                            context.push(AppRoutes.consent);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          art: AppAssets.emoHappy,
                          title: petName.isEmpty
                              ? 'Your picks'
                              : "$petName's picks",
                          subtitle: 'Matched to the report',
                          onTap: () => context.go(AppRoutes.shop),
                        ),
                      ),
                    ],
                  ),
                  if (quiz.result != null) ...[
                    const SizedBox(height: 14),
                    _FocusCard(quiz: quiz),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  const _RoundAction({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F1F9),
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The gradient hero showing the latest fitness score, or a prompt to take
/// the assessment when there isn't one yet.
class _ScoreCard extends StatelessWidget {
  final QuizProvider quiz;

  const _ScoreCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final result = quiz.result;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF46437F), Color(0xFF5B4E8E), Color(0xFF8E4F7C)],
          stops: [0, 0.55, 1],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            bottom: -40,
            child: PawMark(
              size: 120,
              color: Colors.white,
              opacity: 0.07,
              rotation: -0.24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ScoreRing(percent: result?.percentageScore),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FITNESS SCORE',
                          style: AppTheme.font(
                            size: 12,
                            weight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result == null
                              ? 'Not assessed yet'
                              : result.category.label,
                          style: AppTheme.font(
                            size: 20,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          result == null
                              ? 'Take the 45-question assessment'
                              : 'Last assessed ${_date(result.completedAt)}',
                          style: AppTheme.font(
                            size: 12.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _WhiteButton(
                label: result == null
                    ? 'Start the assessment'
                    : 'View report card',
                onTap: () => context.push(
                  result == null ? AppRoutes.consent : AppRoutes.report,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _date(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _ScoreRing extends StatelessWidget {
  final int? percent;

  const _ScoreRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (percent ?? 0) / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          Text(
            percent == null ? '—' : '$percent',
            style: AppTheme.font(
              size: 19,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WhiteButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            size: 14,
            weight: FontWeight.w800,
            color: AppTheme.action,
          ),
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final int answered;
  final int total;
  final VoidCallback onTap;

  const _ResumeCard({
    required this.answered,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          DesignImage(AppAssets.categoryFace(3), width: 54, height: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue assessment',
                  style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$answered of $total answered',
                  style: AppTheme.font(size: 12.5, color: AppTheme.body),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : answered / total,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDEBF4),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.action),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFFB0AEC2),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String art;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.art,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignImage(art, width: 60, height: 60),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.font(
              size: 12,
              color: AppTheme.body,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// "This week's focus" — the three weakest categories from the last report,
/// so the advice reflects real answers rather than fixed copy.
class _FocusCard extends StatelessWidget {
  final QuizProvider quiz;

  const _FocusCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final scores = quiz.result!.categoryScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakest = scores.take(3).toList();

    return AppCard(
      background: const Color(0xFFFCFBFD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DesignImage(AppAssets.emoTilt, width: 40, height: 40),
              const SizedBox(width: 10),
              Text(
                "This week's focus",
                style: AppTheme.font(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entry in weakest)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: categoryBarColor(entry.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.key} — ${entry.value.round()}%',
                      style: AppTheme.font(
                        size: 13,
                        color: AppTheme.bodyStrong,
                        height: 1.45,
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
