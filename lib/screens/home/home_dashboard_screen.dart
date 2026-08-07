import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../models/score_band.dart';
import '../../models/score_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/paw_mark.dart';
import '../../widgets/photo_slot.dart';

/// Screen 30 — Home dashboard.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    // select, not watch: the picks tile needs one string, and watching the
    // whole provider rebuilt this list on every pet edit and photo change.
    final petName = context.select<PetInfoProvider, String>(
      (pets) => pets.activePet?.name.trim() ?? '',
    );

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
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
                          // Straight into the questionnaire for the active
                          // pet, the same way the pet profile's retake works.
                          // This used to route via /consent, which asked
                          // someone who had already signed it to sign it
                          // again — consent is a gate the router owns once,
                          // not a step in every assessment.
                          onTap: () {
                            context.read<QuizProvider>().reset();
                            context.push(AppRoutes.quiz);
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

/// Greeting, owner name, and who the rest of the screen is about.
///
/// Watches the two providers it reads rather than letting the whole
/// dashboard watch them, so renaming a pet or editing the owner repaints
/// this strip instead of every card below it.
class _Header extends StatelessWidget {
  const _Header();

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetInfoProvider>();
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                        color: context.c.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _ownerName(pets, auth),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 25,
                        weight: FontWeight.w800,
                        color: context.c.ink,
                        letterSpacing: -0.9,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundAction(
                semanticLabel: 'Notifications',
                onTap: () => context.push(AppRoutes.inbox),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 21,
                  color: context.c.actionText,
                ),
              ),
              const SizedBox(width: 10),
              _RoundAction(
                semanticLabel: 'Account',
                onTap: () => context.go(AppRoutes.account),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 21,
                  color: context.c.actionText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _PetStrip(),
        ],
      ),
    );
  }

  /// The owner record first, the account second.
  ///
  /// `auth.firstName` is empty for an email sign-in — [AuthProvider.signIn]
  /// has no name to read off the credential — so relying on it showed those
  /// users their username. The owner form is where they actually typed their
  /// name, so it leads.
  static String _ownerName(PetInfoProvider pets, AuthProvider auth) {
    final owner = pets.ownerInfo?.name.trim() ?? '';
    if (owner.isNotEmpty) return owner.split(' ').first;

    final account = auth.firstName.trim().isNotEmpty
        ? auth.firstName.trim()
        : auth.displayName.trim();
    return account.isEmpty ? 'Welcome back' : account;
  }
}

/// Who the dashboard is currently about: avatar, name, breed and age.
///
/// Also the pet switcher. Every card below reads the active pet, and
/// [QuizProvider] is bound to it in main.dart, so changing the selection
/// here repaints the whole screen against the new pet with no other wiring.
class _PetStrip extends StatelessWidget {
  const _PetStrip();

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetInfoProvider>();
    final pet = pets.activePet;

    if (pet == null) return const _NoPetStrip();

    final switchable = pets.petCount > 1;

