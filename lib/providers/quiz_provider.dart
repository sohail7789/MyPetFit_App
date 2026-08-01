import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/questions_data.dart';
import '../models/question.dart';
import '../models/score_result.dart';

/// Holds assessment progress and computes the fitness index.
///
/// Scoring follows the design exactly: an unanswered scored question counts as
/// its *lowest* option rather than zero, and the overall percentage is
/// normalised between the worst and best achievable totals.
class QuizProvider extends ChangeNotifier {
  static const int maxHistory = 5;
  static const _key = 'quiz_state';

  int _currentCategoryIndex = 0;
  final Map<String, Answer> _selectedAnswers = {};

  /// Selected option ids for multi-select questions.
  final Map<String, Set<String>> _multiAnswers = {};

  final Map<String, String> _textFieldValues = {};
  ScoreResult? _result;
  final List<ScoreResult> _assessmentHistory = [];
  bool _isLoaded = false;

  // --- Getters ---------------------------------------------------------

  List<QuestionCategory> get categories => healthCategories;
  int get currentCategoryIndex => _currentCategoryIndex;
  QuestionCategory get currentCategory =>
      healthCategories[_currentCategoryIndex];
  int get totalCategories => healthCategories.length;
  bool get isLoaded => _isLoaded;

  /// Total questions in the questionnaire, scored or not.
  int get totalQuestions => allQuestions.length;

  /// Questions the user has engaged with — the progress bar and the home
  /// screen's resume card both count every question, not just scored ones.
  int get answeredCount => allQuestions
      .where((q) => q.isMulti
          ? (_multiAnswers[q.id]?.isNotEmpty ?? false)
          : _selectedAnswers.containsKey(q.id))
      .length;

  double get overallProgress =>
      totalQuestions == 0 ? 0 : answeredCount / totalQuestions;

  /// True when an assessment is part-done and worth offering to resume.
  bool get hasResumableProgress =>
      answeredCount > 0 && answeredCount < totalQuestions;

  /// Scored questions still unanswered in [index].
  int remainingInCategory(int index) {
    if (index < 0 || index >= healthCategories.length) return 0;
    return healthCategories[index]
        .scoredQuestions
        .where((q) => !_selectedAnswers.containsKey(q.id))
        .length;
  }

  bool isCategoryComplete(int index) => remainingInCategory(index) == 0;

  bool get isCurrentCategoryComplete =>
      isCategoryComplete(_currentCategoryIndex);

  bool get isLastCategory =>
      _currentCategoryIndex == healthCategories.length - 1;

  bool get canGoBack => _currentCategoryIndex > 0;

  ScoreResult? get result => _result;

  /// Last 5 completed assessments, newest first.
  List<ScoreResult> get assessmentHistory =>
      List.unmodifiable(_assessmentHistory);

  bool get hasCompletedAssessment =>
      _result != null || _assessmentHistory.isNotEmpty;

  Answer? selectedAnswerFor(String questionId) => _selectedAnswers[questionId];

  Set<String> multiSelectionFor(String questionId) =>
      _multiAnswers[questionId] ?? const {};

  bool isOptionSelected(Question question, Answer answer) =>
      question.isMulti
          ? multiSelectionFor(question.id).contains(answer.id)
          : _selectedAnswers[question.id]?.id == answer.id;

  String? textFieldValueFor(String questionId) => _textFieldValues[questionId];

  // --- Mutations -------------------------------------------------------

  void selectAnswer(String questionId, Answer answer) {
    _selectedAnswers[questionId] = answer;
    _persistProgress();
    notifyListeners();
  }

  /// Adds or removes [answer] from a multi-select question.
  void toggleMultiAnswer(String questionId, Answer answer) {
    final picks = _multiAnswers.putIfAbsent(questionId, () => <String>{});
    if (!picks.remove(answer.id)) picks.add(answer.id);
    _persistProgress();
    notifyListeners();
  }

  void setTextFieldValue(String questionId, String value) {
    _textFieldValues[questionId] = value;
    _persistProgress();
    notifyListeners();
  }

  void goToCategory(int index) {
    if (index < 0 || index >= healthCategories.length) return;
    _currentCategoryIndex = index;
    _persistProgress();
    notifyListeners();
  }

  void nextCategory() => goToCategory(_currentCategoryIndex + 1);

  void previousCategory() => goToCategory(_currentCategoryIndex - 1);

  // --- Scoring ---------------------------------------------------------

  /// Score earned for [question] — the chosen option, or its worst option
  /// when unanswered.
  int _earnedFor(Question question) =>
      _selectedAnswers[question.id]?.score ?? question.minScore;

