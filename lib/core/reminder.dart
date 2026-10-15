/// تذكير يومي محلي (من غير سيرفر) — ولي الأمر بيفعّله من لوحته ويختار الساعة.
/// إذن الإشعارات بيتطلب بس لما يتفعّل، مش أول ما التطبيق يفتح.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/progress/progress_controller.dart';

/// ساعة التذكير (الدقيقة من أول اليوم، ١٧:٣٠ = ١٠٥٠) أو null = مقفول. محفوظة للجهاز كله
/// مش لكل طفل — الإشعار واحد للجهاز.
class ReminderController extends Notifier<int?> {
  static const key = 'rehlati.reminder';

  @override
  int? build() => ref.read(sharedPrefsProvider).getInt(key);

  /// false = الإذن اترفض.
  Future<bool> set(int? minute, {required String greeting}) async {
    final prefs = ref.read(sharedPrefsProvider);
    if (minute == null) {
      await Reminder.cancel();
      await prefs.remove(key);
    } else {
      if (!await Reminder.schedule(minute, greeting: greeting)) return false;
      await prefs.setInt(key, minute);
    }
    state = minute;
    return true;
  }
}

final reminderProvider = NotifierProvider<ReminderController, int?>(ReminderController.new);

class Reminder {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _id = 1;

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (_) {
      // منطقة مش معروفة — UTC أحسن من إن التذكير مايشتغلش
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// بيطلب الإذن ويجدول التذكير كل يوم الساعة [minute] (من أول اليوم). false = الإذن اترفض.
  /// [greeting]: "يوسف" أو "أبطال" لو فيه أكتر من طفل.
  static Future<bool> schedule(int minute, {required String greeting}) async {
    try {
      await _init();
      final ok = defaultTargetPlatform == TargetPlatform.iOS
          ? await _plugin
                  .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true) ??
              false
          : await _plugin
                  .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                  ?.requestNotificationsPermission() ??
              false;
      if (!ok) return false;
      final now = tz.TZDateTime.now(tz.local);
      var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, minute ~/ 60, minute % 60);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _id,
        title: 'رحلتي 🦁',
        body: 'يلا يا $greeting! الأسد مستنيك في مغامرة النهاردة ⭐',
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('daily', 'التذكير اليومي',
              channelDescription: 'تذكير يومي بوقت التعلّم', importance: Importance.defaultImportance),
          iOS: DarwinNotificationDetails(),
        ),
        // مش محتاجين الدقيقة بالظبط — من غير إذن المنبّهات الدقيقة
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cancel() async {
    try {
      await _init();
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