    return Semantics(
      button: switchable,
      label: switchable ? 'Switch pet. Showing ${pet.name}' : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: switchable ? () => _openSwitcher(context) : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: BoxDecoration(
            color: context.c.surfaceRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Row(
            children: [
              PhotoAvatar(photoPath: pet.photoPath, size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 15,
                        weight: FontWeight.w800,
                        color: context.c.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      petSubtitle(pet),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(size: 12.5, color: context.c.body),
                    ),
                  ],
                ),
              ),
              if (switchable) ...[
                const SizedBox(width: 8),
                Text(
                  '${pets.petCount} pets',
                  style: AppTheme.font(
                    size: 12,
                    weight: FontWeight.w700,
                    color: context.c.actionText,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 17,
                  color: context.c.actionText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openSwitcher(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PetSwitcherSheet(),
    );
  }
}

/// Breed and age on one line, skipping whichever is missing.
///
/// Both are optional in practice: the pet form lets someone save a name and
/// come back later, and "Beagle · " with nothing after it reads as a bug.
@visibleForTesting
String petSubtitle(PetInfo pet) {
  final parts = [
    if (pet.breed.trim().isNotEmpty) pet.breed.trim(),
    ?petAgeLabel(pet),
  ];
  return parts.isEmpty ? 'Tap to add details' : parts.join(' · ');
}

/// A readable age, or null when none was recorded.
///
/// Months are dropped once a pet is over two, where "4 yr 3 mo" is more
/// precision than anyone reads; under a year the months are the whole story.
@visibleForTesting
String? petAgeLabel(PetInfo pet) {
  final years = pet.ageYears;
  final months = pet.ageMonths;

  if (years <= 0 && months <= 0) return null;
  if (years <= 0) return months == 1 ? '1 month' : '$months months';
  if (years > 2 || months == 0) return years == 1 ? '1 year' : '$years years';
  return '$years yr $months mo';
}

/// The strip before there is a pet to show.
class _NoPetStrip extends StatelessWidget {
  const _NoPetStrip();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // The router gates this route on consent, so someone who has not
      // signed yet is sent to the form and returned here afterwards.
      onTap: () => context.push(AppRoutes.petInfo),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      background: context.c.tintPanel,
      borderColor: context.c.actionText.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.c.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_rounded,
              size: 22,
              color: context.c.actionText,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add your first pet',
                  style: AppTheme.font(
                    size: 15,
                    weight: FontWeight.w800,
                    color: context.c.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'The assessment needs one to score',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(size: 12.5, color: context.c.body),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: context.c.faint,
          ),
        ],
      ),
    );
  }
}