  /// Percentage for one category, as shown in the report breakdown. Unlike
  /// the overall score this is a plain earned-over-max ratio.
  double categoryPercent(QuestionCategory category) {
    final max = category.maxScore;
    if (max == 0) return 0;
    final earned = category.scoredQuestions.fold<int>(
      0,
      (sum, q) => sum + _earnedFor(q),
    );
    return (earned / max) * 100;
  }

  /// The overall fitness percentage, without recording a result.
  int get fitnessPercent {
    final span = assessmentMaxScore - assessmentMinScore;
    if (span <= 0) return 0;
    final earned = healthCategories.fold<int>(
      0,
      (sum, c) =>
          sum + c.scoredQuestions.fold<int>(0, (s, q) => s + _earnedFor(q)),
    );
    return (((earned - assessmentMinScore) / span) * 100).round().clamp(0, 100);
  }

  ScoreResult calculateResult() {
    final rawScore = healthCategories.fold<int>(
      0,
      (sum, c) =>
          sum + c.scoredQuestions.fold<int>(0, (s, q) => s + _earnedFor(q)),
    );

    final catScores = <String, double>{
      for (final c in healthCategories)
        if (c.maxScore > 0) c.name: categoryPercent(c),
    };

    _result = ScoreResult.calculate(
      rawScore: rawScore,
      minPossibleScore: assessmentMinScore,
      maxPossibleScore: assessmentMaxScore,
      categoryScores: catScores,
    );

    _assessmentHistory.insert(0, _result!);
    if (_assessmentHistory.length > maxHistory) {
      _assessmentHistory.removeLast();
    }

    _persist();
    notifyListeners();
    return _result!;
  }

  // --- Lifecycle -------------------------------------------------------

  /// Clears the in-progress assessment. History and the last result are kept
  /// so the dashboard and report still show prior scores.
  void reset() {
    _currentCategoryIndex = 0;
    _selectedAnswers.clear();
    _multiAnswers.clear();
    _textFieldValues.clear();
    _result = null;
    _persistProgress();
    notifyListeners();
  }

  /// Wipes both in-memory state and the persisted key. Called on sign-out.
  Future<void> resetAll() async {
    _currentCategoryIndex = 0;
    _selectedAnswers.clear();
    _multiAnswers.clear();
    _textFieldValues.clear();
    _result = null;
    _assessmentHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  // --- Persistence -----------------------------------------------------

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;

        final resultJson = json['result'] as Map<String, dynamic>?;
        if (resultJson != null) _result = ScoreResult.fromJson(resultJson);

        final historyJson = json['history'] as List?;
        if (historyJson != null) {
          _assessmentHistory.addAll(historyJson
              .map((e) => ScoreResult.fromJson(e as Map<String, dynamic>)));
        }

        _currentCategoryIndex =
            (json['categoryIndex'] as num?)?.toInt().clamp(
                      0,
                      healthCategories.length - 1,
                    ) ??
                0;

        // Answers persist by option id and are resolved back against the
        // questionnaire, so a changed question simply drops its old answer.
        final answers = json['answers'] as Map<String, dynamic>?;
        if (answers != null) {
          for (final question in allQuestions) {
            final id = answers[question.id];
            if (id is! String) continue;
            for (final option in question.answers) {
              if (option.id == id) {
                _selectedAnswers[question.id] = option;
                break;
              }
            }
          }
        }

        final multi = json['multi'] as Map<String, dynamic>?;
        if (multi != null) {
          for (final entry in multi.entries) {
            final ids = (entry.value as List?)?.whereType<String>().toSet();
            if (ids != null && ids.isNotEmpty) {
              _multiAnswers[entry.key] = ids;
            }
          }
        }

        final texts = json['texts'] as Map<String, dynamic>?;
        if (texts != null) {
          texts.forEach((k, v) {
            if (v is String) _textFieldValues[k] = v;
          });
        }
      } catch (_) {
        // Corrupt payload — start empty.
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Map<String, dynamic> _snapshot() => {
        if (_result != null) 'result': _result!.toJson(),
        'history': _assessmentHistory.map((r) => r.toJson()).toList(),
        'categoryIndex': _currentCategoryIndex,
        'answers': _selectedAnswers.map((k, v) => MapEntry(k, v.id)),
        'multi': _multiAnswers.map((k, v) => MapEntry(k, v.toList())),
        'texts': _textFieldValues,
      };

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_snapshot()));
  }

  /// In-progress saves are fire-and-forget so answering stays responsive.
  void _persistProgress() {
    _persist();
  }
}
