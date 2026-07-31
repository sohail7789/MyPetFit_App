import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/questions_data.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/category_illustration.dart';
import '../../widgets/dog_progress_track.dart';
import 'widgets/category_question_list.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = quiz.currentCategory;
    final categoryIndex = quiz.currentCategoryIndex;
    final totalCategories = quiz.totalCategories;
    final overallProgress = quiz.overallProgress;

    final pastel = AppTheme.categoryPastels[
        categoryIndex % AppTheme.categoryPastels.length];
    final rawAccent =
        AppTheme.brandAccents[categoryIndex % AppTheme.brandAccents.length];
    // Deep navy tones disappear on the dark background — remap them to the
    // light-blue accent so category theming stays visible in dark mode.
    final accent = isDark &&
            (rawAccent == AppTheme.primary ||
                rawAccent == AppTheme.neutralDark)
        ? AppTheme.accentBlue
        : rawAccent;
    // Text/icon color that passes contrast on top of the accent.
    final onAccent =
        accent.computeLuminance() > 0.45 ? AppTheme.neutralDeep : Colors.white;

    final bgColor = isDark
        ? AppTheme.darkBlueBg
        : Color.lerp(Colors.white, pastel, 0.4)!;

    // Next category name for dynamic button label
    final nextCategoryName = quiz.isLastCategory
        ? null
        : healthCategories[categoryIndex + 1].name;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (quiz.canGoBack) {
          quiz.previousCategory();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (quiz.canGoBack) {
                quiz.previousCategory();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          title: Text(
            'Category ${categoryIndex + 1} of $totalCategories',
            style: theme.textTheme.titleMedium,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.slow,
                  switchInCurve: AppMotion.curve,
                  switchOutCurve: AppMotion.curve,
                  transitionBuilder: (child, animation) {
                    // Subtle fade + rise; the old default fade-only switch
                    // felt static.
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey(categoryIndex),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.sm,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Section header with illustration ───
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? accent.withValues(alpha: 0.14)
                                : null,
                            gradient: isDark
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      pastel,
                                      pastel.withValues(alpha: 0.4),
                                    ],
                                  ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isDark
                                  ? accent.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CategoryIllustration(
                                category: category,
                                categoryIndex: categoryIndex,
                                size: 72,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm + 2,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(
                                            alpha: isDark ? 0.25 : 0.15),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.sm),
                                      ),
                                      child: Text(
                                        '${categoryIndex + 1} / $totalCategories',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // Question list
                        CategoryQuestionList(category: category),

                        const SizedBox(height: AppSpacing.lg),

                        // Dynamic navigation button
                        ElevatedButton(
                          onPressed: quiz.isCurrentCategoryComplete
                              ? () {
                                  HapticFeedback.selectionClick();
                                  if (quiz.isLastCategory) {
                                    quiz.calculateResult();
                                    context.go(AppRoutes.report);
                                  } else {
                                    quiz.nextCategory();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: onAccent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  quiz.isLastCategory
                                      ? 'Complete Assessment'
                                      : 'Move to $nextCategoryName',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!quiz.isLastCategory) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 18),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
              // Animated dog mascot progress track
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                child: DogProgressTrack(
                  progress: overallProgress,
                  label:
                      'Your pet is cheering you on • ${(overallProgress * 100).round()}%',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
