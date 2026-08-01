import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import 'widgets/question_card.dart';

/// Screens 13–21 — one screen per assessment category.
///
/// The category index lives in [QuizProvider], so backing out and returning
/// resumes where the user left off.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _advance(QuizProvider quiz) {
    if (quiz.isLastCategory) {
      context.push(AppRoutes.scoring);
      return;
    }
    quiz.nextCategory();
    _scroll.jumpTo(0);
  }

  void _back(QuizProvider quiz) {
    if (quiz.canGoBack) {
      quiz.previousCategory();
      _scroll.jumpTo(0);
    } else {
      context.backOr(AppRoutes.home);
    }
  }

  /// 1-based number of the first question in [index] across the whole
  /// questionnaire, so cards read 1…45 rather than restarting each category.
  int _questionOffset(QuizProvider quiz, int index) {
    var offset = 0;
    for (var i = 0; i < index; i++) {
      offset += quiz.categories[i].questions.length;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final index = quiz.currentCategoryIndex;
    final category = quiz.currentCategory;
    final offset = _questionOffset(quiz, index);
    final remaining = quiz.remainingInCategory(index);
    final ready = remaining == 0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              progress: quiz.overallProgress,
              answeredLabel: '${quiz.answeredCount} / ${quiz.totalQuestions}',
              onBack: () => _back(quiz),
            ),
            _CategoryHeading(
              index: index,
              total: quiz.totalCategories,
              title: category.name,
            ),
            Expanded(
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 10),
                itemCount: category.questions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final question = category.questions[i];
                  return QuestionCard(
                    // Keyed so state is not reused across categories.
                    key: ValueKey(question.id),
                    question: question,
                    number: offset + i + 1,
                    isSelected: (a) => quiz.isOptionSelected(question, a),
                    onSelect: (a) => question.isMulti
                        ? quiz.toggleMultiAnswer(question.id, a)
                        : quiz.selectAnswer(question.id, a),
                    followValue: quiz.textFieldValueFor(question.id),
                    onFollowChanged: question.hasFollowUp
                        ? (v) => quiz.setTextFieldValue(question.id, v)
                        : null,
                  );
                },
              ),
            ),
            _Footer(
              progress: quiz.overallProgress,
              ready: ready,
              label: quiz.isLastCategory ? 'See my score' : 'Next category',
              blockedLabel: remaining == 1
                  ? '1 question left'
                  : '$remaining questions left',
              onNext: () => _advance(quiz),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double progress;
  final String answeredLabel;
  final VoidCallback onBack;

  const _Header({
    required this.progress,
    required this.answeredLabel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 40,
            semanticLabel: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEDEBF4),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.action),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            answeredLabel,
            style: AppTheme.font(
              size: 13,
              weight: FontWeight.w700,
              color: AppTheme.action,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeading extends StatelessWidget {
  final int index;
  final int total;
  final String title;

  const _CategoryHeading({
    required this.index,
    required this.total,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1F9),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: DesignImage(
              AppAssets.categoryFace(index),
              width: 64,
              height: 64,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CATEGORY ${index + 1} OF $total',
                  style: AppTheme.font(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppTheme.start,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: AppTheme.h3.copyWith(height: 1.15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final double progress;
  final bool ready;
  final String label;
  final String blockedLabel;
  final VoidCallback onNext;

  const _Footer({
    required this.progress,
    required this.ready,
    required this.label,
    required this.blockedLabel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The walker tracks overall progress along the footer rule.
          Positioned(
            top: -44,
            left: 0,
            right: 0,
            height: 64,
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final clamped = progress.clamp(0.06, 0.94);
                  return AnimatedAlign(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(clamped * 2 - 1, 0),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Lottie.asset(
                        AppAssets.walker,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
            child: AppButton(
              label: ready ? label : blockedLabel,
              height: AppTheme.ctaHeightCompact,
              icon: ready
                  ? const Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: Colors.white,
                    )
                  : null,
              onPressed: ready ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}
