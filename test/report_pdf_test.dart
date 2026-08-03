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
      pet: const PetInfo(
        id: 'p1',
        name: 'Bruno',
        breed: 'Golden Retriever',
        ageYears: 3,
        ageMonths: 4,
        gender: PetGender.male,
        weightKg: 24,
        heightCm: 56,
      ),
      owner: const OwnerInfo(
        name: 'Sohail',
        contactNumber: '+91 90000 11111',
        email: 'owner@example.com',
        // The vet belongs to the owner, not a pet — one practice usually
        // covers the whole household.
        vetName: 'Dr Rao',
        vetContact: '+91 90000 00000',
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
}
