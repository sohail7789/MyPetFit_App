import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/data/category_order.dart';
import 'package:mypetfit_app/data/questions_data.dart';

/// Canonical category ordering, shared by the report screen and the PDF.
///
/// The stored map's own order cannot be trusted: Firestore does not
/// guarantee document field order, so a report restored from the cloud can
/// come back arranged differently from the one written locally.
void main() {
  const skin = 'Skin & Coat Health';
  const activity = 'Activity & Fitness Level';
  const oral = 'Oral, Vision & Hearing';
  const sleep = 'Sleep & Nutrition';
  const medical = 'Medical & Lifestyle Tracking';

  /// The questionnaire's own scored order, which is the answer these tests
  /// are written against rather than a list copied by hand.
  final canonicalScored = <String>[
    for (final category in healthCategories)
      if (category.maxScore > 0) category.name,
  ];

  group('ordering', () {
    test('a scrambled map comes back in questionnaire order', () {
      // Exactly the shape a cloud-restored report can arrive in.
      final ordered = orderedCategoryScores(const {
        medical: 88,
        skin: 41,
        sleep: 92,
        activity: 66,
      });

      expect(ordered.map((e) => e.key), [skin, activity, sleep, medical]);
    });

    test('the order matches the questionnaire, not a hand-copied list', () {
      final everything = {
        for (final name in canonicalScored) name: 50.0,
      };

      // Reversed on the way in, so passing cannot be an accident of input.
      final scrambled = {
        for (final name in canonicalScored.reversed) name: 50.0,
      };

      expect(
        orderedCategoryScores(scrambled).map((e) => e.key),
        canonicalScored,
      );
      expect(
        orderedCategoryScores(everything).map((e) => e.key),
        canonicalScored,
      );
    });

    test('values travel with their categories', () {
      final ordered = orderedCategoryScores(const {
        sleep: 92,
        skin: 41,
      });

      expect(ordered.first.key, skin);
      expect(ordered.first.value, 41);
      expect(ordered.last.key, sleep);
      expect(ordered.last.value, 92);
    });

    test('a partial report keeps only what it recorded', () {
      final ordered = orderedCategoryScores(const {oral: 30, skin: 41});

      expect(ordered.map((e) => e.key), [skin, oral]);
      expect(ordered.length, 2);
    });

    test('an empty report orders into nothing', () {
      expect(orderedCategoryScores(const {}), isEmpty);
    });
  });

  group('categories the questionnaire no longer defines', () {
    test('are kept, not dropped', () {
      // A renamed or retired area in an old report. Losing the row would
      // silently rewrite an immutable record.
      final ordered = orderedCategoryScores(const {
        'Retired Wellness Area': 55,
        skin: 41,
      });

      expect(ordered.map((e) => e.key), [skin, 'Retired Wellness Area']);
      expect(ordered.last.value, 55);
    });

    test('are appended after everything the questionnaire knows', () {
      final ordered = orderedCategoryScores(const {
        'Some Old Area': 10,
        medical: 88,
        skin: 41,
      });

      expect(ordered.map((e) => e.key), [skin, medical, 'Some Old Area']);
    });

    test('order among themselves by name, not by however they were stored',
        () {
      // The stored order is precisely what cannot be trusted, so leaving
      // these to it would reintroduce the bug for the rows least likely to
      // be noticed.
      const forwards = {'Zeta Area': 1.0, 'Alpha Area': 2.0, 'Mid Area': 3.0};
      const backwards = {'Mid Area': 3.0, 'Alpha Area': 2.0, 'Zeta Area': 1.0};

      expect(
        orderedCategoryScores(forwards).map((e) => e.key),
        ['Alpha Area', 'Mid Area', 'Zeta Area'],
      );
      expect(
        orderedCategoryScores(backwards).map((e) => e.key),
        orderedCategoryScores(forwards).map((e) => e.key),
      );
    });

    test('a report of nothing but retired areas still renders in full', () {
      final ordered = orderedCategoryScores(const {
        'Old B': 20,
        'Old A': 10,
      });

      expect(ordered.map((e) => e.key), ['Old A', 'Old B']);
    });
  });

  group('nothing is lost or invented', () {
    test('every stored entry survives the ordering', () {
      const stored = {
        medical: 88.0,
        skin: 41.0,
        'Retired Area': 55.0,
        sleep: 92.0,
      };

      final ordered = orderedCategoryScores(stored);

      expect(ordered.length, stored.length);
      expect({for (final e in ordered) e.key: e.value}, stored);
    });

    test('the same map always orders the same way', () {
      const stored = {sleep: 92.0, skin: 41.0, 'Retired Area': 55.0};

      expect(
        orderedCategoryScores(stored).map((e) => e.key),
        orderedCategoryScores(stored).map((e) => e.key),
      );
    });
  });
}
