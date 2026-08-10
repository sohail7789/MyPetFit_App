import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../analytics/models/assessment_cadence.dart';
import '../../config/theme.dart';
import '../../data/product_recommendations.dart';
import '../../data/questions_data.dart';
import '../../models/pet_info.dart';
import '../../models/product.dart';
import '../../models/product_palette.dart';
import '../../models/score_band.dart';
import '../../models/score_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/quiz_provider.dart';
import '../shop/widgets/product_tile.dart' show ProductArt, formatPrice;
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                children: [
                  // Scrolls with the page rather than sitting above it.
                  //
                  // The greeting and pet strip used to be a fixed sibling of
                  // this list, on the Scaffold's opaque surface colour — so
                  // the cards slid underneath an opaque white band and the
                  // score card was cut in half by it. Nothing about the
                  // header needed to be pinned: it is identity, not a
                  // control, and reading it once at the top is enough.
                  const _Header(),
                  const SizedBox(height: 16),
                  _ScoreCard(quiz: quiz),
                  if (quiz.hasResumableProgress) ...[
                    const SizedBox(height: 14),
                    _ResumeCard(
                      answered: quiz.answeredCount,
                      total: quiz.totalQuestions,
                      onTap: () => context.push(AppRoutes.quiz),
                    ),
                  ],
                  if (assessmentReminder(quiz.result) case final reminder?) ...[
                    const SizedBox(height: 12),
                    _ReminderBanner(reminder: reminder),
                  ],
                  const SizedBox(height: 14),
                  const _QuickActions(),
                  const SizedBox(height: 14),
                  _RecommendationCard(quiz: quiz, petName: petName),
                  const SizedBox(height: 14),
                  _CategoryCard(quiz: quiz),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal inset that brings the header back to the design's 24 once the
/// list's own 22 is accounted for.
const _headerInset = EdgeInsets.fromLTRB(2, 16, 2, 0);

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
      padding: _headerInset,
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

    if (pet == null) {
      // Data-first: only a provider with nothing to show *and* nothing read
      // yet gets the skeleton. Otherwise a returning user watched "Add your
      // first pet" flash before their own pet arrived, which reads as data
      // loss rather than as loading.
      return pets.isLoaded ? const _NoPetStrip() : const _PetStripSkeleton();
    }

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
                        // Only the invitation. When a report exists, how long
                        // ago it was is the reminder banner's line — saying
                        // it in both places is the same sentence twice.
                        if (result == null) ...[
                          const SizedBox(height: 7),
                          Text(
                            'Take the 45-question assessment',
                            style: AppTheme.font(
                              size: 12.5,
                              color: context.c.onAccent.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
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
                    valueColor: AlwaysStoppedAnimation<Color>(context.c.action),
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

/// Every scored category from the last report, weakest first, with the
/// strongest and weakest called out above them.
///
/// Weakest first because the list is meant to be acted on: the categories a
/// user can do something about belong at the top, not buried under the ones
/// already going well.
///
/// Replaces the old "This week's focus", which showed the same data cut to
/// three rows and only appeared once a report existed.
class _CategoryCard extends StatelessWidget {
  final QuizProvider quiz;

  const _CategoryCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    // Data first: a restored report is worth showing even if the local read
    // has not finished flipping isLoaded, and a skeleton drawn over real
    // scores is a worse answer than the scores.
    final ranked = rankedCategories(quiz.result);
    if (ranked.isEmpty) {
      return quiz.isLoaded
          ? const _CategoryPreview()
          : const _CategorySkeleton();
    }

    return AppCard(
      background: context.c.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Category breakdown',
                  style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w800,
                    color: context.c.ink,
                  ),
                ),
              ),
              Text(
                '${ranked.length} areas',
                style: AppTheme.font(size: 12, color: context.c.muted),
              ),
            ],
          ),
          // One scored category means best and worst are the same row, and
          // two tiles saying the same thing reads as a bug.
          if (ranked.length > 1) ...[
            const SizedBox(height: 12),
            // IntrinsicHeight so the two tiles match even when one name
            // wraps to a second line. `stretch` alone cannot do it here:
            // the row's height is unbounded inside the scrolling column, and
            // stretching against an unbounded cross axis fails to lay out.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ExtremeTile(
                      caption: 'STRONGEST',
                      entry: ranked.last,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ExtremeTile(
                      caption: 'NEEDS WORK',
                      entry: ranked.first,
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (var i = 0; i < ranked.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == ranked.length - 1 ? 0 : 11),
              child: _CategoryBar(entry: ranked[i]),
            ),
        ],
      ),
    );
  }
}

