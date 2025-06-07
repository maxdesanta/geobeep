import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gobeap/models/station_model.dart';
import 'package:gobeap/models/alarm_history.dart';
import 'package:gobeap/services/location_service.dart';
import 'package:gobeap/services/alarm_service.dart';
import 'package:gobeap/services/notification_service.dart';
import 'package:gobeap/services/storage_service.dart';
import 'package:gobeap/data/stations_data.dart';

class StationProvider extends ChangeNotifier {
  List<StationModel> _allStations = [];
  List<StationModel> _favoriteStations = [];
  Map<String, double> _stationDistances = {};
  bool _isLoading = false;
  bool _isMonitoring = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _locationSubscription;
  List<AlarmHistory> _alarmHistory = [];

  // Getter yang diperlukan
  List<StationModel> get allStations {
    // Return a combined list of regular stations and the test station
    return _allStations;
  }

  List<StationModel> get favoriteStations => _favoriteStations;
  Map<String, double> get stationDistances => _stationDistances;
  bool get isLoading => _isLoading;
  bool get isMonitoring => _isMonitoring;
  Position? get currentPosition => _currentPosition;
  List<StationModel> get activeAlarms =>
      _allStations.where((s) => s.isAlarmActive).toList();
  List<AlarmHistory> get alarmHistory => _alarmHistory;

  // Stasiun uji
  StationModel? _testStation;
  StationModel? get testStation => _testStation;

  // Inisialisasi provider dan load data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allStations = StationsData.getAllStations();
      // Remove test station initialization

      await _loadSavedStationSettings();
      await _loadAlarmHistory();

