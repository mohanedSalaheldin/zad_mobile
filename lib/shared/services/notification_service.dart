import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _downloadChannelId = 'zad_downloads';
  static const String _downloadChannelName = 'تنزيلات رفيق زاد';
  static const String _downloadChannelDesc =
      'إشعارات اكتمال تحميل المحاضرات والملفات';

  static const String _reminderChannelId = 'zad_reminders';
  static const String _reminderChannelName = 'تذكيرات المذاكرة الأسبوعية';
  static const String _reminderChannelDesc =
      'تنبيهات أسبوعية لجدول المحاضرات وتنزيل الدروس';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked with payload: ${details.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');

      // جدولة التنبيه الأسبوعي التذكيري
      await scheduleWeeklyReminder();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// إرسال تنبيه محلي فوري عند اكتمال تنزيل ملف
  Future<void> showDownloadCompletedNotification({
    required String title,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinDetails =
          DarwinNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final id = (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7fffffff;
      await _notificationsPlugin.show(
        id,
        'تم اكتمال التنزيل بنجاح',
        'تم تنزيل "$title" بنجاح، يمكنك قراءته ومتابعته الآن أوفلاين.',
        platformDetails,
      );
    } catch (e) {
      debugPrint('NotificationService showDownloadCompletedNotification error: $e');
    }
  }

  /// جدولة تنبيه تذكيري أسبوعي
  Future<void> scheduleWeeklyReminder() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinDetails =
          DarwinNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      const int reminderId = 999;

      await _notificationsPlugin.periodicallyShow(
        reminderId,
        'تذكير أسبوعي من رفيق زاد',
        'جدول الأسبوع الجديد متوفر، لا تنسَ تحميل محاضراتك للدراسة بدون إنترنت.',
        RepeatInterval.weekly,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('Weekly reminder scheduled successfully.');
    } catch (e) {
      debugPrint('NotificationService scheduleWeeklyReminder error: $e');
    }
  }
}
