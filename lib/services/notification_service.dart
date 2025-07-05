import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/services/circle_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final CircleService _circleService = CircleService();

  Future<void> initialize() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // Get FCM token
      final token = await _fcm.getToken();
      if (token != null) {
        await _circleService.updateFCMToken(token);
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        await _circleService.updateFCMToken(newToken);
      });

      // Initialize local notifications
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Configure notification channels for Android
      await _createNotificationChannels();

      // Handle messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Check if app was opened from a terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    }
  }

  Future<void> _createNotificationChannels() async {
    // Circle activity channel
    const circleChannel = AndroidNotificationChannel(
      'circle_activity',
      'Circle Activity',
      description: 'Notifications for circle activities',
      importance: Importance.high,
    );

    // Location check-in channel
    const locationChannel = AndroidNotificationChannel(
      'location_checkin',
      'Location Check-ins',
      description: 'Smart notifications for nearby places and check-ins',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Vibe achievements channel
    const achievementChannel = AndroidNotificationChannel(
      'vibe_achievements',
      'Vibe Achievements',
      description: 'Notifications for badges and milestones',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotifications != null) {
      await androidNotifications.createNotificationChannel(circleChannel);
      await androidNotifications.createNotificationChannel(locationChannel);
      await androidNotifications.createNotificationChannel(achievementChannel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'circle_activity',
            'Circle Activity',
            channelDescription: 'Notifications for circle activities',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data['circleId'],
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    
    if (data['type'] == 'circle_activity' && data['circleId'] != null) {
      // Navigate to circle detail screen
      // You'll need to implement navigation from your main app
      navigateToCircle(data['circleId']);
    }
  }

  // Send local notification for location-based check-ins
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'location_checkin',
    String channelName = 'Location Check-ins',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'location_checkin',
      'Location Check-ins',
      channelDescription: 'Smart notifications for nearby places and check-ins',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Send achievement notification
  Future<void> sendAchievementNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'vibe_achievements',
      'Vibe Achievements',
      channelDescription: 'Notifications for badges and milestones',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Enhanced notification tap handler
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final payload = response.payload!;
      
      if (payload.startsWith('checkin:')) {
        // Handle check-in notification
        final placeId = payload.substring(8);
        navigateToCheckIn(placeId);
      } else if (payload.startsWith('nearby:')) {
        // Handle nearby places notification
        navigateToNearbyPlaces();
      } else if (payload.startsWith('achievement:')) {
        // Handle achievement notification
        final achievementId = payload.substring(12);
        navigateToAchievements(achievementId);
      } else {
        // Legacy circle navigation
        navigateToCircle(payload);
      }
    }
  }

  // This should be implemented in your main app to handle navigation
  void Function(String circleId) navigateToCircle = (circleId) {
    print('Navigate to circle: $circleId');
  };

  void Function(String placeId) navigateToCheckIn = (placeId) {
    print('Navigate to check-in for place: $placeId');
  };

  void Function() navigateToNearbyPlaces = () {
    print('Navigate to nearby places');
  };

  void Function(String achievementId) navigateToAchievements = (achievementId) {
    print('Navigate to achievements: $achievementId');
  };
}