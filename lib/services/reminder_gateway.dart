import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_schedule.dart';

/// The operating system's side of reminders.
///
/// An interface so [ReminderScheduler] can be driven in tests without a
/// platform: everything above this line is ordinary Dart, and everything
/// below it is a plugin call.
abstract class ReminderGateway {
  /// Prepares the plugin and the timezone database. Safe to call twice.
  Future<void> initialize();

  /// Asks for notification permission, returning whether it is granted.
  ///
  /// Called only when a user turns a reminder *on* — asking on launch, for a
  /// feature nobody has opted into, is how an app gets permanently denied.
  Future<bool> requestPermission();

  /// Drops every reminder this app has scheduled.
  Future<void> cancelAll();

  /// Schedules [reminder] with the OS.
  Future<void> schedule(ScheduledReminder reminder);
}

/// The real gateway, backed by `flutter_local_notifications`.
class LocalNotificationGateway implements ReminderGateway {
  LocalNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;

  /// The one channel the app posts to. Android requires a channel before a
  /// notification can be shown at all; naming it for what it carries is what
  /// lets a user silence retake reminders without silencing the app.
  static const _channel = AndroidNotificationChannel(
    'assessment_retake',
    'Assessment reminders',
    description:
        'Reminds you when a pet’s fitness assessment is due to be retaken.',
    importance: Importance.defaultImportance,
  );

  @override
  Future<void> initialize() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested when a reminder is switched on, not here.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();

    if (Platform.isIOS || Platform.isMacOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      // POST_NOTIFICATIONS, required from Android 13. Older versions have no
      // runtime permission and the plugin reports null, which is a grant.
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? true;
    }

    return false;
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async {
    await initialize();

    await _plugin.zonedSchedule(
      reminder.id,
      reminder.title,
      reminder.body,
      tz.TZDateTime.from(reminder.at, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Inexact deliberately. An exact alarm needs SCHEDULE_EXACT_ALARM on
      // Android 12+, which Play requires a justification for and which a
      // ninety-day wellness nudge plainly does not have: whether it arrives
      // at 09:00 or 09:40 changes nothing for the owner.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

/// A gateway that does nothing, for tests and for platforms with no
/// notification support compiled in.
class NoopReminderGateway implements ReminderGateway {
  const NoopReminderGateway();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> schedule(ScheduledReminder reminder) async {}
}

/// True on the platforms the reminder feature is built for.
///
/// Reminders are a phone feature here; the desktop and web targets exist for
/// development and would need their own permission story.
bool get remindersSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}
