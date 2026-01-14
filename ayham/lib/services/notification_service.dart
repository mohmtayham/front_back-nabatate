import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabtatcompany/models/app_notification.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings ios =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings =
        InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
  }
Future<void> _saveNotification(AppNotification notification) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('notifications') ?? [];

  list.add(jsonEncode(notification.toJson()));
  await prefs.setStringList('notifications', list);
}

Future<void> removeNotification(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('notifications') ?? [];

  list.removeWhere((item) {
    final json = jsonDecode(item);
    return json['id'] == id;
  });

  await prefs.setStringList('notifications', list);
}

Future<List<AppNotification>> getAllNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('notifications') ?? [];

  return list
      .map((e) => AppNotification.fromJson(jsonDecode(e)))
      .toList();
}

  /// إشعار قبل 10 أيام من موعد الدفع
 Future<void> scheduleReminderNotification({
  required int id,
  required String title,
  required String body,
  required DateTime dueDate,
}) async {
  final now = DateTime.now();
  final daysLeft = dueDate.difference(now).inDays;

  // لو باقي أقل من 0 → انتهى
  if (daysLeft < 0) return;

  // لو باقي أقل من 10 أيام → إشعار الآن
  final notifyAt = daysLeft <= 10
      ? now.add(const Duration(seconds: 5)) // إشعار فوري للاختبار
      : dueDate.subtract(const Duration(days: 10));

  final scheduledDate = tz.TZDateTime.from(notifyAt, tz.local);

  await _plugin.zonedSchedule(
    id,
    title,
    body,
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'payment_reminders',
        'Payment Reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );



// ✅ SAVE LOCALLY
await _saveNotification(
  AppNotification(
    id: id,
    title: title,
    body: body,
    scheduledDate: notifyAt,
  ),
);}
  

Future<void> cancelNotification(int id) async {
  await _plugin.cancel(id);
  await removeNotification(id); // ✅ remove from list
}

}
