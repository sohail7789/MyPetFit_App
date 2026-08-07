import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../config/theme.dart';
import '../data/category_order.dart';
import '../models/pet_info.dart';
import '../models/score_band.dart';
import '../models/score_result.dart';

/// Builds the fitness report card as a PDF and hands it to the platform
/// share sheet or print dialog.
///
/// This is the artefact the owner takes to the vet, so it is laid out as a
/// document rather than a screenshot of the app: the score and band up top,
/// the full category breakdown in the order the app shows it, and the pet
/// and owner details needed to file it against a patient record.
///
/// [build] is the single source of the document. Sharing and printing both
/// go through it, so a mailed copy and a printed one can never differ.
class ReportPdf {
  ReportPdf._();

  /// Cached across calls — parsing the two faces costs ~30ms each time.
  static pw.Font? _regular;
  static pw.Font? _bold;

  static const _ink = PdfColor.fromInt(0xFF2A2C5A);
  static const _body = PdfColor.fromInt(0xFF6B6D8F);
  static const _muted = PdfColor.fromInt(0xFF8A8AA6);
  static const _action = PdfColor.fromInt(0xFF46437F);
  static const _rule = PdfColor.fromInt(0xFFE6E4EF);
  static const _track = PdfColor.fromInt(0xFFEFECF5);

  static Future<void> _loadFonts() async {
    if (_regular != null && _bold != null) return;
    _regular = pw.Font.ttf(
      await rootBundle.load('assets/pdf/Manrope-Regular.ttf'),
    );
    _bold = pw.Font.ttf(
      await rootBundle.load('assets/pdf/Manrope-ExtraBold.ttf'),
    );
  }