      if (_currentPosition != null) {
        _updateDistances();
      }
    } catch (e) {
      print('Error initializing station provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load history alarm
  Future<void> _loadAlarmHistory() async {
    try {
      final historyData = await StorageService.instance.loadAlarmHistory();
      _alarmHistory =
          historyData.map((map) => AlarmHistory.fromMap(map)).toList();
    } catch (e) {
      print('Error loading alarm history: $e');
    }
  }

  // Mulai monitoring lokasi
  Future<bool> startMonitoring() async {
    if (_isMonitoring) return true;

    final locationService = LocationService();
    final started = await locationService.startLocationTracking();

    if (!started) {
      print('Failed to start location tracking');
      return false;
    }

    // Listen to location updates with immediate alarm checks
    _locationSubscription = locationService.locationStream.listen(
      (position) {
        _currentPosition = position;
        print('Location updated: ${position.latitude}, ${position.longitude}');

        // Update distances and check alarms immediately
        _updateDistances();
        _checkAlarms(position);

        notifyListeners();
      },
      onError: (error) {
        print('Error in location stream: $error');
        // Don't stop monitoring on error, just log it
      },
    );

    // Start with current position if available
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = initialPosition;
      _updateDistances();
      _checkAlarms(initialPosition);
      notifyListeners();

      print(
        'Started monitoring with initial position: ${initialPosition.latitude}, ${initialPosition.longitude}',
      );
    } catch (e) {
      print('Could not get initial position: $e');
      // Continue anyway as we'll get updates from the stream
    }

    _isMonitoring = true;
    notifyListeners();
    return true;
  }

  // Stop monitoring
  Future<void> stopMonitoring() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _isMonitoring = false;
    notifyListeners();
  }

  // Update jarak ke stasiun
  void _updateDistances() {
    if (_currentPosition == null) return;

    print('Updating distances for ${_allStations.length} stations...');

    // Update distances for all stations
    for (final station in _allStations) {
      final double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        station.latitude,
        station.longitude,
      );

      _stationDistances[station.id] = distance;
    }

    // Also update for test station if available
    if (_testStation != null) {
      final double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _testStation!.latitude,
        _testStation!.longitude,
      );

      _stationDistances[_testStation!.id] = distance;
    }

    // Sort favorite stations by distance
    _updateFavoriteStations();

    notifyListeners();
  }

  // Cek alarm
  void _checkAlarms(Position position) {
    if (_allStations.isEmpty) return;

    print(
      'Checking alarms for position: ${position.latitude}, ${position.longitude}',
    );

    // Check for active alarms
    for (final station in _allStations) {
      if (station.isAlarmActive) {
        final double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          station.latitude,
          station.longitude,
        );

        // Store the distance for UI display
        _stationDistances[station.id] = distance;

        print(
          'Station ${station.name} (${station.id}): distance=${distance.toStringAsFixed(1)}m, radius=${station.radiusInMeters}m, isActive=${station.isAlarmActive}',
        );

        // Check if user is inside the alarm radius
        if (distance <= station.radiusInMeters) {
          print('🔔 ALARM TRIGGERED for station ${station.name}!');
          _triggerAlarm(station);
        }
      }
    }

    notifyListeners();
  }

  // Add this method to trigger the alarm - separate it from the checking logic for clarity
  void _triggerAlarm(StationModel station) {
    // Check if alarm was already triggered recently
    final now = DateTime.now();
    final lastTriggeredKey = '${station.id}_last_triggered';
    final lastTriggered = _getLastTriggeredTime(lastTriggeredKey);

    // Only trigger again if enough time has passed
    if (lastTriggered == null || now.difference(lastTriggered).inSeconds > 20) {
      print('🔔 Playing alarm sound for ${station.name}');

      // Play alarm sound
      AlarmService.instance.playAlarm();

      // Show notification - just use one notification instead of two
      try {
        NotificationService.instance.showAlarmNotification(
          'Stasiun ${station.name}',
          'Anda telah memasuki radius ${station.radiusInMeters} meter dari stasiun ${station.name}.',
          stationId: station.id,
        );
      } catch (e) {
        print('Error showing notification: $e');
      }

      // Add to history
      if (_currentPosition != null) {
        final history = AlarmHistory(
          stationId: station.id,
          stationName: station.name,
          triggeredAt: now,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );

        _alarmHistory.add(history);
        _saveAlarmHistory();
      }

      // Save last triggered time
      _saveLastTriggeredTime(lastTriggeredKey, now);
    } else {
      print(
        'Alarm for ${station.name} was already triggered recently. Skipping.',
      );
    }
  }

  // Save alarm history
  Future<void> _saveAlarmHistory() async {
    try {
      final List<Map<String, dynamic>> historyMaps =
          _alarmHistory.map((history) => history.toMap()).toList();

      await StorageService.instance.saveAlarmHistory(historyMaps);
    } catch (e) {
      print('Error saving alarm history: $e');
    }
  }

  // Helper methods for managing last triggered time
  DateTime? _getLastTriggeredTime(String key) {
    try {
      final timestamp = StorageService.instance.prefs?.getInt(key);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('Error getting last triggered time: $e');
    }
    return null;
  }

  void _saveLastTriggeredTime(String key, DateTime time) {
    try {
      StorageService.instance.prefs?.setInt(key, time.millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving last triggered time: $e');
    }
  }

  // Tambah alarm
  Future<bool> addStationAlarm(StationModel station, int radius) async {
    try {
      final index = _allStations.indexWhere((s) => s.id == station.id);
      if (index == -1) return false;

      _allStations[index] = _allStations[index].copyWith(
        isAlarmActive: true,
        radiusInMeters: radius,
      );

      await _saveStationSettings();

      // Start monitoring if not already active
      if (!_isMonitoring) {
        await startMonitoring();
      }
      // If monitoring is already active and we have a position, check immediately
      else if (_currentPosition != null) {
        print('Checking alarm immediately after activation');
        _checkAlarms(_currentPosition!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding station alarm: $e');
      return false;
    }
  }

  // Update radius
  Future<bool> updateStationRadius(String stationId, int radius) async {
    try {
      final index = _allStations.indexWhere((s) => s.id == stationId);
      if (index == -1) return false;

      _allStations[index] = _allStations[index].copyWith(
        radiusInMeters: radius,
      );

      await _saveStationSettings();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating station radius: $e');
      return false;
    }
  }

  // Hapus alarm
  Future<bool> removeStationAlarm(String stationId) async {
    try {
      final index = _allStations.indexWhere((s) => s.id == stationId);
      if (index == -1) return false;

      _allStations[index] = _allStations[index].copyWith(isAlarmActive: false);

      // Stop the alarm sound when alarm is removed
      AlarmService.instance.stopAlarm();

      await _saveStationSettings();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing station alarm: $e');
      return false;
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(StationModel station) async {
    try {
      final index = _allStations.indexWhere((s) => s.id == station.id);
      if (index == -1) return;

      // Toggle favorite status
      _allStations[index] = _allStations[index].copyWith(
        isFavorite: !_allStations[index].isFavorite,
      );

      // Save the updated settings
      await _saveStationSettings();

      // Update favorite stations
      _updateFavoriteStations();

      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // Check if station has active alarm
  bool hasActiveAlarm(String stationId) {
    try {
      final station = _allStations.firstWhere(
        (s) => s.id == stationId,
        orElse:
            () => StationModel(
              id: '',
              name: '',
              line: '',
              latitude: 0,
              longitude: 0,
              alarmRadius: 0, // Provide a default value for alarmRadius
            ),
      );
      return station.isAlarmActive;
    } catch (e) {
      return false;
    }
  }

  // Get station by ID
  StationModel? getStationById(String stationId) {
    try {
      return _allStations.firstWhere((s) => s.id == stationId);
    } catch (e) {
      return null;
    }
  }

  // Update test station coordinates
  Future<bool> updateTestStationCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (_testStation == null) return false;

      _testStation = _testStation!.copyWith(
        latitude: latitude,
        longitude: longitude,
      );

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating test station coordinates: $e');
      return false;
    }
  }

  // Save/load stasiun settings
  Future<void> _saveStationSettings() async {
    final List<Map<String, dynamic>> settings =
        _allStations
            .map(
              (station) => {
                'id': station.id,
                'isAlarmActive': station.isAlarmActive,
                'radiusInMeters': station.radiusInMeters,
                'isFavorite': station.isFavorite,
                'latitude': station.latitude,
                'longitude': station.longitude,
              },
            )
            .toList();

    await StorageService.instance.saveStationSettings(settings);
  }

  Future<void> _loadSavedStationSettings() async {
    try {
      final settings = await StorageService.instance.loadStationSettings();

      if (settings.isEmpty) return;

      for (var setting in settings) {
        final index = _allStations.indexWhere((s) => s.id == setting['id']);
        if (index != -1) {
          _allStations[index] = _allStations[index].copyWith(
            isAlarmActive: setting['isAlarmActive'],
            radiusInMeters: setting['radiusInMeters'],
            isFavorite: setting['isFavorite'],
            latitude:
                setting['latitude'] is double
                    ? setting['latitude']
                    : _allStations[index].latitude,
            longitude:
                setting['longitude'] is double
                    ? setting['longitude']
                    : _allStations[index].longitude,
          );

          // Update test station reference if it's the test station
          if (_allStations[index].id == 'TST') {
            _testStation = _allStations[index];
          }
        }
      }

      _favoriteStations = _allStations.where((s) => s.isFavorite).toList();
    } catch (e) {
      print('Error loading saved station settings: $e');
    }
  }

  // Method to simulate being near a station for testing
  Future<void> simulateNearStation(String stationId) async {
    try {
      final station = getStationById(stationId);
      if (station == null || !station.isAlarmActive) {
        print('Station not found or alarm not active');
        return;
      }

      // Create fake position at station location
      final fakePosition = Position(
        latitude: station.latitude,
        longitude: station.longitude,
        timestamp: DateTime.now(),
        accuracy: 4.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      // Store current position temporarily
      final realPosition = _currentPosition;

      // Use fake position
      _currentPosition = fakePosition;

      // Update distances and check alarms
      _updateDistances();
      _checkAlarms(fakePosition);

      // Restore real position
      _currentPosition = realPosition;

      // Inform UI
      notifyListeners();
    } catch (e) {
      print('Error simulating near station: $e');
    }
  }

  // Clear alarm history
  Future<void> clearAlarmHistory() async {
    _alarmHistory.clear();
    await _saveAlarmHistory();

    // Stop any active alarm sounds
    AlarmService.instance.stopAlarm();

    notifyListeners();
  }

  // Add this method to the StationProvider class

  // Force refresh current location
  Future<bool> refreshLocation() async {
    try {
      // Request high-accuracy position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update current position
      _currentPosition = position;

      // Update distances and check alarms
      _updateDistances();
      _checkAlarms(position);

      // Notify listeners of the update
      notifyListeners();

      print(
        'Location refreshed manually: ${position.latitude}, ${position.longitude}',
      );
      return true;
    } catch (e) {
      print('Error refreshing location: $e');
      return false;
    }
  }

  // Update the list of favorite stations and sort by distance if available
  void _updateFavoriteStations() {
    _favoriteStations = _allStations.where((s) => s.isFavorite).toList();

    // Sort favorite stations by name
    _favoriteStations.sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
