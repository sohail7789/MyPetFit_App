import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/question.dart';
import '../../../providers/quiz_provider.dart';
import 'answer_option_card.dart';

class CategoryQuestionList extends StatelessWidget {
  final QuestionCategory category;

  const CategoryQuestionList({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final theme = Theme.of(context);

    return Column(
      children: List.generate(category.questions.length, (qIndex) {
        final question = category.questions[qIndex];
        final selectedAnswer = quiz.selectedAnswerFor(question.id);
        const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${qIndex + 1}. ${question.text}',
                  style: theme.textTheme.titleSmall?.copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
                ...List.generate(question.answers.length, (aIndex) {
                  final answer = question.answers[aIndex];
                  final letter = aIndex < letters.length
                      ? letters[aIndex]
                      : '${aIndex + 1}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AnswerOptionCard(
                      answer: answer,
                      isSelected: selectedAnswer?.id == answer.id,
                      optionLetter: letter,
                      onTap: () {
                        quiz.selectAnswer(question.id, answer);
                      },
                    ),
                  );
                }),
                if (question.hasTextField) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _QuestionTextField(
                    // Key on the question so state is recreated when the
                    // category page swaps to different questions.
                    key: ValueKey('qtf_${question.id}'),
                    questionId: question.id,
                    label: question.textFieldLabel ?? 'Additional details',
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Owns its [TextEditingController] properly.
///
/// The previous implementation built a new controller on every rebuild
/// (`TextEditingController.fromValue` inside build) — leaking controllers,
/// fighting the IME during composition, and snapping the cursor to the end
/// on each provider notify. This widget creates the controller once, seeds
/// it from the provider, and only pushes changes outward.
class _QuestionTextField extends StatefulWidget {
  final String questionId;
  final String label;

  const _QuestionTextField({
    super.key,
    required this.questionId,
    required this.label,
  });

  @override
  State<_QuestionTextField> createState() => _QuestionTextFieldState();
}

class _QuestionTextFieldState extends State<_QuestionTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<QuizProvider>().textFieldValueFor(widget.questionId),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: (value) {
        context
            .read<QuizProvider>()
            .setTextFieldValue(widget.questionId, value);
      },
    );
  }
}
