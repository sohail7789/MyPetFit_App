import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/questions_data.dart';
import '../models/question.dart';
import '../models/score_result.dart';

/// One pet's in-progress assessment.
///
/// Answers are held per pet for the same reason results are: switching pets
/// mid-questionnaire used to carry the part-finished answers across, so the
/// other pet's resume card offered progress that was never theirs.
class _QuizDraft {
  _QuizDraft();

  int categoryIndex = 0;
  final Map<String, Answer> answers = {};
  final Map<String, Set<String>> multi = {};
  final Map<String, String> texts = {};

  bool get isEmpty =>
      categoryIndex == 0 && answers.isEmpty && multi.isEmpty && texts.isEmpty;

  Map<String, dynamic> toJson() => {
        'categoryIndex': categoryIndex,
        'answers': answers.map((k, v) => MapEntry(k, v.id)),
        'multi': multi.map((k, v) => MapEntry(k, v.toList())),
        'texts': texts,
      };

  /// Also parses the pre-per-pet payload, which carried these same keys at
  /// the top level of the saved state.
  factory _QuizDraft.fromJson(Map<String, dynamic> json) {
    final draft = _QuizDraft();

    draft.categoryIndex = (json['categoryIndex'] as num?)?.toInt().clamp(
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
            draft.answers[question.id] = option;
            break;
          }
        }
      }
    }

    final multi = json['multi'] as Map<String, dynamic>?;
    if (multi != null) {
      for (final entry in multi.entries) {
        final ids = (entry.value as List?)?.whereType<String>().toSet();
        if (ids != null && ids.isNotEmpty) draft.multi[entry.key] = ids;
      }
    }

    final texts = json['texts'] as Map<String, dynamic>?;
    texts?.forEach((k, v) {
      if (v is String) draft.texts[k] = v;
    });

    return draft;
  }
}

/// Holds assessment progress and computes the fitness index.
///
/// Scoring follows the design exactly: an unanswered scored question counts as
/// its *lowest* option rather than zero, and the overall percentage is
/// normalised between the worst and best achievable totals.
class QuizProvider extends ChangeNotifier {
  static const int maxHistory = 5;
  static const _key = 'quiz_state';

  /// In-progress answers, one draft per pet.
  final Map<String, _QuizDraft> _drafts = {};

  /// Key for progress recorded before any pet existed.
  static const String _noPet = '';

  _QuizDraft get _draft =>
      _drafts.putIfAbsent(_activePetId ?? _noPet, _QuizDraft.new);

  // The rest of the class reads progress through these, so scoping it per
  // pet did not have to touch every question-handling method.
  int get _currentCategoryIndex => _draft.categoryIndex;
  set _currentCategoryIndex(int value) => _draft.categoryIndex = value;
  Map<String, Answer> get _selectedAnswers => _draft.answers;

  /// Selected option ids for multi-select questions.
  Map<String, Set<String>> get _multiAnswers => _draft.multi;

  Map<String, String> get _textFieldValues => _draft.texts;

  /// Every completed assessment, newest first, across all pets. The public
  /// getters filter this down to the bound pet.
  final List<ScoreResult> _allHistory = [];

  /// Whose results the getters report. Set by [bindPet] from the active pet.
  String? _activePetId;

  /// Guards the one-time stamping of pre-per-pet records.
  bool _stampedLegacy = false;

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

  /// The bound pet's most recent result.
  ///
  /// Derived from history rather than held separately. The two used to be
  /// independent fields, which let them disagree — that is exactly how
  /// starting a retake managed to blank the current score while a perfectly
  /// good report sat in history.
  ScoreResult? get result =>
      assessmentHistory.isEmpty ? null : assessmentHistory.first;

  /// The bound pet's last [maxHistory] assessments, newest first.
  List<ScoreResult> get assessmentHistory => List.unmodifiable(
        _allHistory.where((r) => r.petId == _activePetId),
      );

  bool get hasCompletedAssessment => assessmentHistory.isNotEmpty;

  /// [petId]'s assessments, newest first, regardless of which pet is bound.
  ///
  /// The pet profile can show a pet that isn't the active one, so it cannot
  /// go through the bound getters without reporting another pet's score.
  List<ScoreResult> historyFor(String petId) =>
      List.unmodifiable(_allHistory.where((r) => r.petId == petId));

  /// [petId]'s most recent result, or null if they have never been assessed.
  ScoreResult? resultFor(String petId) {
    final theirs = historyFor(petId);
    return theirs.isEmpty ? null : theirs.first;
  }

