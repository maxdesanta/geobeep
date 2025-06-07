import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;
  SharedPreferences? get prefs => _prefs;

  // Initialize shared preferences
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // Save alarm settings
  Future<void> saveStationSettings(List<Map<String, dynamic>> settings) async {
    await _ensureInitialized();

    // Convert to JSON strings
    final List<String> jsonList = settings.map((s) => json.encode(s)).toList();
    await _prefs!.setStringList('station_settings', jsonList);
  }

  // Load alarm settings
  Future<List<Map<String, dynamic>>> loadStationSettings() async {
    await _ensureInitialized();

    final jsonList = _prefs!.getStringList('station_settings') ?? [];
    // Convert JSON strings to maps
    return jsonList
        .map((jsonStr) => json.decode(jsonStr) as Map<String, dynamic>)
        .toList();
  }

  // Save alarm history
  Future<void> saveAlarmHistory(List<Map<String, dynamic>> history) async {
    await _ensureInitialized();

    // Convert to JSON strings
    final List<String> jsonList = history.map((h) => json.encode(h)).toList();
    await _prefs!.setStringList('alarm_history', jsonList);
  }

  // Load alarm history
  Future<List<Map<String, dynamic>>> loadAlarmHistory() async {
    await _ensureInitialized();

    final jsonList = _prefs!.getStringList('alarm_history') ?? [];
    // Convert JSON strings to maps
    return jsonList
        .map((jsonStr) => json.decode(jsonStr) as Map<String, dynamic>)
        .toList();
  }
}