/// Scored categories from [result], weakest first.
///
/// Empty when there is no report, and also when a report carries no
/// breakdown — records written before `categoryScores` existed decode to an
/// empty map, and those should fall to the same preview as a new account
/// rather than rendering a card with nothing in it.
///
/// Ties break on the category name so the order cannot shuffle between
/// rebuilds for two areas that happen to score the same.
@visibleForTesting
List<MapEntry<String, double>> rankedCategories(ScoreResult? result) {
  final scores = result?.categoryScores ?? const <String, double>{};
  return scores.entries.toList()..sort((a, b) {
    final byScore = a.value.compareTo(b.value);
    return byScore != 0 ? byScore : a.key.compareTo(b.key);
  });
}

/// The strongest or weakest area, called out above the full list.
class _ExtremeTile extends StatelessWidget {
  final String caption;
  final MapEntry<String, double> entry;
  final IconData icon;

  const _ExtremeTile({
    required this.caption,
    required this.entry,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = categoryBarColor(context.c, entry.value);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 4),
              Text(
                caption,
                style: AppTheme.font(
                  size: 10.5,
                  weight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            entry.key,
            // Two lines: the longest category names run to 28 characters and
            // will not fit a half-width tile on one.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              size: 13,
              weight: FontWeight.w700,
              color: context.c.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${entry.value.round()}%',
            style: AppTheme.font(
              size: 17,
              weight: FontWeight.w800,
              color: accent,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// One category: its name, its score, and a bar coloured by the same
/// cutoffs the overall bands use.
class _CategoryBar extends StatelessWidget {
  final MapEntry<String, double> entry;

  const _CategoryBar({required this.entry});

  @override
  Widget build(BuildContext context) {
    final percent = entry.value.clamp(0, 100).toDouble();
    final accent = categoryBarColor(context.c, percent);

    return Semantics(
      label: '${entry.key}, ${percent.round()} percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(size: 13, color: context.c.bodyStrong),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percent.round()}%',
                style: AppTheme.font(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: context.c.divider,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the assessment covers, before there is a report to show.
///
/// The nine real category names rather than a "no data" line: someone who
/// has not been assessed learns what they would get, which is a better use
/// of the space than repeating the hero's invitation.
class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      background: context.c.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What the assessment covers',
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w800,
              color: context.c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Each area is scored separately, so you can see exactly where to '
            'start.',
            style: AppTheme.font(
              size: 12.5,
              color: context.c.body,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final category in healthCategories)
                if (category.maxScore > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.c.border),
                    ),
                    child: Text(
                      category.name,
                      style: AppTheme.font(
                        size: 12,
                        weight: FontWeight.w600,
                        color: context.c.body,
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Placeholder rows while the persisted assessments are still being read.
///
/// The router only lands on the dashboard once startup reports ready, so
/// this is a narrow window — but the screen is also reachable by tab while
/// a reload is in flight, and empty space there reads as "no data".
class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor) => Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthFactor,
            child: Container(
              height: 11,
              decoration: BoxDecoration(
                color: context.c.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: context.c.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: 'Loading category breakdown',
      child: AppCard(
        background: context.c.surfaceLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.45,
              child: Container(
                height: 13,
                decoration: BoxDecoration(
                  color: context.c.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            bar(0.55),
            bar(0.7),
            bar(0.4),
          ],
        ),
      ),
    );
  }
}

/// Products merchandising has tagged for the pet's weakest scoring area.
///
/// Deterministic and explicit: the weakest category from the latest report
/// is matched against each product's `recommendedFor`. Nothing is inferred
/// from a product's name, description or shop category, so a product appears
/// here only because someone put it there.
class _RecommendationCard extends StatelessWidget {
  final QuizProvider quiz;
  final String petName;

  const _RecommendationCard({required this.quiz, required this.petName});

  @override
  Widget build(BuildContext context) {
    // Watched here rather than by the dashboard, so the catalog arriving
    // repaints this card instead of every card on the screen.
    final catalog = context.watch<ProductProvider>();

    final ranked = rankedCategories(quiz.result);
    if (ranked.isEmpty) {
      return quiz.isLoaded
          ? const _NoAssessmentYet()
          : const _RecommendationSkeleton();
    }

    final weakest = ranked.first.key;
    if (catalog.loading) return const _RecommendationSkeleton();

    final matches = recommendedProducts(catalog.products, weakest);
    if (matches.isEmpty) return const _NoRecommendations();

    return _RecommendationShell(
      petName: petName,
      child: matches.length == 1
          ? _FeaturedProduct(product: matches.single)
          : _ProductCarousel(products: matches),
    );
  }
}

/// Title, subtitle and whatever presentation the matches call for.
class _RecommendationShell extends StatelessWidget {
  final String petName;
  final Widget child;

  const _RecommendationShell({required this.petName, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            petName.isEmpty
                ? 'Recommended for you'
                : 'Recommended for $petName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w800,
              color: context.c.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Based on your latest assessment',
            style: AppTheme.font(size: 12.5, color: context.c.body),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

/// The single-match presentation: art beside the copy, full-width CTA.
class _FeaturedProduct extends StatelessWidget {
  final Product product;

  const _FeaturedProduct({required this.product});

  @override
  Widget build(BuildContext context) {
    final palette = ProductPalette.of(context, product.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.tint,
                borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
              ),
              clipBehavior: Clip.antiAlias,
              child: ProductArt(product: product, pawSize: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CategoryChip(label: product.displayTag),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      size: 14.5,
                      weight: FontWeight.w800,
                      color: context.c.ink,
                      height: 1.25,
                    ),
                  ),
                  if (_blurbOf(product) case final blurb?) ...[
                    const SizedBox(height: 4),
                    Text(
                      blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        size: 12,
                        color: context.c.body,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    formatPrice(product.price),
                    style: AppTheme.font(
                      size: 16,
                      weight: FontWeight.w800,
                      color: context.c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _ViewProductButton(product: product),
      ],
    );
  }
}

/// The many-match presentation.
///
/// A fixed height with horizontal scrolling: the card lives in a vertical
/// list, so the row has no height of its own to inherit, and letting the
/// tallest product decide it would make the dashboard jump as the catalog
/// loads.
class _ProductCarousel extends StatelessWidget {
  final List<Product> products;

  const _ProductCarousel({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 254,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (context, i) =>
            SizedBox(width: 168, child: _CarouselProduct(product: products[i])),
      ),
    );
  }
}

class _CarouselProduct extends StatelessWidget {
  final Product product;

  const _CarouselProduct({required this.product});

  @override
  Widget build(BuildContext context) {
    final palette = ProductPalette.of(context, product.category);

    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
        border: Border.all(color: context.c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 82,
            color: palette.tint,
            padding: const EdgeInsets.all(8),
            child: ProductArt(product: product, pawSize: 30),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryChip(label: product.displayTag),
                  const SizedBox(height: 6),
                  // Expanded, so the copy gives up room before the price and
                  // the CTA do — those must never be pushed off the card.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                            size: 13,
                            weight: FontWeight.w700,
                            color: context.c.ink,
                            height: 1.25,
                          ),
                        ),
                        if (_blurbOf(product) case final blurb?) ...[
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              blurb,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.font(
                                size: 11.5,
                                color: context.c.body,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPrice(product.price),
                    maxLines: 1,
                    style: AppTheme.font(
                      size: 14.5,
                      weight: FontWeight.w800,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ViewProductButton(product: product, compact: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The short line under a product name.
///
/// `purpose` is the design's "why this pick" copy and reads better here than
/// the full description; the description stands in when a product has not
/// been given one, and neither is guaranteed.
String? _blurbOf(Product product) {
  for (final copy in [product.purpose, product.description]) {
    if (copy.trim().isNotEmpty) return copy.trim();
  }
  return null;
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.c.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.font(
          size: 10.5,
          weight: FontWeight.w800,
          color: context.c.actionText,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Opens the existing product detail screen. Nothing there changes.
class _ViewProductButton extends StatelessWidget {
  final Product product;
  final bool compact;

  const _ViewProductButton({required this.product, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final height = compact ? 32.0 : 42.0;

    return Semantics(
      button: true,
      label: 'View ${product.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('${AppRoutes.productDetail}/${product.id}'),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.c.action,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Text(
            'View Product',
            maxLines: 1,
            style: AppTheme.font(
              size: compact ? 12 : 13.5,
              weight: FontWeight.w800,
              color: context.c.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nothing to recommend from, because nothing has been assessed.
///
/// Explains why the card is empty and stops there. It carried its own
/// "Start Assessment" button, which — alongside the hero's CTA and the
/// quick action — put three identical calls to action on one screen.
class _NoAssessmentYet extends StatelessWidget {
  const _NoAssessmentYet();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recommendations',
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w800,
              color: context.c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete an assessment to receive personalized recommendations.',
            style: AppTheme.font(
              size: 12.5,
              color: context.c.body,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Assessed, but merchandising has tagged nothing for the weakest area.
///
/// Deliberately does not name that area: the category summary sits directly
/// below and already calls it out under "NEEDS WORK", so repeating it here
/// is duplication rather than context.
class _NoRecommendations extends StatelessWidget {
  const _NoRecommendations();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w800,
              color: context.c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No recommendations available yet.',
            style: AppTheme.font(
              size: 12.5,
              color: context.c.body,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder cards while the catalog is in flight.
class _RecommendationSkeleton extends StatelessWidget {
  const _RecommendationSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double widthFactor = 1}) =>
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: context.c.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );

    return Semantics(
      label: 'Loading recommendations',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            block(13, widthFactor: 0.5),
            const SizedBox(height: 8),
            block(10, widthFactor: 0.7),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: context.c.divider,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusCardSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      block(11, widthFactor: 0.4),
                      const SizedBox(height: 8),
                      block(11),
                      const SizedBox(height: 8),
                      block(11, widthFactor: 0.6),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            block(42),
          ],
        ),
      ),
    );
  }
}

/// Where a pet stands on assessment cadence.
typedef AssessmentReminder = ({String label, IconData icon, bool isDue});

/// The cadence line for [latest], or null when nothing has been assessed.
///
/// Null rather than a "never assessed" string: the hero already carries that
/// invitation, and a banner repeating it under a card that just said it is
/// noise. The banner exists to say what the hero does not — whether the
/// score on it is still current.
@visibleForTesting
AssessmentReminder? assessmentReminder(ScoreResult? latest, {DateTime? now}) {
  if (latest == null) return null;

  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today
      .difference(DateUtils.dateOnly(latest.completedAt.toLocal()))
      .inDays;

  if (days <= 0) {
    return (
      label: 'Assessment completed today',
      icon: Icons.check_circle_rounded,
      isDue: false,
    );
  }
  // The retake interval is the analytics module's policy, not this screen's.
  // It used to be a private constant here, a second copy of the ninety days
  // the report card advises in prose — the banner and the health overview
  // must never disagree about whether an assessment is due.
  final due = AssessmentCadence.standard.dueFrom(
    latest.completedAt,
    now: now ?? DateTime.now(),
  );
  if (due != null && due.isDue) {
    return (
      label: 'Assessment due',
      icon: Icons.event_repeat_rounded,
      isDue: true,
    );
  }
  return (
    label: 'Last assessment ${relativeDay(latest.completedAt, now: now)}',
    icon: Icons.schedule_rounded,
    isDue: false,
  );
}

/// The cadence line under the score.
///
/// Tappable only when something is due — a banner that merely reports a
/// recent assessment has nowhere useful to send anyone.
class _ReminderBanner extends StatelessWidget {
  final AssessmentReminder reminder;

  const _ReminderBanner({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final accent = reminder.isDue
        ? context.c.warningText
        : context.c.actionText;

    return Semantics(
      button: reminder.isDue,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: reminder.isDue
            ? () {
                context.read<QuizProvider>().reset();
                context.push(AppRoutes.quiz);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(reminder.icon, size: 16, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  reminder.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: context.c.bodyStrong,
                  ),
                ),
              ),
              if (reminder.isDue) ...[
                const SizedBox(width: 8),
                Text(
                  'Retake',
                  style: AppTheme.font(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The four places someone goes from here.
///
/// A compact row rather than the two tall cards it replaces: four of those
/// would push the recommendation and category cards off the fold, and this
/// screen has already run out of vertical room to spend.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Assessment',
            semanticLabel: 'Start assessment',
            // Same behaviour as the tile this replaces: clear the draft,
            // then straight into the questionnaire. The router gates /quiz
            // on consent, so an unsigned account is asked there and returned.
            onTap: () {
              context.read<QuizProvider>().reset();
              context.push(AppRoutes.quiz);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.insert_chart_outlined_rounded,
            label: 'Reports',
            semanticLabel: 'View reports',
            onTap: () => context.go(AppRoutes.reportHistory),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.pets_outlined,
            label: 'My pets',
            semanticLabel: 'My pets',
            onTap: () => context.push(AppRoutes.pets),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.storefront_outlined,
            label: 'Shop',
            semanticLabel: 'Shop products',
            onTap: () => context.go(AppRoutes.shop),
          ),
        ),
      ],
    );
  }
}

/// One quick action: a tinted glyph over a short label.
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      // A container that replaces the child's own semantics: the visible
      // label is shortened to fit four across, and "Assessment" alone is a
      // worse thing to hear read out than "Start assessment".
      container: true,
      excludeSemantics: true,
      // The action belongs on the node. Excluding the child's semantics to
      // replace the shortened visible label also excluded the detector's tap
      // action, leaving four buttons a screen reader could read and not use.
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.c.surfaceRaised,
                borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
              ),
              child: Icon(icon, size: 22, color: context.c.actionText),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                size: 11.5,
                weight: FontWeight.w700,
                color: context.c.bodyStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pet strip before SharedPreferences has been read.
///
/// Without it a returning user sees "Add your first pet" flash before their
/// own pet arrives, which reads as data loss rather than as loading.
class _PetStripSkeleton extends StatelessWidget {
  const _PetStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your pets',
      // A container of its own. The skeleton's children are bare decoration
      // with no semantics to annotate, so without this the label had no node
      // to live on and merged into whatever ancestor happened to be nearest
      // — which meant whether a screen reader announced the loading state at
      // all depended on the surrounding layout.
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: context.c.surfaceRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.c.divider,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.35,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: context.c.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: context.c.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
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
