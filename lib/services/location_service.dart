import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Stream untuk pembaruan lokasi
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  bool _isRunning = false;
  StreamSubscription<Position>? _positionSubscription;

  // Meminta izin lokasi
  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission geoPermission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      // Check for location permission
      geoPermission = await Geolocator.checkPermission();
      if (geoPermission == LocationPermission.denied) {
        geoPermission = await Geolocator.requestPermission();
        if (geoPermission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return false;
        }
      }

      if (geoPermission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        // Open app settings to let user enable location permission
        await openAppSettings();
        return false;
      }

      // For background location (Android 10+)
      if (geoPermission == LocationPermission.whileInUse) {
        // Request background permission
        await Permission.locationAlways.request();
        // We'll continue even if this fails as we at least have foreground permission
      }

      debugPrint('Location permissions granted: $geoPermission');
      return true;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  // Mulai tracking lokasi
  Future<bool> startLocationTracking({bool enableBackground = false}) async {
    if (_isRunning) return true;

    final permissionGranted = await requestLocationPermission();
    if (!permissionGranted) {
      debugPrint('Failed to start location tracking: Permission not granted');
      return false;
    }

    try {
      // Get last known location
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _locationController.add(lastPosition);
      }

      // Create location settings with background mode if requested
      LocationSettings locationSettings;

      if (enableBackground) {
        // Settings for Android
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "GeoBeep memantau lokasi Anda untuk alarm stasiun",
            notificationTitle: "GeoBeep Aktif",
            enableWakeLock: true,
          ),
          intervalDuration: const Duration(seconds: 10),
        );
      } else {
        // Regular settings
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        );
      }

      // Start location updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          _locationController.add(position);
          debugPrint(
            'Location update: ${position.latitude}, ${position.longitude}',
          );
        },
        onError: (e) {
          debugPrint('Error in location stream: $e');
        },
      );

      _isRunning = true;
      debugPrint(
        'Location tracking started successfully${enableBackground ? ' with background updates' : ''}',
      );
      return true;
    } catch (e) {
      debugPrint('Failed to start location tracking: $e');
      return false;
    }
  }

  // Stop tracking
  Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isRunning = false;
    debugPrint('Location tracking stopped');
  }

  // Dispose
  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}
