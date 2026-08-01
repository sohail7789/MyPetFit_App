/// One selectable option. [score] contributes to the fitness index; options on
/// unscored questions carry 0.
class Answer {
  final String id;
  final String text;
  final int score;

  const Answer({required this.id, required this.text, required this.score});
}

class Question {
  final String id;
  final String text;
  final List<Answer> answers;

  /// Scored questions feed the fitness index. Category 9 is informational and
  /// is excluded from both the earned total and the maximum.
  final bool isScored;

  /// Multi-select ("pick all that apply"). Never scored.
  final bool isMulti;

  /// Optional free-text follow-up shown beneath the options.
  final String? followLabel;
  final String? followHint;

  const Question({
    required this.id,
    required this.text,
    required this.answers,
    this.isScored = true,
    this.isMulti = false,
    this.followLabel,
    this.followHint,
  });

  bool get hasFollowUp => followLabel != null;

  /// Counted toward the index only when scored and single-select.
  bool get countsTowardScore => isScored && !isMulti;

  int get maxScore =>
      answers.fold(0, (best, a) => a.score > best ? a.score : best);

  int get minScore => answers.fold(
        answers.isEmpty ? 0 : answers.first.score,
        (least, a) => a.score < least ? a.score : least,
      );
}

class QuestionCategory {
  final String id;
  final String name;
  final List<Question> questions;

  const QuestionCategory({
    required this.id,
    required this.name,
    required this.questions,
  });

  List<Question> get scoredQuestions =>
      questions.where((q) => q.countsTowardScore).toList();

  /// Highest total this category can earn.
  int get maxScore =>
      scoredQuestions.fold(0, (sum, q) => sum + q.maxScore);

  /// Floor used when a question is left unanswered, matching the design's
  /// scoring: an unanswered question scores its lowest option.
  int get minScore =>
      scoredQuestions.fold(0, (sum, q) => sum + q.minScore);
}
