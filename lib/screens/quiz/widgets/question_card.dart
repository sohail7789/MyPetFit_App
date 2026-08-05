import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/question.dart';
import '../../../widgets/app_icons.dart';
import '../../../widgets/labeled_field.dart';

/// One question from the assessment: number, prompt, option list and an
/// optional free-text follow-up.
class QuestionCard extends StatefulWidget {
  final Question question;

  /// 1-based position across the whole questionnaire.
  final int number;

  final bool Function(Answer) isSelected;
  final ValueChanged<Answer> onSelect;

  final String? followValue;
  final ValueChanged<String>? onFollowChanged;

  const QuestionCard({
    super.key,
    required this.question,
    required this.number,
    required this.isSelected,
    required this.onSelect,
    this.followValue,
    this.onFollowChanged,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  TextEditingController? _follow;

  @override
  void initState() {
    super.initState();
    if (widget.question.hasFollowUp) {
      _follow = TextEditingController(text: widget.followValue ?? '');
    }
  }

  @override
  void dispose() {
    _follow?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: context.c.surfaceLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: context.c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 10),
                child: Text(
                  '${widget.number}',
                  style: AppTheme.font(
                    size: 12,
                    weight: FontWeight.w800,
                    color: context.c.body,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  question.text,
                  style: AppTheme.font(
                    size: 15,
                    weight: FontWeight.w700,
                    color: context.c.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < question.answers.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == question.answers.length - 1 ? 0 : 8,
              ),
              child: _Option(
                answer: question.answers[i],
                // Multi-select marks every pick with a tick; single-select
                // labels its options A, B, C…
                mark: widget.isSelected(question.answers[i])
                    ? null
                    : String.fromCharCode(65 + i),
                selected: widget.isSelected(question.answers[i]),
                onTap: () => widget.onSelect(question.answers[i]),
              ),
            ),
          if (question.hasFollowUp) ...[
            const SizedBox(height: 10),
            LabeledField(
              label: question.followLabel!,
              hint: question.followHint ?? '',
              height: 48,
              controller: _follow,
              onChanged: widget.onFollowChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final Answer answer;

  /// Letter shown when unselected; a tick replaces it when selected.
  final String? mark;

  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.answer,
    required this.mark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, selected ? -1 : 0, 0),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.c.surfaceRaised : context.c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(
            color: selected ? context.c.actionText : context.c.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.c.action.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: -10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? context.c.action : context.c.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.c.actionText : context.c.dotInactive,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? AppIcon(AppIcons.check(context.c.onAccent, 3.4), size: 11)
                  : Text(
                      mark ?? '',
                      style: AppTheme.font(
                        size: 11,
                        weight: FontWeight.w800,
                        color: context.c.placeholder,
                      ),
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                answer.text,
                style: AppTheme.font(
                  size: 14,
                  weight: FontWeight.w600,
                  color: selected ? context.c.ink : context.c.bodyStrong,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
