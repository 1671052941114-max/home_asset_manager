import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'warranty_notifications';
  static const String _channelName = 'แจ้งเตือนการรับประกัน';
  static const String _channelDescription =
      'แจ้งเตือนเมื่อการรับประกันทรัพย์สินใกล้หมดอายุ';

  Future<void> initialize() async {
    // Web ไม่ใช้ระบบ Local Notification
    if (kIsWeb) {
      return;
    }

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const windowsSettings = WindowsInitializationSettings(
      appName: 'Home Asset Manager',
      appUserModelId: 'com.homeassetmanager.app',
      guid: '7f3d9b8e-6c1a-4d52-9a71-2e8f5c4b6d10',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> showTestNotification() async {
    if (kIsWeb) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.windows) {
      const details = NotificationDetails(
        windows: WindowsNotificationDetails(),
      );

      await _plugin.show(
        id: 999999,
        title: 'Home Asset Manager',
        body: 'ระบบแจ้งเตือนทำงานเรียบร้อยแล้ว',
        notificationDetails: details,
      );

      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: 999999,
      title: 'Home Asset Manager',
      body: 'ระบบแจ้งเตือนทำงานเรียบร้อยแล้ว',
      notificationDetails: details,
    );
  }

  Future<void> scheduleWarrantyNotification({
    required int assetId,
    required String assetName,
    required DateTime warrantyEndDate,
    required int daysBefore,
  }) async {
    // Web ไม่รองรับระบบนี้
    if (kIsWeb) {
      return;
    }

    // Windows ยังไม่รองรับ scheduled notifications
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }

    final notificationDate = DateTime(
      warrantyEndDate.year,
      warrantyEndDate.month,
      warrantyEndDate.day,
    ).subtract(
      Duration(days: daysBefore),
    );

    final scheduledDate = tz.TZDateTime(
      tz.local,
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      9,
      0,
    );

    if (!scheduledDate.isAfter(
      tz.TZDateTime.now(tz.local),
    )) {
      return;
    }

    final notificationId = _notificationId(
      assetId,
      daysBefore,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'ประกันใกล้หมด',
      body: '$assetName เหลือประกันอีก $daysBefore วัน',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'asset:$assetId',
    );
  }

  Future<void> scheduleWarrantyNotifications({
    required int assetId,
    required String assetName,
    required DateTime warrantyEndDate,
  }) async {
    if (kIsWeb) {
      return;
    }

    await cancelWarrantyNotifications(assetId);

    for (final daysBefore in [30, 14, 7]) {
      await scheduleWarrantyNotification(
        assetId: assetId,
        assetName: assetName,
        warrantyEndDate: warrantyEndDate,
        daysBefore: daysBefore,
      );
    }
  }

  Future<void> cancelWarrantyNotifications(int assetId) async {
    if (kIsWeb) {
      return;
    }

    for (final daysBefore in [30, 14, 7]) {
      await _plugin.cancel(
        id: _notificationId(
          assetId,
          daysBefore,
        ),
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      return;
    }

    await _plugin.cancelAll();
  }

  int _notificationId(
    int assetId,
    int daysBefore,
  ) {
    return (assetId * 100) + daysBefore;
  }
}