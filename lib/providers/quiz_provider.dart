import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/questions_data.dart';
import '../models/question.dart';
import '../models/score_result.dart';

class QuizProvider extends ChangeNotifier {
  static const int maxHistory = 5;
  static const _key = 'quiz_state';

  int _currentCategoryIndex = 0;
  final Map<String, Answer> _selectedAnswers = {};
  final Map<String, String> _textFieldValues = {};
  ScoreResult? _result;
  final List<ScoreResult> _assessmentHistory = [];
  bool _isLoaded = false;

  // --- Getters ---

  List<QuestionCategory> get categories => healthCategories;
  int get currentCategoryIndex => _currentCategoryIndex;
  QuestionCategory get currentCategory =>
      healthCategories[_currentCategoryIndex];
  int get totalCategories => healthCategories.length;
  bool get isLoaded => _isLoaded;

  double get overallProgress {
    int totalScored = 0;
    int answeredScored = 0;
    for (final category in healthCategories) {
      for (final question in category.scoredQuestions) {
        totalScored++;
        if (_selectedAnswers.containsKey(question.id)) {
          answeredScored++;
        }
      }
    }
    if (totalScored == 0) return 0.0;
    return answeredScored / totalScored;
  }

  double categoryProgress(int index) {
    if (index < 0 || index >= healthCategories.length) return 0.0;
    final category = healthCategories[index];
    final scored = category.scoredQuestions;
    if (scored.isEmpty) return 0.0;
    int answered = 0;
    for (final question in scored) {
      if (_selectedAnswers.containsKey(question.id)) {
        answered++;
      }
    }
    return answered / scored.length;
  }

  bool isCategoryComplete(int index) {
    if (index < 0 || index >= healthCategories.length) return false;
    final category = healthCategories[index];
    final scored = category.scoredQuestions;
    if (scored.isEmpty) return true;
    for (final question in scored) {
      if (!_selectedAnswers.containsKey(question.id)) {
        return false;
      }
    }
    return true;
  }

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

  Answer? selectedAnswerFor(String questionId) =>
      _selectedAnswers[questionId];

  String? textFieldValueFor(String questionId) =>
      _textFieldValues[questionId];

  // --- Persistence ---

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
      } catch (_) {
        // Corrupt payload — start empty.
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  // --- Mutations ---

  void selectAnswer(String questionId, Answer answer) {
    _selectedAnswers[questionId] = answer;
    notifyListeners();
  }

  void setTextFieldValue(String questionId, String value) {
    _textFieldValues[questionId] = value;
    notifyListeners();
  }

  void nextCategory() {
    if (_currentCategoryIndex < healthCategories.length - 1) {
      _currentCategoryIndex++;
      notifyListeners();
    }
  }

  void previousCategory() {
    if (_currentCategoryIndex > 0) {
      _currentCategoryIndex--;
      notifyListeners();
    }
  }

  ScoreResult calculateResult() {
    int rawScore = 0;
    int maxPossible = 0;
    final Map<String, double> catScores = {};

    for (final category in healthCategories) {
      int catRaw = 0;
      int catMax = 0;

      for (final question in category.scoredQuestions) {
        catMax += question.maxScore;
        final answer = _selectedAnswers[question.id];
        if (answer != null) {
          catRaw += answer.score;
        }
      }

      rawScore += catRaw;
      maxPossible += catMax;

      if (catMax > 0) {
        catScores[category.name] = (catRaw / catMax) * 100;
      }
    }

    _result = ScoreResult.calculate(
      rawScore: rawScore,
      maxPossibleScore: maxPossible,
      categoryScores: catScores,
    );

    // Store in history (newest first, keep last 5)
    _assessmentHistory.insert(0, _result!);
    if (_assessmentHistory.length > maxHistory) {
      _assessmentHistory.removeLast();
    }

    _persist();
    notifyListeners();
    return _result!;
  }

  /// Reset the in-progress quiz (answers + index). The assessment history
  /// and last result are preserved so the dashboard/report keep showing
  /// prior scores.
  void reset() {
    _currentCategoryIndex = 0;
    _selectedAnswers.clear();
    _textFieldValues.clear();
    _result = null;
    notifyListeners();
  }

  /// Wipe both in-memory state and the persisted key. Called on sign-out.
  Future<void> resetAll() async {
    _currentCategoryIndex = 0;
    _selectedAnswers.clear();
    _textFieldValues.clear();
    _result = null;
    _assessmentHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        if (_result != null) 'result': _result!.toJson(),
        'history': _assessmentHistory.map((r) => r.toJson()).toList(),
      }),
    );
  }
}
