import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/services/report_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ScoreResult resultWith({
    int percent = 42,
    Map<String, double> categories = const {
      'Skin & Coat Health': 25,
      'Activity & Fitness': 60,
      'Physical & Internal Health': 8,
    },
  }) =>
      ScoreResult(
        rawScore: 84,
        maxPossibleScore: 200,
        percentageScore: percent,
        category: ScoreResult.calculate(
          rawScore: percent,
          minPossibleScore: 0,
          maxPossibleScore: 100,
        ).category,
        categoryScores: categories,
        completedAt: DateTime(2026, 8, 2),
      );

  test('renders a non-empty PDF with pet and owner details', () async {
    final bytes = await ReportPdf.build(
      result: resultWith(),
      pet: PetInfo(
        id: 'p1',
        name: 'Bruno',
        breed: 'Golden Retriever',
        ageYears: 3,
        ageMonths: 4,
        gender: PetGender.male,
        weightKg: 24,
        heightCm: 56,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
      owner: OwnerInfo(
        name: 'Sohail',
        contactNumber: '+91 90000 11111',
        email: 'owner@example.com',
        // The vet belongs to the owner, not a pet — one practice usually
        // covers the whole household.
        vetName: 'Dr Rao',
        vetContact: '+91 90000 00000',
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    expect(bytes, isNotEmpty);
    // Every valid PDF opens with the %PDF- magic bytes.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('renders when the assessment has no pet or owner attached', () async {
    final bytes = await ReportPdf.build(result: resultWith());
    expect(bytes, isNotEmpty);
  });

  test('handles a 0% category without dividing by zero', () async {
    final bytes = await ReportPdf.build(
      result: resultWith(percent: 0, categories: const {'Sleep': 0}),
    );
    expect(bytes, isNotEmpty);
  });

  group('what the document prints', () {
    test('categories print in the same order the screen shows them', () {
      const stored = {
        'Sleep & Nutrition': 92.0,
        'Skin & Coat Health': 41.0,
        'Zeta area': 41.0,
        'Activity & Fitness': 66.0,
      };

      // The stored order, untouched — the report screen reads the same map
      // the same way, so the printout and the phone cannot disagree.
      expect(
        ReportPdf.categoriesForReport(resultWith(categories: stored))
            .map((e) => e.key),
        stored.keys,
      );
    });

    test('nothing is dropped or added on the way to the page', () {
      final stored = {for (var i = 0; i < 9; i++) 'Area $i': i * 10.0};
      final printed = ReportPdf.categoriesForReport(
        resultWith(categories: stored),
      );

      expect(printed.length, stored.length);
      expect(
        {for (final e in printed) e.key: e.value},
        stored,
      );
    });

    test('an assessment stamp carries the date and the time', () {
      expect(
        ReportPdf.assessedStamp(DateTime(2026, 2, 14, 14, 35)),
        '14 February 2026 at 2:35 pm',
      );
      expect(
        ReportPdf.assessedStamp(DateTime(2026, 2, 14, 0, 5)),
        '14 February 2026 at 12:05 am',
      );
    });

    test('the generation stamp sorts and reads unambiguously', () {
      expect(
        ReportPdf.generationStamp(DateTime(2026, 8, 8, 12, 0)),
        '2026-08-08 12:00 pm',
      );
      expect(
        ReportPdf.generationStamp(DateTime(2026, 8, 8, 23, 9)),
        '2026-08-08 11:09 pm',
      );
    });

    test('the stamps are independent of each other', () async {
      // A six-month-old report generated today must show both dates, not one
      // standing in for the other.
      final assessed = DateTime(2026, 2, 14, 9, 0);
      final generated = DateTime(2026, 8, 8, 17, 30);

      expect(ReportPdf.assessedStamp(assessed), contains('14 February 2026'));
      expect(ReportPdf.generationStamp(generated), contains('2026-08-08'));

      final bytes = await ReportPdf.build(
        result: resultWith().copyWith(petId: 'p1'),
        generatedAt: generated,
      );
      expect(bytes, isNotEmpty);
    });
  });

  group('the document builds for every shape of report', () {
    test('with no pet and no owner on file', () async {
      final bytes = await ReportPdf.build(result: resultWith());
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('with no category breakdown at all', () async {
      // Records written before categoryScores existed decode to an empty map.
      final bytes = await ReportPdf.build(
        result: resultWith(categories: const {}),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('at both ends of the scale', () async {
      for (final percent in [0, 100]) {
        final bytes = await ReportPdf.build(
          result: resultWith(
            percent: percent,
            categories: {'Skin & Coat Health': percent.toDouble()},
          ),
        );
        expect(bytes, isNotEmpty, reason: 'failed at $percent%');
      }
    });

    test('nine long-named categories still produce a document', () async {
      // The category cards add nesting, and pagination is where that would
      // show up first.
      final bytes = await ReportPdf.build(
        result: resultWith(
          categories: {
            for (var i = 0; i < 9; i++)
              'An Extremely Long Assessment Category Name Number $i':
                  (i * 11).toDouble(),
          },
        ),
        pet: PetInfo(
          id: 'p1',
          name: 'Bartholomew',
          breed: 'Rhodesian Ridgeback',
          ageYears: 4,
          ageMonths: 0,
          gender: PetGender.female,
          weightKg: 31.5,
          heightCm: 64,
          microchipNumber: '900123456789012',
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('printing shares the document with sharing', () {
    test('both paths file the report under the same name', () {
      final result = resultWith();
      final pet = PetInfo(
        id: 'p1',
        name: 'Bruno The Third',
        breed: 'Beagle',
        ageYears: 3,
        ageMonths: 0,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      // Punctuation and spaces are not filename material.
      expect(
        ReportPdf.documentName(result: result, pet: pet),
        'MyPetFit-report-Bruno-The-Third-2026-08-02',
      );
    });

    test('a report with no pet still gets a filename', () {
      expect(
        ReportPdf.documentName(result: resultWith()),
        'MyPetFit-report-pet-2026-08-02',
      );
    });

    test('the name is stamped with the assessment, not with today', () {
      // A six-month-old report printed today files under its own date.
      final old = ScoreResult(
        rawScore: 40,
        maxPossibleScore: 100,
        percentageScore: 40,
        category: HealthCategory.needsImprovement,
        completedAt: DateTime(2025, 12, 25),
      );
      expect(
        ReportPdf.documentName(result: old),
        endsWith('2025-12-25'),
      );
    });
  });
}