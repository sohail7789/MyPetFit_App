import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/analytics/models/assessment_cadence.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/reminders_provider.dart';
import 'package:mypetfit_app/services/reminder_gateway.dart';
import 'package:mypetfit_app/services/reminder_schedule.dart';
import 'package:mypetfit_app/services/reminder_scheduler.dart';

PetInfo _pet(String id, String name) => PetInfo(
      id: id,
      name: name,
      breed: 'Beagle',
      ageYears: 3,
      ageMonths: 0,
      gender: PetGender.male,
      weightKg: 12,
      heightCm: 40,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

ScoreResult _result(String petId, DateTime completedAt) => ScoreResult(
      rawScore: 70,
      maxPossibleScore: 100,
      percentageScore: 70,
      category: HealthCategory.good,
      completedAt: completedAt,
      petId: petId,
    );

/// Records what the scheduler asked the OS to do.
class _RecordingGateway implements ReminderGateway {
  final events = <String>[];
  final scheduled = <ScheduledReminder>[];
  bool grant = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    events.add('permission');
    return grant;
  }

  @override
  Future<void> cancelAll() async {
    events.add('cancelAll');
    scheduled.clear();
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async {
    events.add('schedule:${reminder.petName}');
    scheduled.add(reminder);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final now = DateTime(2026, 8, 17, 12);

  group('planning retake reminders', () {
    test('nothing is scheduled while the preference is off', () {
      // The requirement that matters most: a reminder nobody enabled must
      // not merely be hidden, it must not be planned either.
      final plan = planRetakeReminders(
        enabled: false,
        pets: [_pet('a', 'Bruno')],
        latestFor: (_) => _result('a', now.subtract(const Duration(days: 1))),
        now: now,
      );

      expect(plan, isEmpty);
    });

    test('a pet that has never been assessed is skipped', () {
      // No cadence to count from. The dashboard already invites a first
      // assessment, so there is nothing a notification would add.
      final plan = planRetakeReminders(
        enabled: true,
        pets: [_pet('a', 'Bruno')],
        latestFor: (_) => null,
        now: now,
      );

      expect(plan, isEmpty);
    });

    test('a reminder lands on the due date, mid-morning', () {
      final assessed = now.subtract(const Duration(days: 10));
      final plan = planRetakeReminders(
        enabled: true,
        pets: [_pet('a', 'Bruno')],
        latestFor: (_) => _result('a', assessed),
        now: now,
      );

      expect(plan, hasLength(1));

      final due = AssessmentCadence.standard.dueFrom(assessed, now: now)!;
      expect(plan.single.at.year, due.dueOn.year);
      expect(plan.single.at.month, due.dueOn.month);
      expect(plan.single.at.day, due.dueOn.day);
      expect(plan.single.at.hour, kReminderHour);
      expect(plan.single.petName, 'Bruno');
    });

    test('an assessment already due is left to the in-app banner', () {
      // The OS cannot deliver a past instant, and rounding one up to "now"
      // would fire the moment the toggle was switched on.
      final plan = planRetakeReminders(
        enabled: true,
        pets: [_pet('a', 'Bruno')],
        latestFor: (_) => _result('a', now.subtract(const Duration(days: 200))),
        now: now,
      );

      expect(plan, isEmpty);
    });

    test('each pet gets its own reminder on its own date', () {
      final pets = [_pet('a', 'Bruno'), _pet('b', 'Nala')];
      final assessedAt = {
        'a': now.subtract(const Duration(days: 10)),
        'b': now.subtract(const Duration(days: 40)),
      };

      final plan = planRetakeReminders(
        enabled: true,
        pets: pets,
        latestFor: (id) => _result(id, assessedAt[id]!),
        now: now,
      );

      expect(plan, hasLength(2));
      expect(plan.map((r) => r.petName), ['Bruno', 'Nala']);
      // Assessed thirty days apart, so due thirty days apart.
      expect(
        plan[1].at.difference(plan[0].at).inDays,
        -30,
      );
      // Distinct ids, or one would cancel the other with the OS.
      expect(plan[0].id, isNot(plan[1].id));
    });

    test('only pets with an assessment are counted', () {
      final plan = planRetakeReminders(
        enabled: true,
        pets: [_pet('a', 'Bruno'), _pet('b', 'Nala')],
        latestFor: (id) => id == 'a'
            ? _result(id, now.subtract(const Duration(days: 10)))
            : null,
        now: now,
      );

      expect(plan.map((r) => r.petName), ['Bruno']);
    });
  });

  group('the scheduler', () {
    ScheduledReminder reminder(String id, String name, int inDays) =>
        ScheduledReminder(
          petId: id,
          petName: name,
          at: now.add(Duration(days: inDays)),
        );

    test('replaces the pending set rather than adding to it', () async {
      final gateway = _RecordingGateway();
      final scheduler = ReminderScheduler(gateway);

      await scheduler.apply([reminder('a', 'Bruno', 30)]);
      await scheduler.apply([reminder('b', 'Nala', 40)]);

      // Every apply cancels first, so the same reminder can never be
      // registered twice.
      expect(
        gateway.events,
        ['cancelAll', 'schedule:Bruno', 'cancelAll', 'schedule:Nala'],
      );
      expect(gateway.scheduled.map((r) => r.petName), ['Nala']);
    });

    test('an empty plan cancels everything pending', () async {
      final gateway = _RecordingGateway();
      final scheduler = ReminderScheduler(gateway);

      await scheduler.apply([reminder('a', 'Bruno', 30)]);
      gateway.events.clear();

      // This is the disable path: switching the preference off has to reach
      // the OS, not just the UI.
      await scheduler.apply(const []);

      expect(gateway.events, ['cancelAll']);
      expect(gateway.scheduled, isEmpty);
    });

    test('an unchanged plan is not re-registered', () async {
      // Pets and quiz notify on every edit, sync and selection change. Each
      // of those would otherwise be a full cancel-and-reschedule.
      final gateway = _RecordingGateway();
      final scheduler = ReminderScheduler(gateway);

      await scheduler.apply([reminder('a', 'Bruno', 30)]);
      gateway.events.clear();

      await scheduler.apply([reminder('a', 'Bruno', 30)]);

      expect(gateway.events, isEmpty);
    });

    test('a changed date is re-registered', () async {
      final gateway = _RecordingGateway();
      final scheduler = ReminderScheduler(gateway);

      await scheduler.apply([reminder('a', 'Bruno', 30)]);
      gateway.events.clear();

      await scheduler.apply([reminder('a', 'Bruno', 31)]);

      expect(gateway.events, ['cancelAll', 'schedule:Bruno']);
    });

    test('cancelAll forgets the memo so the next apply still runs', () async {
      final gateway = _RecordingGateway();
      final scheduler = ReminderScheduler(gateway);

      await scheduler.apply([reminder('a', 'Bruno', 30)]);
      await scheduler.cancelAll();
      gateway.events.clear();

      await scheduler.apply([reminder('a', 'Bruno', 30)]);

      expect(gateway.events, ['cancelAll', 'schedule:Bruno']);
    });
  });

  group('the preference', () {
    test('defaults to off', () async {
      final reminders = RemindersProvider();
      await reminders.init();

      // Nobody has opted in on a fresh install.
      expect(reminders.assessmentRetake, isFalse);
      expect(reminders.isLoaded, isTrue);
    });

    test('survives a restart', () async {
      // The reported defect: the toggles were widget state, so popping the
      // screen forgot them while the screen claimed they were saved.
      await RemindersProvider().setAssessmentRetake(true);

      final reloaded = RemindersProvider();
      await reloaded.init();

      expect(reloaded.assessmentRetake, isTrue);
    });

    test('turning it off survives a restart too', () async {
      await RemindersProvider().setAssessmentRetake(true);

      // Read the stored value back before changing it, the way the app does
      // — the provider is created once at startup and init()ed there.
      final second = RemindersProvider();
      await second.init();
      expect(second.assessmentRetake, isTrue);
      await second.setAssessmentRetake(false);

      final reloaded = RemindersProvider();
      await reloaded.init();

      expect(reloaded.assessmentRetake, isFalse);
    });

    test('notifies once per real change', () async {
      final reminders = RemindersProvider();
      await reminders.init();

      var notifications = 0;
      reminders.addListener(() => notifications++);

      await reminders.setAssessmentRetake(true);
      expect(notifications, 1);

      // Setting the value it already holds must not churn the store or
      // re-run the scheduler.
      await reminders.setAssessmentRetake(true);
      expect(notifications, 1);
    });

    test('reset clears it for the next account on the device', () async {
      final reminders = RemindersProvider();
      await reminders.setAssessmentRetake(true);

      await reminders.reset();
      expect(reminders.assessmentRetake, isFalse);

      final reloaded = RemindersProvider();
      await reloaded.init();
      expect(reloaded.assessmentRetake, isFalse);
    });
  });
}
