import 'package:flutter/material.dart';
import '../config/constants.dart';

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

  Color get color => switch (this) {
        critical => const Color(0xFFE53935),
        needsImprovement => const Color(0xFFFF6B35),
        good => const Color(0xFF66BB6A),
        excellent => const Color(0xFF42A5F5),
      };

  IconData get icon => switch (this) {
        critical => Icons.warning_rounded,
        needsImprovement => Icons.info_rounded,
        good => Icons.thumb_up_rounded,
        excellent => Icons.star_rounded,
      };

  String get emoji => switch (this) {
        critical => '\u{1F6A8}',
        needsImprovement => '\u{26A1}',
        good => '\u{1F44D}',
        excellent => '\u{1F451}',
      };

  String get summary => switch (this) {
        critical =>
          'Your pet needs immediate attention. Several health indicators are concerning and we strongly recommend consulting a veterinarian. The products below can help support your pet\'s recovery.',
        needsImprovement =>
          'There are areas where your pet\'s health could be improved. With some adjustments to diet, exercise, and care routines, your pet can thrive. Check out our recommended products to help.',
        good =>
          'Your pet is doing well! There\'s still room for improvement in a few areas. Our recommended products can help take your pet\'s health to the next level.',
        excellent =>
          'Great job! Your pet is thriving and in excellent health. Keep up the amazing work! Browse our premium products to maintain this level of wellness.',
      };
}

class ScoreResult {
  final int rawScore;
  final int maxPossibleScore;
  final int percentageScore;
  final HealthCategory category;
  final Map<String, double> categoryScores;
  final DateTime completedAt;

  const ScoreResult({
    required this.rawScore,
    required this.maxPossibleScore,
    required this.percentageScore,
    required this.category,
    this.categoryScores = const {},
    required this.completedAt,
  });

  factory ScoreResult.calculate({
    required int rawScore,
    required int maxPossibleScore,
    Map<String, double> categoryScores = const {},
  }) {
    final percentage = ((rawScore - AppConstants.minPossibleScore) /
            (AppConstants.maxPossibleScore - AppConstants.minPossibleScore) *
            100)
        .round()
        .clamp(0, 100);
    return ScoreResult(
      rawScore: rawScore,
      maxPossibleScore: maxPossibleScore,
      percentageScore: percentage,
      category: _categoryFromScore(percentage),
      categoryScores: categoryScores,
      completedAt: DateTime.now(),
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
      );
}
