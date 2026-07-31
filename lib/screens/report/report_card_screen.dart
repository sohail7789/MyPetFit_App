import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/score_result.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/primary_button.dart';
import 'widgets/health_summary_card.dart';

class ReportCardScreen extends StatelessWidget {
  const ReportCardScreen({super.key});

  Color _progressColor(double percentage) {
    if (percentage < 25) return HealthCategory.critical.color;
    if (percentage < 50) return HealthCategory.needsImprovement.color;
    if (percentage < 75) return HealthCategory.good.color;
    return HealthCategory.excellent.color;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quiz = context.watch<QuizProvider>();
    final result = quiz.result;
    final hasHistory = quiz.hasCompletedAssessment;

    // ── No result AND no history → empty state ──
    if (result == null && !hasHistory) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.tint(
                          isDark, AppTheme.accentBlue, AppTheme.lightAzure),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 40,
                      color: isDark
                          ? AppTheme.accentBlue
                          : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('No results yet',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Take the 5-minute health assessment to see your pet\'s full report.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText(isDark),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Start Assessment',
                    onPressed: () {
                      quiz.reset();
                      context.go(AppRoutes.quiz);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final displayResult = result ?? quiz.assessmentHistory.first;
    final categoryColor = displayResult.category.color;
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * 0.35;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Top gradient + overlapping score card
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: topSectionHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor,
                            Color.lerp(
                                categoryColor, AppTheme.neutralDeep, 0.25)!,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Your Pet's Health Report",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayResult.category.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  displayResult.category.label,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Overlapping score card — neutral shadow, not colored.
                    Positioned(
                      left: AppSpacing.xxl,
                      right: AppSpacing.xxl,
                      bottom: -60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface(isDark),
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: AppTheme.hairline(isDark), width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.4 : 0.10),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxxl),
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: displayResult.percentageScore
                                    .toDouble(),
                              ),
                              duration:
                                  const Duration(milliseconds: 1200),
                              curve: AppMotion.curve,
                              builder: (context, value, child) {
                                return Text(
                                  '${value.round()}%',
                                  style: theme.textTheme.displayLarge
                                      ?.copyWith(
                                    color: categoryColor,
                                    fontSize: 56,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Fitness Score',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.mutedText(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 76),

                // Category breakdown
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Breakdown',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...displayResult.categoryScores.entries.map((entry) {
                        final percentage = entry.value;
                        final color = _progressColor(percentage);
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${percentage.round()}%',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 0, end: percentage / 100),
                                duration:
                                    const Duration(milliseconds: 900),
                                curve: AppMotion.curve,
                                builder: (context, v, _) => ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: v,
                                    minHeight: 8,
                                    backgroundColor:
                                        AppTheme.hairline(isDark),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            color),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Summary card
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl),
                  child:
                      HealthSummaryCard(category: displayResult.category),
                ),
                const SizedBox(height: AppSpacing.section),

                // ── Assessment History ──
                if (quiz.assessmentHistory.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assessment History',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Last ${quiz.assessmentHistory.length} assessments',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...quiz.assessmentHistory
                            .asMap()
                            .entries
                            .map((entry) {
                          return _AssessmentHistoryTile(
                            result: entry.value,
                            isLatest: entry.key == 0,
                            isDark: isDark,
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                ],

                // ── Actions ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Go to My Dashboard',
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: () {
                          quiz.reset();
                          context.go(AppRoutes.quiz);
                        },
                        child: const Text('Retake Assessment'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.products),
                        child: const Text('See Recommended Products'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact tile showing one past assessment's date, score, and category.
class _AssessmentHistoryTile extends StatelessWidget {
  final ScoreResult result;
  final bool isLatest;
  final bool isDark;

  const _AssessmentHistoryTile({
    required this.result,
    required this.isLatest,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = result.completedAt;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr =
        '${months[dt.month - 1]} ${dt.day}, ${dt.year} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isLatest
              ? result.category.color.withValues(alpha: 0.5)
              : AppTheme.hairline(isDark),
          width: isLatest ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: result.category.color
                  .withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${result.percentageScore}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: result.category.color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${result.category.emoji}  ${result.category.label}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary
                              .withValues(alpha: isDark ? 0.3 : 0.15),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Latest',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.accentPink
                                : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(dateStr, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
