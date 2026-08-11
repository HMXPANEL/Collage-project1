import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules / cancels the daily action reminder.
///
/// Implementation is a layer behind the plugin so tests can swap in a fake
/// and never touch platform channels.
abstract class ReminderScheduler {
  Future<void> scheduleDaily({
    required int hourOfDay,
    required int minute,
    required String title,
    required String body,
  });

  Future<void> cancelAll();
}

/// Real implementation backed by flutter_local_notifications.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Initializes the plugin and returns a ready scheduler.
  static Future<LocalReminderScheduler> create() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    return LocalReminderScheduler._(plugin);
  }

  @override
  Future<void> scheduleDaily({
    required int hourOfDay,
    required int minute,
    required String title,
    required String body,
  }) async {
    tzdata.initializeTimeZones();
    final localName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName));
    await _plugin.zonedSchedule(
      _reminderId,
      title,
      body,
      _nextInstanceOf(hourOfDay, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily action reminder',
          channelDescription: 'Ask you to log one small action each day',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancel(_reminderId);

  static const int _reminderId = 1;

  /// The next time [hourOfDay]:[minute] occurs in the local timezone.
  tz.TZDateTime _nextInstanceOf(int hourOfDay, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hourOfDay,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
