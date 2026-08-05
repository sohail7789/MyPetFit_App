import '../config/constants.dart';

/// The band a score falls into.
///
/// Presentation lives in `score_band.dart`, not here: colours, tint, glyph,
/// artwork and copy all differ between light and dark, so they resolve
/// against an `AppColors` rather than being constants hanging off the enum.
/// This type stays a plain domain value with one label.
enum HealthCategory {
  critical,
  needsImprovement,
  good,
  excellent;

  String get label => switch (this) {
        critical => 'Critical',
        needsImprovement => 'Needs Improvement',
        good => 'Good',
        excellent => 'Excellent',
      };
}

class ScoreResult {
  final int rawScore;
  final int maxPossibleScore;
  final int percentageScore;
  final HealthCategory category;
  final Map<String, double> categoryScores;
  final DateTime completedAt;

  /// Which pet was assessed. Null on records written before results were
  /// scoped per pet — [QuizProvider] stamps those once on first load.
  final String? petId;

  const ScoreResult({
    required this.rawScore,
    required this.maxPossibleScore,
    required this.percentageScore,
    required this.category,
    this.categoryScores = const {},
    required this.completedAt,
    this.petId,
  });

  ScoreResult copyWith({String? petId}) => ScoreResult(
        rawScore: rawScore,
        maxPossibleScore: maxPossibleScore,
        percentageScore: percentageScore,
        category: category,
        categoryScores: categoryScores,
        completedAt: completedAt,
        petId: petId ?? this.petId,
      );

  factory ScoreResult.calculate({
    required int rawScore,
    required int minPossibleScore,
    required int maxPossibleScore,
    Map<String, double> categoryScores = const {},
    String? petId,
  }) {
    // Normalised the way the design does it: the floor is the score you get
    // by picking the worst option everywhere, not zero.
    final span = maxPossibleScore - minPossibleScore;
    final percentage = span <= 0
        ? 0
        : ((rawScore - minPossibleScore) / span * 100).round().clamp(0, 100);
    return ScoreResult(
      rawScore: rawScore,
      maxPossibleScore: maxPossibleScore,
      percentageScore: percentage,
      category: _categoryFromScore(percentage),
      categoryScores: categoryScores,
      completedAt: DateTime.now(),
      petId: petId,
    );
  }

  static HealthCategory _categoryFromScore(int score) {
    if (score <= AppConstants.criticalMax) return HealthCategory.critical;
    if (score <= AppConstants.needsImprovementMax) {
      return HealthCategory.needsImprovement;
    }
    if (score <= AppConstants.goodMax) return HealthCategory.good;
    return HealthCategory.excellent;
  }

  Map<String, dynamic> toJson() => {
        'rawScore': rawScore,
        'maxPossibleScore': maxPossibleScore,
        'percentageScore': percentageScore,
        'category': category.name,
        'categoryScores': categoryScores,
        'completedAt': completedAt.toIso8601String(),
        if (petId != null) 'petId': petId,
      };

  factory ScoreResult.fromJson(Map<String, dynamic> json) => ScoreResult(
        rawScore: (json['rawScore'] as num?)?.toInt() ?? 0,
        maxPossibleScore: (json['maxPossibleScore'] as num?)?.toInt() ?? 0,
        percentageScore: (json['percentageScore'] as num?)?.toInt() ?? 0,
        category: HealthCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => HealthCategory.good,
        ),
        categoryScores: (json['categoryScores'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
            const {},
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
            DateTime.now(),
        petId: json['petId'] as String?,
      );
}
