import 'package:flutter/material.dart';

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
  final bool hasTextField;
  final String? textFieldLabel;
  final bool isScored;

  const Question({
    required this.id,
    required this.text,
    required this.answers,
    this.hasTextField = false,
    this.textFieldLabel,
    this.isScored = true,
  });

  int get maxScore =>
      answers.fold(0, (max, a) => a.score > max ? a.score : max);
}

class QuestionCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<Question> questions;

  const QuestionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.questions,
  });

  List<Question> get scoredQuestions =>
      questions.where((q) => q.isScored).toList();
}
