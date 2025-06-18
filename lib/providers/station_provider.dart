import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geobeep/models/station_model.dart';
import 'package:geobeep/models/alarm_history.dart';
import 'package:geobeep/services/location_service.dart';
import 'package:geobeep/services/alarm_service.dart';
import 'package:geobeep/services/notification_service.dart';
import 'package:geobeep/services/storage_service.dart';
import 'package:geobeep/data/stations_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StationProvider extends ChangeNotifier {
  List<StationModel> _allStations = [];
  List<StationModel> _favoriteStations = [];
  final Map<String, double> _stationDistances = {};
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
  StationModel? get testStation =>
      _testStation; // Inisialisasi provider dan load data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allStations = StationsData.getAllStations();
      _testStation = StationsData.getTestStation();

      // Load local data first (for offline usage and fallback)
      await _loadSavedStationSettings();
      await _loadAlarmHistory();

      // Check if user is already logged in and load their data from Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print(
          '🔐 User already logged in during initialization: ${currentUser.uid}',
        );
        await loadFromFirestore(currentUser.uid);
      } else {
        print('👤 No user logged in during initialization, using local data');
      }

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

  // Tambah alarm with Firebase sync
  Future<bool> addStationAlarm(StationModel station, int radius) async {
    try {
      final index = _allStations.indexWhere((s) => s.id == station.id);
      if (index == -1) return false;

      _allStations[index] = _allStations[index].copyWith(
        isAlarmActive: true,
        radiusInMeters: radius,
      );

      // Save to local storage
      await _saveStationSettings();

      // Update monitoring status if needed
      if (!_isMonitoring) {
        await startMonitoring();
      } else if (_currentPosition != null) {
        _checkAlarms(_currentPosition!);
      }

      notifyListeners();

      // Sync to Firebase if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Syncing alarm settings to Firebase for user: ${user.uid}');
        await syncToFirestore(user.uid);
      }

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

  // Remove alarm with Firebase sync
  Future<bool> removeStationAlarm(String stationId) async {
    try {
      final index = _allStations.indexWhere((s) => s.id == stationId);
      if (index == -1) return false;

      _allStations[index] = _allStations[index].copyWith(isAlarmActive: false);

      // Stop any playing alarm sounds
      AlarmService.instance.stopAlarm();

      // Save to local storage
      await _saveStationSettings();

      notifyListeners();

      // Sync to Firebase if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Syncing alarm removal to Firebase for user: ${user.uid}');
        await syncToFirestore(user.uid);
      }

      return true;
    } catch (e) {
      print('Error removing station alarm: $e');
      return false;
    }
  }

  // Sinkronisasi data ke Firestore
  Future<void> syncToFirestore(String uid) async {
    try {
      // Get favorite station IDs
      final favIds =
          _allStations.where((s) => s.isFavorite).map((s) => s.id).toList();

      // Get all alarm settings (active alarms)
      final alarmSettings =
          _allStations
              .where((s) => s.isAlarmActive)
              .map(
                (s) => {
                  'id': s.id,
                  'radiusInMeters': s.radiusInMeters,
                  'lastUpdated': DateTime.now().millisecondsSinceEpoch,
                },
              )
              .toList();

      // Convert alarm history to maps with all details
      final historyMaps = _alarmHistory.map((h) => h.toMap()).toList();

      // Save everything to the user's document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'favoriteStations': favIds,
        'alarmSettings': alarmSettings,
        'alarmHistory': historyMaps,
        'lastSync': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      print('Successfully synced user data to Firestore for user: $uid');
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
  }

  // Load data dari Firestore
  Future<void> loadFromFirestore(String uid) async {
    try {
      print('🔄 Loading data from Firestore for user: $uid');
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        print('❌ No existing data found for user: $uid');
        return;
      }

      final data = doc.data()!;
      print('✅ Found user data in Firestore: ${data.keys}');

      // Load favorite stations
      final favIds = List<String>.from(data['favoriteStations'] ?? []);
      print('⭐ Loading ${favIds.length} favorite stations: $favIds');

      // Load alarm settings
      final alarmSettings = List<Map<String, dynamic>>.from(
        data['alarmSettings'] ?? [],
      );
      print('🔔 Loading ${alarmSettings.length} alarm settings');

      // Update stations with favorites and alarm settings
      _allStations =
          _allStations.map((s) {
            // Check if station is in favorites
            final isFav = favIds.contains(s.id);

            // Check if station has active alarm
            final alarmSetting = alarmSettings.firstWhere(
              (a) => a['id'] == s.id,
              orElse: () => {},
            );

            final isActive = alarmSetting.isNotEmpty;
            final radius = alarmSetting['radiusInMeters'] ?? s.radiusInMeters;

            if (isFav || isActive) {
              print(
                '📍 Station ${s.name}: favorite=$isFav, alarm=$isActive, radius=$radius',
              );
            }

            return s.copyWith(
              isFavorite: isFav,
              isAlarmActive: isActive,
              radiusInMeters: radius,
            );
          }).toList();

      // Load alarm history
      if (data.containsKey('alarmHistory')) {
        final historyList = List<Map<String, dynamic>>.from(
          data['alarmHistory'] ?? [],
        );
        _alarmHistory =
            historyList.map((m) => AlarmHistory.fromMap(m)).toList();
        print('📋 Loaded ${_alarmHistory.length} alarm history records');
      }

      // Update local favorites list
      _updateFavoriteStations();
      print('⭐ Updated favorites list: ${_favoriteStations.length} stations');

      // Save locally to SharedPreferences for offline access
      await _saveStationSettings();
      await _saveAlarmHistory();
      print('💾 Saved data locally for offline access');

      notifyListeners();
      print('🔔 UI notified of data changes');
    } catch (e) {
      print('❌ Error loading from Firestore: $e');
    }
  }

  // Dipanggil saat user login/logout
  Future<void> onUserChanged(User? user) async {
    try {
      if (user == null) {
        // Logout: clear user data and reset to default settings
        print('🚪 User logged out, clearing user-specific data');

        // Reset all favorites
        _favoriteStations.clear();

        // Reset all alarms
        _allStations =
            _allStations
                .map((s) => s.copyWith(isFavorite: false, isAlarmActive: false))
                .toList();

        // Clear alarm history
        _alarmHistory.clear();

        // Stop any playing alarms
        AlarmService.instance.stopAlarm();

        // Save cleared settings locally
        await _saveStationSettings();
        await _saveAlarmHistory();

        notifyListeners();
        print('✅ User data cleared and UI updated');
      } else {
        // Login: load data from Firestore
        print('🔐 User logged in: ${user.uid}, loading data from Firestore');

        // First ensure we have basic station data loaded
        if (_allStations.isEmpty) {
          print('📡 No stations loaded, initializing...');
          _allStations = StationsData.getAllStations();
          _testStation = StationsData.getTestStation();
        }

        await loadFromFirestore(user.uid);

        // If in monitoring mode, immediately check alarms with new settings
        if (_isMonitoring && _currentPosition != null) {
          print('📍 Re-checking alarms with new user settings');
          _checkAlarms(_currentPosition!);
        }

        print('✅ User login process completed');
      }
    } catch (e) {
      print('❌ Error in onUserChanged: $e');
    }
  }

  // Toggle favorite with Firebase sync
  Future<void> toggleFavorite(StationModel station) async {
    try {
      final index = _allStations.indexWhere((s) => s.id == station.id);
      if (index == -1) return;

      _allStations[index] = _allStations[index].copyWith(
        isFavorite: !_allStations[index].isFavorite,
      );

      // Save to local storage
      await _saveStationSettings();

      // Update favorite stations list
      _updateFavoriteStations();

      notifyListeners();

      // Sync to Firebase if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Syncing favorite changes to Firebase for user: ${user.uid}');
        await syncToFirestore(user.uid);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // Clear alarm history with Firebase sync
  Future<void> clearAlarmHistory() async {
    try {
      _alarmHistory.clear();

      // Save to local storage
      await _saveAlarmHistory();

      // Stop any active alarm sounds
      AlarmService.instance.stopAlarm();

      notifyListeners();

      // Sync to Firebase if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print(
          'Syncing alarm history clearing to Firebase for user: ${user.uid}',
        );
        await syncToFirestore(user.uid);
      }
    } catch (e) {
      print('Error clearing alarm history: $e');
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

  // Helper to get station by ID
  StationModel? getStationById(String id) {
    try {
      return _allStations.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
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