/// Picks which pet the dashboard is about.
class _PetSwitcherSheet extends StatelessWidget {
  const _PetSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetInfoProvider>();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: context.c.dotInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Your pets', style: context.t.h3),
            const SizedBox(height: 6),
            Text(
              'The dashboard, reports and recommendations all follow this '
              'choice.',
              style: AppTheme.font(size: 13.5, color: context.c.body),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < pets.petCount; i++) ...[
              _PetRow(
                pet: pets.pets[i],
                selected: i == pets.activePetIndex,
                onTap: () {
                  context.read<PetInfoProvider>().setActivePet(i);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// One row in the switcher, styled to match the language sheet.
class _PetRow extends StatelessWidget {
  final PetInfo pet;
  final bool selected;
  final VoidCallback onTap;

  const _PetRow({
    required this.pet,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.c.tintPanel : context.c.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
            border: Border.all(
              color: selected ? context.c.actionText : context.c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              PhotoAvatar(photoPath: pet.photoPath, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 15,
                        weight: FontWeight.w700,
                        color: context.c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      petSubtitle(pet),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(size: 12.5, color: context.c.muted),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: context.c.actionText,
                ),
            ],
          ),
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
          decoration: BoxDecoration(
            color: context.c.surfaceRaised,
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
    final history = quiz.assessmentHistory;
    final result = quiz.result;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.c.heroGradient,
          stops: const [0, 0.55, 1],
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
              color: context.c.onAccent,
              opacity: 0.07,
              rotation: -0.24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: context.c.onAccent.withValues(alpha: 0.75),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (result == null)
                          Text(
                            'Not assessed yet',
                            style: AppTheme.font(
                              size: 20,
                              weight: FontWeight.w800,
                              color: context.c.onAccent,
                              letterSpacing: -0.5,
                            ),
                          )
                        else
                          // Wrap, not Row: at larger text scales the band and
                          // the trend stop fitting on one line, and a Row
                          // clips the trend rather than moving it down.
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _HeroChip(
                                icon: result.category.bandGlyph,
                                label: result.category.label,
                                emphasised: true,
                              ),
                              if (scoreTrend(history) case final delta?)
                                _HeroChip(
                                  icon: trendIcon(delta),
                                  label: trendLabel(delta),
                                ),
                            ],
                          ),
                        const SizedBox(height: 7),
                        Text(
                          result == null
                              ? 'Take the 45-question assessment'
                              : 'Assessed ${relativeDay(result.completedAt)}',
                          style: AppTheme.font(
                            size: 12.5,
                            color: context.c.onAccent.withValues(alpha: 0.8),
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
                  result == null ? AppRoutes.quiz : AppRoutes.report,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

/// Points gained or lost against the previous assessment, or null when there
/// is nothing to compare against.
///
/// [history] is newest first — QuizProvider inserts at the head and sorts
/// descending after a cloud load — so the comparison is the first two
/// entries, and a pet's very first report has no trend rather than a
/// flattering "+78".
@visibleForTesting
int? scoreTrend(List<ScoreResult> history) {
  if (history.length < 2) return null;
  return history.first.percentageScore - history[1].percentageScore;
}

@visibleForTesting
String trendLabel(int delta) {
  if (delta > 0) return 'Improved by $delta%';
  if (delta < 0) return 'Dropped by ${delta.abs()}%';
  return 'No change';
}

@visibleForTesting
IconData trendIcon(int delta) {
  if (delta > 0) return Icons.arrow_upward_rounded;
  if (delta < 0) return Icons.arrow_downward_rounded;
  return Icons.remove_rounded;
}

/// How long ago something happened, in the words someone would use.
///
/// Coarsens as it recedes: exact days for the first week, then weeks, then
/// months. Precision past that is noise on a dashboard — what matters is
/// whether the last assessment was recent, not that it was 43 days ago.
///
/// A [when] in the future reads as today. Device clocks drift, records sync
/// from other handsets, and "in -1 days" is worse than a day's imprecision.
@visibleForTesting
String relativeDay(DateTime when, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(when.toLocal())).inDays;

  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 7) return '$days days ago';
  if (days < 14) return 'last week';
  if (days < 30) return '${days ~/ 7} weeks ago';
  if (days < 60) return 'last month';
  if (days < 365) return '${days ~/ 30} months ago';
  return 'over a year ago';
}

/// A translucent pill on the hero gradient.
///
/// Deliberately not tinted with the band's own colour: the band palette is
/// built to sit on the light card surface, and dropping #E8654E onto the
/// accent gradient reads as an error state rather than a score.
class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasised;

  const _HeroChip({
    required this.icon,
    required this.label,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final onAccent = context.c.onAccent;

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
      decoration: BoxDecoration(
        color: onAccent.withValues(alpha: emphasised ? 0.22 : 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.font(
              size: 13,
              weight: emphasised ? FontWeight.w800 : FontWeight.w600,
              color: onAccent,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
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
                backgroundColor: context.c.onAccent.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(context.c.onAccent),
              ),
            ),
          ),
          // The % rides as a smaller baseline-aligned suffix so the figure
          // itself keeps the weight, and the pair still fits the ring at the
          // 1.3 text scale the app clamps to.
          Text.rich(
            TextSpan(
              text: percent == null ? '—' : '$percent',
              children: [
                if (percent != null)
                  TextSpan(
                    text: '%',
                    style: AppTheme.font(
                      size: 12,
                      weight: FontWeight.w700,
                      color: context.c.onAccent.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
            style: AppTheme.font(
              size: 19,
              weight: FontWeight.w800,
              color: context.c.onAccent,
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
          color: context.c.onAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            size: 14,
            weight: FontWeight.w800,
            color: context.c.actionText,
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
                    color: context.c.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$answered of $total answered',
                  style: AppTheme.font(size: 12.5, color: context.c.body),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : answered / total,
                    minHeight: 6,
                    backgroundColor: context.c.divider,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(context.c.action),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: context.c.faint,
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
              color: context.c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.font(
              size: 12,
              color: context.c.body,
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
      background: context.c.surfaceLow,
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
                  color: context.c.ink,
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
                      color: categoryBarColor(context.c, entry.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.key} — ${entry.value.round()}%',
                      style: AppTheme.font(
                        size: 13,
                        color: context.c.bodyStrong,
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
