import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../providers/cart_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/add_pet_sheet.dart';
import '../../widgets/blob_background.dart';
import '../../widgets/metric_chart_card.dart';
import '../../widgets/mood_selector_card.dart';
import '../../widgets/mypetfit_logo.dart';
import '../../widgets/wellness_card.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quiz = context.read<QuizProvider>();
      final dashboard = context.read<DashboardProvider>();
      dashboard.seedFromQuiz(quiz.result?.categoryScores);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final petInfo = context.watch<PetInfoProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final quiz = context.watch<QuizProvider>();
    final cart = context.watch<CartProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final ownerName = petInfo.ownerInfo?.name.split(' ').first ?? 'Friend';
    final petName = petInfo.activePet?.name ?? 'your pet';

    return Scaffold(
      body: BlobBackground(
        variant: BlobVariant.scattered,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  final q = context.read<QuizProvider>();
                  final d = context.read<DashboardProvider>();
                  d.seedFromQuiz(q.result?.categoryScores);
                  await Future.delayed(const Duration(milliseconds: 600));
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.lg,
                  AppSpacing.page,
                  100,
                ),
                sliver: SliverList.list(
                  children: [
                    // ─── Greeting header ───
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $ownerName',
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.heading(isDark),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'How is $petName today?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.mutedText(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CircleIconButton(
                          tooltip:
                              isDark ? 'Switch to light' : 'Switch to dark',
                          icon: isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            themeProvider.toggle();
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const MyPetFitLogo.compact(fontSize: 18),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Pet switcher chips ───
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: petInfo.pets.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          if (i == petInfo.pets.length) {
                            return _PetChip.add(
                              isDark: isDark,
                              enabled: petInfo.canAddPet,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                showAddPetSheet(context, petInfo);
                              },
                            );
                          }
                          final p = petInfo.pets[i];
                          final active = i == petInfo.activePetIndex;
                          return _PetChip(
                            label: p.name,
                            emoji: p.species.emoji,
                            active: active,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (active) {
                                _showPetDetailSheet(context, petInfo, i);
                              } else {
                                petInfo.setActivePet(i);
                              }
                            },
                            onLongPress: () =>
                                _showPetDetailSheet(context, petInfo, i),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // ─── Mood selector ───
                    MoodSelectorCard(
                      petName: petName,
                      selected: dashboard.todayMood,
                      onChanged: (m) {
                        HapticFeedback.selectionClick();
                        dashboard.setMood(m);
                      },
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // ─── Latest fitness score / empty state ───
                    if (quiz.result != null)
                      _FitnessScoreBanner(
                        percentage: quiz.result!.percentageScore,
                        emoji: quiz.result!.category.emoji,
                        label: quiz.result!.category.label,
                        onTap: () => context.push(AppRoutes.report),
                      )
                    else
                      _NoScoreCard(
                        onTap: () {
                          context.read<QuizProvider>().reset();
                          context.push(AppRoutes.quiz);
                        },
                      ),
                    const SizedBox(height: AppSpacing.section),

                    // ─── Weight trend ───
                    const _SectionHeader(
                      title: 'Weight trend',
                      subtitle: 'Last 30 days',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MetricChartCard(
                      title: 'Last 30 days',
                      unit: 'kg',
                      points: dashboard.weightHistory,
                      accent: AppTheme.brandBlue,
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // ─── Lifestyle rings ───
                    const _SectionHeader(
                      title: 'Lifestyle',
                      subtitle: 'Activity, nutrition & wellness',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _AnimatedProgressRing(
                            icon: Icons.directions_run_rounded,
                            label: 'Activity',
                            value: dashboard.activityScore,
                            accent: AppTheme.primary,
                            pastel: AppTheme.lightAzure,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _AnimatedProgressRing(
                            icon: Icons.restaurant_rounded,
                            label: 'Nutrition',
                            value: dashboard.nutritionScore,
                            accent: AppTheme.accentBlue,
                            pastel: AppTheme.softPeach,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _AnimatedProgressRing(
                            icon: Icons.favorite_rounded,
                            label: 'Wellness',
                            value: dashboard.wellnessScore,
                            accent: AppTheme.secondary,
                            pastel: AppTheme.softLavender,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // ─── Quick actions ───
                    const _SectionHeader(title: 'Quick actions'),
                    const SizedBox(height: AppSpacing.md),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        // Max-extent instead of a fixed column count keeps
                        // the cards usable from small phones to tablets.
                        maxCrossAxisExtent: 260,
                        mainAxisExtent: 118,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      children: [
                        WellnessCard(
                          icon: Icons.shopping_bag_rounded,
                          title: 'Recommended Products',
                          accent: AppTheme.primary,
                          pastel: AppTheme.lightAzure,
                          onTap: () => context.push(AppRoutes.products),
                        ),
                        WellnessCard(
                          icon: Icons.spa_rounded,
                          title: 'Wellness Hub',
                          accent: AppTheme.secondary,
                          pastel: AppTheme.softPeach,
                          onTap: () => context.push(AppRoutes.wellness),
                        ),
                        WellnessCard(
                          icon: Icons.refresh_rounded,
                          title: 'Retake Assessment',
                          accent: AppTheme.accentBlue,
                          pastel: AppTheme.lightAzure,
                          onTap: () {
                            context.read<QuizProvider>().reset();
                            context.push(AppRoutes.quiz);
                          },
                        ),
                        WellnessCard(
                          icon: Icons.shopping_cart_rounded,
                          title: 'My Cart (${cart.totalItems})',
                          accent: AppTheme.neutralDark,
                          pastel: AppTheme.softLavender,
                          onTap: () => context.push(AppRoutes.cart),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pet detail bottom sheet ──
  void _showPetDetailSheet(
      BuildContext context, PetInfoProvider provider, int index) {
    final pet = provider.pets[index];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.mutedText(isDark).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.tint(
                    isDark, AppTheme.accentBlue, AppTheme.lightAzure),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(pet.species.emoji,
                  style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(pet.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              pet.breed,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText(isDark),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                _DetailChip(
                  icon: Icons.cake_rounded,
                  label: 'Age',
                  value: pet.ageDisplay,
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _DetailChip(
                  icon: pet.gender == PetGender.male
                      ? Icons.male_rounded
                      : Icons.female_rounded,
                  label: 'Gender',
                  value: pet.gender == PetGender.male ? 'Male' : 'Female',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _DetailChip(
                  icon: Icons.monitor_weight_rounded,
                  label: 'Weight',
                  value: '${pet.weightKg} kg',
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _DetailChip(
                  icon: Icons.height_rounded,
                  label: 'Height',
                  value: '${pet.heightCm} cm',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.setActivePet(index);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(index == provider.activePetIndex
                        ? 'Active'
                        : 'Set Active'),
                  ),
                ),
                if (provider.petCount > 1) ...[
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeletePet(context, provider, index);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.errorColor),
                    label: const Text('Remove',
                        style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppTheme.errorColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePet(
      BuildContext context, PetInfoProvider provider, int index) {
    final petName = provider.pets[index].name;
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Remove $petName?'),
        message: const Text('This can\'t be undone.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.removePet(index);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Private widgets
// ───────────────────────────────────────────────────────────────────────────

/// Small circular surface button (theme toggle). Reads as a quiet utility
/// control instead of a bare IconButton floating in space.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.surface(isDark),
        shape: CircleBorder(
          side: BorderSide(color: AppTheme.hairline(isDark), width: 0.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: AppTheme.heading(isDark)),
          ),
        ),
      ),
    );
  }
}

/// Pet switcher chip. Active = filled brand navy; inactive = surface +
/// hairline (adapts to dark, unlike the old fixed pastels).
class _PetChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool active;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isAdd;

  const _PetChip({
    required this.label,
    required this.emoji,
    required this.active,
    required this.isDark,
    this.onTap,
    this.onLongPress,
  }) : isAdd = false;

  const _PetChip.add({
    required this.isDark,
    required bool enabled,
    this.onTap,
  })  : label = 'Add',
        emoji = '',
        active = false,
        isAdd = true,
        onLongPress = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bg;
    final Color fg;
    if (active) {
      bg = AppTheme.primary;
      fg = Colors.white;
    } else {
      bg = AppTheme.surface(isDark);
      fg = AppTheme.heading(isDark);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: active ? AppTheme.primary : AppTheme.hairline(isDark),
            width: active ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdd)
              Icon(Icons.add_rounded, size: 15, color: fg)
            else
              Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _FitnessScoreBanner extends StatelessWidget {
  final int percentage;
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _FitnessScoreBanner({
    required this.percentage,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppTheme.darkBlueSurface, const Color(0xFF232A44)]
                  : [AppTheme.lightAzure, AppTheme.softPeach],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppTheme.hairline(isDark),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBlueBg : Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$percentage%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white : AppTheme.brandBlue,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest fitness score',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.mutedText(isDark),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$emoji  $label',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.heading(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.mutedText(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for "no assessment yet" — now a proper call-to-action that
/// adapts to dark mode (previously a fixed pink slab with dark text).
class _NoScoreCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoScoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.hairline(isDark), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.tint(
                      isDark, AppTheme.secondary, AppTheme.softPeach),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_rounded,
                  color:
                      isDark ? AppTheme.accentPink : AppTheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No assessment yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.heading(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get your pet\'s fitness score in 5 minutes.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.mutedText(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressRing extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color accent;
  final Color pastel;

  const _AnimatedProgressRing({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.pastel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = (value * 100).round();
    // Ring accent needs a lighter tone in dark mode to keep contrast.
    final ringColor = isDark && accent == AppTheme.primary
        ? AppTheme.accentBlue
        : accent;

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline(isDark), width: 0.5),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: AppMotion.curve,
              builder: (context, animVal, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: animVal,
                        strokeWidth: 5,
                        backgroundColor: isDark
                            ? ringColor.withValues(alpha: 0.18)
                            : pastel,
                        valueColor: AlwaysStoppedAnimation(ringColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(icon, color: ringColor, size: 22),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$pct%',
            style: theme.textTheme.titleMedium?.copyWith(color: ringColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedText(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg - 2),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBlueBg : AppTheme.lightAzure,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              // Navy on dark surface failed contrast — use the light accent.
              color: isDark ? AppTheme.accentBlue : AppTheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedText(isDark),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Section header: bold title + optional muted subtitle.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
