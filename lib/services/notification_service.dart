import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'alarm_service.dart';

// Global navigation key to access navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Define notification action IDs
  static const String stopAlarmActionId = 'stop_alarm';

  // Track the active station ID to disable when notification is tapped
  String? _activeAlarmStationId;
  void Function(String?)? _onAlarmStop;

  // Register callback for alarm stop
  void registerAlarmStopCallback(void Function(String?) callback) {
    _onAlarmStop = callback;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permission first
      final permissionGranted = await requestNotificationPermission();
      if (!permissionGranted) {
        print('Notification permission denied');
      }

      // Define notification details
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      // Initialize with notification tap callback
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Check if app was launched from notification
      final NotificationAppLaunchDetails? launchDetails =
          await _flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        if (launchDetails.notificationResponse?.payload != null) {
          _handlePayload(launchDetails.notificationResponse!.payload!);
        }
      }

      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Failed to initialize NotificationService: $e');
      _isInitialized = false;
    }
  }

  // Handle notification response
  void _handleNotificationResponse(NotificationResponse response) {
    print(
      'Notification response received: ${response.payload}, actionId: ${response.actionId}',
    );

    // Stop alarm regardless of which notification control was used
    if (response.payload != null) {
      _handlePayload(response.payload!);
    }
  }

  // Handle payload data
  void _handlePayload(String payload) {
    print('Processing notification payload: $payload');

    // Stop the sound immediately
    AlarmService.instance.stopAlarm();

    // Extract station ID if available
    String? stationId;
    if (payload.startsWith('station_')) {
      stationId = payload.substring(8); // Remove "station_" prefix
    } else if (_activeAlarmStationId != null) {
      stationId = _activeAlarmStationId;
    }

    // Notify listeners about alarm stop
    if (_onAlarmStop != null) {
      _onAlarmStop!(stationId);
    }

    // Cancel all notifications
    cancelAllNotifications();
  }

  Future<void> showAlarmNotification(
    String title,
    String body, {
    String? stationId,
  }) async {
    await initialize();

    if (!_isInitialized) {
      print('Cannot show notification: Service not initialized');
      HapticFeedback.vibrate();
      return;
    }

    // Store the station ID for the active alarm
    _activeAlarmStationId = stationId;

    try {
      // Create a simple notification that can be tapped to stop the alarm
      final androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Station Alarms',
        channelDescription: 'Notifications for station proximity alarms',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        ongoing: true,
        autoCancel: false,
        category: AndroidNotificationCategory.alarm,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);
      final payload = stationId != null ? 'station_$stationId' : 'stop_alarm';

      await _flutterLocalNotificationsPlugin.show(
        1, // Use fixed ID so it's easy to cancel later
        title,
        '$body\n\nTap to stop alarm',
        notificationDetails,
        payload: payload,
      );

      print('Alarm notification displayed with payload: $payload');
    } catch (e) {
      print('Error showing notification: $e');
      HapticFeedback.vibrate();
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _activeAlarmStationId = null;
  }
}
