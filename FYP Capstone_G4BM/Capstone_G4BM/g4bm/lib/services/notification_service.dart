import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> checkPending() async {
    final List<PendingNotificationRequest> pending = await _notifications
        .pendingNotificationRequests();
    print("--- PENDING NOTIFICATIONS: ${pending.length} ---");
    for (var p in pending) {
      print("ID: ${p.id} | Title: ${p.title} | Body: ${p.body}");
    }
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,

          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications.initialize(settings);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Rules:
  /// 1. Standard Reminders: 1 hour before scheduled time.
  /// 2. Family Reminders: Every 6 hours leading up to the event.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool isFamilyReminder,
  }) async {
    if (isFamilyReminder) {
      // Rule: Every 6 hours leading up to the event
      // We schedule 4 repeat reminders (24, 18, 12, and 6 hours before)
      for (int i = 1; i <= 4; i++) {
        final triggerTime = scheduledTime.subtract(Duration(hours: 6 * i));
        if (triggerTime.isAfter(DateTime.now())) {
          await _schedule(id + i, "Family Update: $title", body, triggerTime);
        }
      }
    } else {
      // Rule: 1 hour before the time
      //final triggerTime = scheduledTime.subtract(const Duration(hours: 1));
      final triggerTime = DateTime.now().add(const Duration(seconds: 10));
      if (triggerTime.isAfter(DateTime.now())) {
        await _schedule(id, title, body, triggerTime);
      }
    }
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime time,
  ) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'g4bm_reminders',
          'G4BM Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
