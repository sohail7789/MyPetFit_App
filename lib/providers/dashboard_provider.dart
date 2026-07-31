import 'package:flutter/material.dart';

enum PetMood { highEnergy, middle, lowEnergy }

class WeightPoint {
  final DateTime date;
  final double kg;
  const WeightPoint(this.date, this.kg);
}

class DashboardProvider extends ChangeNotifier {
  PetMood? _todayMood;
  PetMood? get todayMood => _todayMood;

  void setMood(PetMood mood) {
    _todayMood = mood;
    notifyListeners();
  }

  // Mock weight history — UI only. In a real app these come from a backend.
  final List<WeightPoint> _weightHistory = [
    WeightPoint(DateTime.now().subtract(const Duration(days: 30)), 12.4),
    WeightPoint(DateTime.now().subtract(const Duration(days: 25)), 12.6),
    WeightPoint(DateTime.now().subtract(const Duration(days: 20)), 12.8),
    WeightPoint(DateTime.now().subtract(const Duration(days: 15)), 12.7),
    WeightPoint(DateTime.now().subtract(const Duration(days: 10)), 13.0),
    WeightPoint(DateTime.now().subtract(const Duration(days: 5)), 13.1),
    WeightPoint(DateTime.now(), 13.2),
  ];

  List<WeightPoint> get weightHistory => List.unmodifiable(_weightHistory);

  // Lifestyle indicators 0..1
  double activityScore = 0.72;
  double nutritionScore = 0.65;
  double wellnessScore = 0.81;

  /// Seed indicators from a quiz result's category scores when available.
  void seedFromQuiz(Map<String, double>? categoryScores) {
    if (categoryScores == null || categoryScores.isEmpty) return;
    double avg(List<String> keys) {
      final values = <double>[];
      for (final k in keys) {
        for (final entry in categoryScores.entries) {
          if (entry.key.toLowerCase().contains(k)) {
            values.add(entry.value);
          }
        }
      }
      if (values.isEmpty) return 0.6;
      return (values.reduce((a, b) => a + b) / values.length) / 100.0;
    }

    activityScore = avg(['activity', 'fitness']);
    nutritionScore = avg(['nutrition', 'sleep', 'digestive']);
    wellnessScore = avg(['behavior', 'mental', 'physical', 'medical']);
    notifyListeners();
  }
}