  /// Points the getters at [petId]'s results.
  ///
  /// Wired to the active pet in `main.dart`. Records written before results
  /// were scoped carry no pet id; the first bind with a real pet claims them,
  /// so a single-pet user keeps their history rather than appearing to have
  /// never taken the assessment.
  void bindPet(String? petId) {
    final claimed = _claimLegacyFor(petId);
    if (_activePetId == petId && !claimed) return;
    _activePetId = petId;
    if (claimed) _persist();
    notifyListeners();
  }

  bool _claimLegacyFor(String? petId) {
    if (_stampedLegacy || petId == null) return false;
    _stampedLegacy = true;

    var changed = false;
    for (var i = 0; i < _allHistory.length; i++) {
      if (_allHistory[i].petId == null) {
        _allHistory[i] = _allHistory[i].copyWith(petId: petId);
        changed = true;
      }
    }

    // A part-finished assessment from before pets were tracked belongs to
    // the same pet as the history it sits beside.
    final orphan = _drafts.remove(_noPet);
    if (orphan != null && !orphan.isEmpty && !_drafts.containsKey(petId)) {
      _drafts[petId] = orphan;
      changed = true;
    }

    return changed;
  }

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

    final result = ScoreResult.calculate(
      rawScore: rawScore,
      minPossibleScore: assessmentMinScore,
      maxPossibleScore: assessmentMaxScore,
      categoryScores: catScores,
      petId: _activePetId,
    );

    _allHistory.insert(0, result);
    _trimHistoryFor(_activePetId);

    _persist();
    notifyListeners();
    return result;
  }

  /// Keeps [maxHistory] per pet rather than across the whole list, so a
  /// household with several pets doesn't push one pet's reports out by
  /// assessing another.
  void _trimHistoryFor(String? petId) {
    final theirs = _allHistory.where((r) => r.petId == petId).toList();
    if (theirs.length <= maxHistory) return;
    for (final stale in theirs.sublist(maxHistory)) {
      _allHistory.remove(stale);
    }
  }

  // --- Lifecycle -------------------------------------------------------

  /// Clears the in-progress assessment. History and the last result are kept
  /// so the dashboard and report still show prior scores.
  ///
  /// This is called when a retake *starts*, so it must not touch [_result].
  /// It used to null it, which meant beginning a retake wiped the current
  /// score before a replacement existed — abandon the quiz part-way and the
  /// dashboard fell back to "Not assessed yet" even though a perfectly good
  /// report was still sitting in history. [calculateResult] replaces the
  /// result on completion, which is the only point at which it should change.
  void reset() {
    _drafts.remove(_activePetId ?? _noPet);
    _persistProgress();
    notifyListeners();
  }

  /// Discards every result for [petId]. Called when a pet is removed, so a
  /// deleted pet's reports don't linger against an id nothing points at.
  void clearResultsFor(String petId) {
    final before = _allHistory.length;
    _allHistory.removeWhere((r) => r.petId == petId);
    final hadDraft = _drafts.remove(petId) != null;
    if (_allHistory.length == before && !hadDraft) return;
    _persist();
    notifyListeners();
  }

  /// Wipes both in-memory state and the persisted key. Called on sign-out.
  Future<void> resetAll() async {
    _drafts.clear();
    _allHistory.clear();
    _activePetId = null;
    _stampedLegacy = false;
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

        final historyJson = json['history'] as List?;
        if (historyJson != null) {
          _allHistory.addAll(historyJson
              .map((e) => ScoreResult.fromJson(e as Map<String, dynamic>)));
        }

        // Older saves kept the newest result outside the history list. If it
        // somehow isn't in there, fold it in rather than dropping it.
        final resultJson = json['result'] as Map<String, dynamic>?;
        if (resultJson != null && _allHistory.isEmpty) {
          _allHistory.add(ScoreResult.fromJson(resultJson));
        }

        final draftsJson = json['drafts'] as Map<String, dynamic>?;
        if (draftsJson != null) {
          draftsJson.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              _drafts[key] = _QuizDraft.fromJson(value);
            }
          });
        } else {
          // Pre-per-pet payload: progress sat at the top level. The draft
          // parser reads those keys directly, and the first bind with a real
          // pet claims it — see [_claimLegacyFor].
          final legacy = _QuizDraft.fromJson(json);
          if (!legacy.isEmpty) _drafts[_noPet] = legacy;
        }
      } catch (_) {
        // Corrupt payload — start empty.
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Map<String, dynamic> _snapshot() => {
        'history': _allHistory.map((r) => r.toJson()).toList(),
        // Empty drafts are dropped rather than written as noise.
        'drafts': {
          for (final entry in _drafts.entries)
            if (!entry.value.isEmpty) entry.key: entry.value.toJson(),
        },
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
