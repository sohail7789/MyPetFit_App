import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';

import 'support/fake_cloud.dart';

/// Sprint 4, P1-1 — a cloud restore must not delete what the cloud has not
/// got yet.
///
/// `loadAssessmentsFromFirestore` replaced the whole history with the cloud's
/// contents. The cloud is authoritative for what it holds, but it does not
/// hold everything: `calculateResult` stores a report locally and *queues*
/// the write, and that queue lives in memory. A report finished offline
/// therefore exists nowhere but the local list until the write lands — and a
/// restore deleted precisely those records, then persisted the loss.
///
/// The same applied to a pet whose own document had not synced: the cloud
/// read keys on the pet documents it knows about, so an unsynced pet
/// contributed nothing and took its reports down with it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final epoch = DateTime.utc(2026, 6, 1, 9);

  ScoreResult report(
    int percent, {
    required String petId,
    required int minutesAgo,
    HealthCategory band = HealthCategory.good,
  }) =>
      ScoreResult(
        rawScore: percent,
        maxPossibleScore: 100,
        percentageScore: percent,
        category: band,
        categoryScores: const {'Skin & Coat': 55},
        completedAt: epoch.subtract(Duration(minutes: minutesAgo)),
        petId: petId,
      );

  /// A provider whose local history was restored from disk, exactly as a
  /// cold launch produces it.
  Future<QuizProvider> withLocalHistory(
    List<ScoreResult> local, {
    FakeCloud? cloud,
    String bindTo = 'p1',
  }) async {
    SharedPreferences.setMockInitialValues({
      'quiz_state': _persisted(local),
    });

    final quiz = QuizProvider(service: cloud ?? FakeCloud());
    await quiz.init();
    quiz.bindPet(bindTo);

    expect(
      quiz.historyFor(bindTo),
      isNotEmpty,
      reason: 'the fixture never reached the provider',
    );
    return quiz;
  }

  List<String> identities(Iterable<ScoreResult> records) => [
        for (final r in records)
          '${r.petId}@${r.completedAt.toUtc().toIso8601String()}',
      ];

  group('a failing cloud read', () {
    test('leaves the local history exactly as it was', () async {
      final local = [
        report(70, petId: 'p1', minutesAgo: 0),
        report(60, petId: 'p1', minutesAgo: 60),
      ];
      final quiz = await withLocalHistory(
        local,
        cloud: FakeCloud(offline: Exception('network unavailable')),
      );

      await expectLater(
        quiz.loadAssessmentsFromFirestore(),
        throwsA(isA<Exception>()),
      );

      // The exact records, not merely "some history".
      expect(identities(quiz.historyFor('p1')), identities(local));
      expect(quiz.historyFor('p1').map((r) => r.percentageScore), [70, 60]);
    });

    test('does not write the loss to disk', () async {
      final quiz = await withLocalHistory(
        [report(70, petId: 'p1', minutesAgo: 0)],
        cloud: FakeCloud(offline: Exception('network unavailable')),
      );

      await expectLater(
        quiz.loadAssessmentsFromFirestore(),
        throwsA(isA<Exception>()),
      );

      // A fresh provider reading the same disk still finds the report.
      final reopened = QuizProvider(service: FakeCloud());
      await reopened.init();
      reopened.bindPet('p1');

      expect(reopened.historyFor('p1'), hasLength(1));
    });
  });

  group('an empty cloud response', () {
    test('removes nothing', () async {
      // The contract could not tell "this account genuinely has no reports"
      // from "the cloud does not know about them yet" — an unsynced pet
      // produces an empty map either way. The safe reading is the only one
      // that cannot destroy a record: nothing in the cloud removes nothing
      // from here.
      final local = [
        report(70, petId: 'p1', minutesAgo: 0),
        report(60, petId: 'p1', minutesAgo: 60),
      ];
      final quiz = await withLocalHistory(local, cloud: FakeCloud());

      await quiz.loadAssessmentsFromFirestore();

      expect(identities(quiz.historyFor('p1')), identities(local));
    });

    test('a pet the cloud has never seen keeps its reports', () async {
      // getAllAssessments keys on the pet documents the cloud holds, so a pet
      // whose own document has not synced contributes nothing at all.
      final local = [report(66, petId: 'p-unsynced', minutesAgo: 5)];
      final quiz = await withLocalHistory(
        local,
        cloud: FakeCloud(assessments: {'p1': [report(70, petId: 'p1', minutesAgo: 0)]}),
        bindTo: 'p-unsynced',
      );

      await quiz.loadAssessmentsFromFirestore();

      expect(quiz.historyFor('p-unsynced'), hasLength(1));
      expect(quiz.historyFor('p1'), hasLength(1));
    });
  });

  group('a successful cloud read', () {
    test('brings down records this device did not have', () async {
      final quiz = await withLocalHistory(
        [report(70, petId: 'p1', minutesAgo: 0)],
        cloud: FakeCloud(assessments: {
          'p1': [
            report(70, petId: 'p1', minutesAgo: 0),
            report(55, petId: 'p1', minutesAgo: 120),
          ],
        }),
      );

      await quiz.loadAssessmentsFromFirestore();

      expect(quiz.historyFor('p1').map((r) => r.percentageScore), [70, 55]);
    });

    test('does not duplicate a record both sides hold', () async {
      final shared = report(70, petId: 'p1', minutesAgo: 0);

      final quiz = await withLocalHistory(
        [shared],
        cloud: FakeCloud(assessments: {'p1': [shared]}),
      );

      await quiz.loadAssessmentsFromFirestore();

      expect(quiz.historyFor('p1'), hasLength(1));
    });

    test('keeps a local record the cloud has not got', () async {
      // The offline assessment: scored on the device, its queued write never
      // landed, and the queue does not survive a restart.
      final unsynced = report(81, petId: 'p1', minutesAgo: 1);

      final quiz = await withLocalHistory(
        [unsynced, report(60, petId: 'p1', minutesAgo: 240)],
        cloud: FakeCloud(assessments: {
          'p1': [report(60, petId: 'p1', minutesAgo: 240)],
        }),
      );

      await quiz.loadAssessmentsFromFirestore();

      expect(
        quiz.historyFor('p1').map((r) => r.percentageScore),
        [81, 60],
        reason: 'the unsynced assessment was destroyed by the restore',
      );
    });

    test('returns records newest first, deterministically', () async {
      final quiz = await withLocalHistory(
        [report(60, petId: 'p1', minutesAgo: 240)],
        cloud: FakeCloud(assessments: {
          'p1': [
            report(55, petId: 'p1', minutesAgo: 480),
            report(90, petId: 'p1', minutesAgo: 10),
            report(70, petId: 'p1', minutesAgo: 120),
          ],
        }),
      );

      await quiz.loadAssessmentsFromFirestore();
      final first = quiz.historyFor('p1').map((r) => r.percentageScore).toList();

      // Same inputs, same order, twice.
      await quiz.loadAssessmentsFromFirestore();

      expect(first, [90, 70, 60, 55]);
      expect(quiz.historyFor('p1').map((r) => r.percentageScore), first);
    });
  });

  group('multiple pets', () {
    test('one pet\'s restore never touches another\'s records', () async {
      final quiz = await withLocalHistory(
        [
          report(70, petId: 'p1', minutesAgo: 0),
          report(40, petId: 'p2', minutesAgo: 30),
        ],
        cloud: FakeCloud(assessments: {
          'p1': [report(70, petId: 'p1', minutesAgo: 0)],
        }),
      );

      await quiz.loadAssessmentsFromFirestore();

      expect(quiz.historyFor('p1').map((r) => r.percentageScore), [70]);
      expect(
        quiz.historyFor('p2').map((r) => r.percentageScore),
        [40],
        reason: "the other pet's history was collateral damage",
      );
    });

    test('switching the active pet still isolates the record', () async {
      final quiz = await withLocalHistory(
        [
          report(70, petId: 'p1', minutesAgo: 0),
          report(40, petId: 'p2', minutesAgo: 30),
        ],
        cloud: FakeCloud(assessments: {
          'p1': [report(70, petId: 'p1', minutesAgo: 0)],
          'p2': [report(40, petId: 'p2', minutesAgo: 30)],
        }),
      );

      await quiz.loadAssessmentsFromFirestore();

      quiz.bindPet('p2');
      expect(quiz.assessmentHistory.map((r) => r.percentageScore), [40]);

      quiz.bindPet('p1');
      expect(quiz.assessmentHistory.map((r) => r.percentageScore), [70]);
    });
  });

  group('a restore after a failure', () {
    test('recovers without duplicating anything', () async {
      final unsynced = report(81, petId: 'p1', minutesAgo: 1);
      final cloud = FakeCloud(offline: Exception('network unavailable'));

      final quiz = await withLocalHistory([unsynced], cloud: cloud);

      await expectLater(
        quiz.loadAssessmentsFromFirestore(),
        throwsA(isA<Exception>()),
      );
      expect(quiz.historyFor('p1'), hasLength(1));

      // The connection returns, and the queued write has since landed.
      cloud.offline = null;
      cloud.assessments = {
        'p1': [unsynced, report(60, petId: 'p1', minutesAgo: 240)],
      };

      await quiz.loadAssessmentsFromFirestore();

      expect(quiz.historyFor('p1').map((r) => r.percentageScore), [81, 60]);
    });
  });

  group('retention is untouched', () {
    test('scoring still trims to maxHistory per pet', () async {
      // The policy applies where it always has — at scoring time. This is
      // here so a change to the restore path cannot quietly move it.
      final quiz = await withLocalHistory(
        [
          for (var i = 0; i < QuizProvider.maxHistory; i++)
            report(50 + i, petId: 'p1', minutesAgo: (i + 1) * 60),
        ],
      );

      expect(quiz.historyFor('p1'), hasLength(QuizProvider.maxHistory));

      await quiz.calculateResult();

      expect(
        quiz.historyFor('p1'),
        hasLength(QuizProvider.maxHistory),
        reason: 'the retention cap moved',
      );
    });

    test('a restore does not trim, exactly as before', () async {
      // The cloud is never trimmed, and this method has never trimmed either.
      // Adding a trim here would hide records it had just fetched — a
      // retention change dressed up as a safety fix.
      final quiz = await withLocalHistory(
        [report(70, petId: 'p1', minutesAgo: 0)],
        cloud: FakeCloud(assessments: {
          'p1': [
            for (var i = 0; i < QuizProvider.maxHistory + 3; i++)
              report(40 + i, petId: 'p1', minutesAgo: (i + 2) * 60),
          ],
        }),
      );

      await quiz.loadAssessmentsFromFirestore();

      expect(
        quiz.historyFor('p1').length,
        QuizProvider.maxHistory + 4,
        reason: 'the restore started trimming, which it never did',
      );
    });
  });

  group('historical integrity', () {
    test('restored records keep their stored values verbatim', () async {
      final stored = ScoreResult(
        rawScore: 12,
        maxPossibleScore: 100,
        // Deliberately disagreeing with rawScore: a recalculation anywhere
        // in this path would show a different number.
        percentageScore: 73,
        category: HealthCategory.critical,
        categoryScores: const {'Skin & Coat': 41.5},
        completedAt: epoch.subtract(const Duration(minutes: 90)),
        petId: 'p1',
      );

      final quiz = await withLocalHistory(
        [report(70, petId: 'p1', minutesAgo: 0)],
        cloud: FakeCloud(assessments: {'p1': [stored]}),
      );

      await quiz.loadAssessmentsFromFirestore();

      final restored =
          quiz.historyFor('p1').firstWhere((r) => r.percentageScore == 73);

      expect(restored.category, HealthCategory.critical);
      expect(restored.rawScore, 12);
      expect(restored.categoryScores['Skin & Coat'], 41.5);
      expect(restored.completedAt, stored.completedAt);
    });
  });
}

/// The persisted payload a cold launch reads, in the provider's own format.
String _persisted(List<ScoreResult> history) {
  final encoded = history.map((r) => r.toJson()).toList();
  return '{"history":${_json(encoded)},"drafts":{}}';
}

String _json(Object? value) {
  if (value is Map) {
    return '{${value.entries.map((e) => '${_json(e.key)}:${_json(e.value)}').join(',')}}';
  }
  if (value is List) return '[${value.map(_json).join(',')}]';
  if (value is String) return '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  return '$value';
}