  /// Renders the report and returns the PDF bytes.
  /// [generatedAt] stamps the footer. Injectable so the document is
  /// reproducible in a test; production leaves it to the clock.
  static Future<List<int>> build({
    required ScoreResult result,
    PetInfo? pet,
    OwnerInfo? owner,
    DateTime? generatedAt,
  }) async {
    await _loadFonts();
    final stampedAt = generatedAt ?? DateTime.now();

    final doc = pw.Document(
      title: 'MyPetFit Fitness Report Card',
      author: 'MyPetFit',
    );

    final categories = categoriesForReport(result);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 32),
        theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // When the document was produced, which is not when the
              // assessment was taken — a vet handed a printout needs to know
              // both, and only the assessment date appears in the header.
              pw.Text(
                'MyPetFit · generated ${generationStamp(stampedAt)}',
                style: pw.TextStyle(fontSize: 8.5, color: _muted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8.5, color: _muted),
              ),
            ],
          ),
        ),
        build: (context) => [
          _header(result),
          pw.SizedBox(height: 14),
          _scoreBand(result),
          pw.SizedBox(height: 14),
          if (pet != null || owner != null) ...[
            _details(pet, owner),
            pw.SizedBox(height: 12),
          ],
          _sectionTitle('Category breakdown'),
          pw.SizedBox(height: 3),
          pw.Text(
            'Every scored area from this assessment, in the order the app '
            'shows them.',
            style: pw.TextStyle(fontSize: 10, color: _muted),
          ),
          pw.SizedBox(height: 8),
          for (final entry in categories)
            _categoryCard(entry.key, entry.value),
          pw.SizedBox(height: 10),
          _advice(result),
        ],
      ),
    );

    return doc.save();
  }

  /// Builds the PDF and hands it to the platform print dialog.
  ///
  /// Separate from [share] rather than folded into it: the share sheet is
  /// how a report reaches a vet over WhatsApp or mail, and printing is how
  /// it reaches a clinic file. Nothing about the document differs — the same
  /// [build] produces both, so a printed copy and a shared one can never
  /// disagree.
  ///
  /// Returns false when the user dismisses the dialog without printing, and
  /// on the platforms where printing is unavailable.
  static Future<bool> printDocument({
    required ScoreResult result,
    PetInfo? pet,
    OwnerInfo? owner,
  }) async {
    final bytes = await build(result: result, pet: pet, owner: owner);

    return Printing.layoutPdf(
      name: documentName(result: result, pet: pet),
      onLayout: (_) async => Uint8List.fromList(bytes),
    );
  }

  /// Whether this device can print at all.
  ///
  /// Android before API 19 and some desktop configurations cannot, and a
  /// print control that opens nothing is worse than one that is absent.
  static Future<bool> canPrint() => Printing.info().then((i) => i.canPrint);

  /// The document's filename, without extension.
  ///
  /// Shared by the share sheet and the print dialog so a report is filed
  /// under the same name however it leaves the app.
  @visibleForTesting
  static String documentName({required ScoreResult result, PetInfo? pet}) {
    final name = (pet?.name.trim().isNotEmpty ?? false)
        ? pet!.name.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        : 'pet';
    return 'MyPetFit-report-$name-${_isoDate(result.completedAt)}';
  }

  /// Builds the PDF, writes it to a temp file and opens the share sheet.
  ///
  /// [origin] positions the sheet on iPad, where a share sheet without a
  /// source rect throws.
  static Future<void> share({
    required ScoreResult result,
    PetInfo? pet,
    OwnerInfo? owner,
    Rect? origin,
  }) async {
    final bytes = await build(result: result, pet: pet, owner: owner);

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${documentName(result: result, pet: pet)}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);

    final subject = (pet?.name.trim().isNotEmpty ?? false)
        ? "${pet!.name.trim()}'s MyPetFit report card"
        : 'MyPetFit fitness report card';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: subject,
        text: '$subject — fitness score ${result.percentageScore}% '
            '(${result.category.label}).',
        sharePositionOrigin: origin,
      ),
    );
  }

  // -- Sections ---------------------------------------------------------

  static pw.Widget _header(ScoreResult result) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'MyPetFit',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _action,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Intelligent Care for Lifelong Pet Health',
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'FITNESS REPORT CARD',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              assessedStamp(result.completedAt),
              style: pw.TextStyle(fontSize: 10, color: _body),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _scoreBand(ScoreResult result) {
    final band = result.category;
    final accent = PdfColor.fromInt(band.bandColor(AppColors.light).toARGB32());

    return pw.Container(
      padding: const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(band.bandTint(AppColors.light).toARGB32()),
        border: pw.Border.all(color: PdfColor.fromInt(band.bandLine(AppColors.light).toARGB32())),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${result.percentageScore}%',
                style: pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                band.label.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Text(
              band.bandCopy,
              style: pw.TextStyle(fontSize: 11, color: _body, lineSpacing: 3),
            ),
          ),
        ],
      ),
    );
  }

  /// Pet on the left, owner and vet on the right. Two columns rather than one
  /// long list, so the whole report card lands on a single page a vet can
  /// print or glance at without scrolling.
  static pw.Widget _details(PetInfo? pet, OwnerInfo? owner) {
    final petRows = <List<String>>[
      if (pet != null) ...[
        ['Name', _orDash(pet.name)],
        ['Species / breed', '${pet.species.label} · ${_orDash(pet.breed)}'],
        ['Age', pet.ageDisplay],
        ['Sex', pet.gender == PetGender.male ? 'Male' : 'Female'],
        if (pet.weightKg > 0)
          ['Weight', '${pet.weightKg.toStringAsFixed(1)} kg'],
        if (pet.heightCm > 0)
          ['Height', '${pet.heightCm.toStringAsFixed(0)} cm'],
        if (pet.microchipNumber?.trim().isNotEmpty ?? false)
          ['Microchip', pet.microchipNumber!.trim()],
      ],
    ];

    final ownerRows = <List<String>>[
      if (owner != null) ...[
        ['Name', _orDash(owner.name)],
        ['Contact', _orDash(owner.contactNumber)],
        ['Email', _orDash(owner.email)],
      ],
      if (owner?.vetName?.trim().isNotEmpty ?? false)
        [
          'Veterinarian',
          [owner!.vetName!.trim(), owner.vetContact?.trim()]
              .where((v) => v != null && v.isNotEmpty)
              .join(' · '),
        ],
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _detailColumn('Pet', petRows)),
        pw.SizedBox(width: 24),
        pw.Expanded(child: _detailColumn('Owner', ownerRows)),
      ],
    );
  }

  static pw.Widget _detailColumn(String title, List<List<String>> rows) {
    if (rows.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        pw.SizedBox(height: 8),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1.4),
          },
          children: [
            for (final row in rows)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      row[0],
                      style: pw.TextStyle(fontSize: 9.5, color: _muted),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      row[1],
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// One category as a bordered card: name, percentage, band and bar.
  ///
  /// Mirrors the on-screen card so the printout and the app agree — a vet
  /// reading the PDF and an owner reading the phone should be looking at the
  /// same document.
  static pw.Widget _categoryCard(String name, double percent) {
    final clamped = percent.clamp(0, 100).toDouble();
    final accent =
        PdfColor.fromInt(categoryBarColor(AppColors.light, clamped).toARGB32());
    final band = bandForPercent(clamped);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 7),
      padding: const pw.EdgeInsets.fromLTRB(11, 9, 11, 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rule),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              // The band beside the figure, so a scanned column of cards
              // reads as words rather than as numbers needing a key.
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(
                    band.bandTint(AppColors.light).toARGB32(),
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  band.label,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(
                      band.bandColor(AppColors.light).toARGB32(),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '${clamped.round()}%',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          // Track with a flex-proportioned fill on top, mirroring the app's
          // breakdown bars. Expressed as flex weights out of 1000 because
          // the pdf widget set has no fractional sizing.
          _bar(clamped, accent),
        ],
      ),
    );
  }

  static pw.Widget _bar(double percent, PdfColor accent) {
    const height = 7.0;
    final radius = pw.BorderRadius.circular(4);
    // A visible sliver at 0% so an empty category still reads as a bar.
    final filled = (percent * 10).round().clamp(6, 1000);
    final rest = 1000 - filled;

    return pw.Stack(
      children: [
        pw.Container(
          height: height,
          width: double.infinity,
          decoration: pw.BoxDecoration(color: _track, borderRadius: radius),
        ),
        pw.Row(
          children: [
            pw.Expanded(
              flex: filled,
              child: pw.Container(
                height: height,
                decoration:
                    pw.BoxDecoration(color: accent, borderRadius: radius),
              ),
            ),
            if (rest > 0)
              pw.Expanded(flex: rest, child: pw.SizedBox(height: height)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _advice(ScoreResult result) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFCFBFD),
        border: pw.Border.all(color: _rule),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'What to do next',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            result.category.bandAdvice,
            style: pw.TextStyle(fontSize: 10.5, color: _body, lineSpacing: 3),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: _rule, height: 1),
          pw.SizedBox(height: 8),
          // Kept inside the card rather than as a trailing block: as its own
          // element it was the one thing pushing the report onto a second
          // page, and a disclaimer stranded on an otherwise blank page is
          // easy to miss.
          pw.Text(
            'This report is generated from an owner-completed questionnaire. '
            'It is a screening aid, not a veterinary diagnosis, and does not '
            'replace clinical examination or testing.',
            style: pw.TextStyle(fontSize: 8.5, color: _muted, lineSpacing: 2),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      );

  // -- Formatting -------------------------------------------------------

  static String _orDash(String? value) =>
      (value == null || value.trim().isEmpty) ? '—' : value.trim();

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _longDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  static String _isoDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// The report's categories in the order the document prints them.
  ///
  /// Questionnaire order, which is the same order the report screen renders
  /// — an owner pointing at a row on their phone and a vet reading the paper
  /// have to be looking at the same list. Reading the stored map directly
  /// gave that only by luck: Firestore does not guarantee field order, so a
  /// cloud-restored report could print in a different sequence than it
  /// displayed.
  @visibleForTesting
  static List<MapEntry<String, double>> categoriesForReport(
    ScoreResult result,
  ) =>
      orderedCategoryScores(result.categoryScores);

  /// When the assessment was completed, to the minute.
  @visibleForTesting
  static String assessedStamp(DateTime when) {
    final t = when.toLocal();
    return '${_longDate(t)} at ${_clock(t)}';
  }

  /// When the document was produced.
  @visibleForTesting
  static String generationStamp(DateTime when) {
    final t = when.toLocal();
    return '${_isoDate(t)} ${_clock(t)}';
  }

  static String _clock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:${_two(t.minute)} ${t.hour < 12 ? 'am' : 'pm'}';
  }
}
