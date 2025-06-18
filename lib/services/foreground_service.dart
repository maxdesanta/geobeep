import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundService {
  static ForegroundService? _instance;
  static ForegroundService get instance => _instance ??= ForegroundService._();
  ForegroundService._();

  // Service instance
  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _isInitialized = false;

  // Status tracking
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notifications for the service
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Set up notification channel for Android with standard settings
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'geobeep_foreground',
      'GeoBeep Aplikasi Aktif',
      description:
          'Notifikasi yang menunjukkan bahwa aplikasi GeoBeep sedang berjalan',
      importance: Importance.high,
      enableVibration: false,
      playSound: false,
      showBadge: true,
      enableLights: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Configure service - standard settings, not ongoing/persistent
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false, // Tidak autostart service ketika app dibuka
        isForegroundMode: true,
        notificationChannelId: 'geobeep_foreground',
        initialNotificationTitle: 'GeoBeep Sedang Berjalan',
        initialNotificationContent: 'Aplikasi sedang aktif',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    _isInitialized = true;
    _isRunning = await _service.isRunning();
    debugPrint('ForegroundService initialized: running=${_isRunning}');
  }

  // iOS background handler - required but not used
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

  // Start service handler
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      // Set up as standard foreground service with notification
      service.setForegroundNotificationInfo(
        title: 'GeoBeep Sedang Berjalan',
        content: 'Aplikasi sedang aktif',
      );

      // Set as foreground service
      service.setAsForegroundService();
    }

    // Update notification periodically with current time
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        // Update notification text to show it's still running with current time
        service.setForegroundNotificationInfo(
          title: 'GeoBeep Sedang Berjalan',
          content:
              'Aplikasi sedang aktif (${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')})',
        );
      }

      // Send data to app UI if needed
      service.invoke('update', {
        'isRunning': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Initial data update
    service.invoke('update', {
      'isRunning': true,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Start the foreground service
  Future<bool> startService() async {
    await initialize();

    // Start service - no need to stop first since this is a standard notification
    final result = await _service.startService();
    _isRunning = result;
    debugPrint('ForegroundService start result: $result');
    return result;
  }

  // Stop the foreground service
  Future<bool> stopService() async {
    // Invoke returns void, so we can't use its result
    _service.invoke('stopService');

    // Wait a moment for the service to process the stop request
    await Future.delayed(const Duration(milliseconds: 200));
    _isRunning = await _service.isRunning();
    debugPrint('ForegroundService stopped, isRunning: $_isRunning');
    return !_isRunning;
  }
}
