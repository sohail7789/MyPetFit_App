import 'questions_data.dart';

/// Orders a stored report's category scores the way the questionnaire asks
/// them.
///
/// A report's `categoryScores` is a `Map<String, double>`, and a map carries
/// whatever order it was built with. Locally that is questionnaire order and
/// survives the JSON round trip — but Firestore documents have no guaranteed
/// field order, so the same report restored from the cloud can come back
/// arranged differently. Rendering straight from the map therefore let one
/// pet's report list its areas in one order on this phone and another order
/// on the next, which for a health record reads as a defect.
///
/// Canonical order is the questionnaire's own, so every surface — the report
/// screen, the PDF, and anything later — agrees without coordinating.
///
/// Deliberately pure Dart: a web dashboard or a server-side renderer needs
/// the same ordering and should not have to import Flutter for it.
List<MapEntry<String, double>> orderedCategoryScores(
  Map<String, double> scores,
) {
  if (scores.isEmpty) return const [];

  final remaining = Map<String, double>.from(scores);
  final ordered = <MapEntry<String, double>>[];

  for (final category in healthCategories) {
    final score = remaining.remove(category.name);
    if (score != null) ordered.add(MapEntry(category.name, score));
  }

  // Anything the questionnaire no longer defines — an area renamed or
  // retired since the report was filed — is kept, not dropped. A historical
  // report is an immutable record, and silently losing a row from an old one
  // would be a worse bug than showing it out of sequence.
  //
  // Sorted by name rather than left in map order: the stored order is
  // precisely what cannot be trusted here, so leaving these to it would
  // reintroduce the problem for exactly the rows least likely to be noticed.
  final unknown = remaining.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return [...ordered, ...unknown];
}
