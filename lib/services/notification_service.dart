import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to expense screen
    // This will be handled by the app when it comes to foreground
  }

  Future<void> showPaymentAppNotification(String appName) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'payment_detection',
      'Payment App Detection',
      channelDescription: 'Notifications when payment apps are opened',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String title;
    String body;

    if (appName.contains('GPay') || appName.contains('Google Pay')) {
      title = '💸 Just paid via GPay?';
      body = 'Tap here to log your expense!';
    } else if (appName.contains('PhonePe')) {
      title = '📱 Just paid via PhonePe?';
      body = 'Tap here to log your expense!';
    } else {
      title = '💰 Just paid?';
      body = 'Tap here to log your expense!';
    }

    await _notifications.show(
      0,
      title,
      body,
      details,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
