import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AlarmService {
  static AlarmService? _instance;
  static AlarmService get instance => _instance ??= AlarmService._();
  AlarmService._() {
    // Initialize immediately when created
    initialize();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isInitialized = false;
  Timer? _autoStopTimer;
  Timer? _retryTimer;
  Timer? _vibrationTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Pre-load the alarm sound
      await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop the alarm

      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);

      _isInitialized = true;
      debugPrint('AlarmService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AlarmService: $e');
      // Try again after a delay
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: 2), initialize);
    }
  }

  Future<void> playAlarm() async {
    if (_isPlaying) {
      debugPrint('Alarm already playing');
      return;
    }

    // If not initialized, try to initialize first
    if (!_isInitialized) {
      await initialize();
      // If still not initialized, fall back to vibration
      if (!_isInitialized) {
        HapticFeedback.vibrate();
        return;
      }
    }

    try {
      debugPrint('Starting alarm sound...');
      _isPlaying = true;

      // Play vibration immediately
      HapticFeedback.heavyImpact();

      // Play sound
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();

      // Vibrate with pattern for extra attention
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 800), (
        timer,
      ) {
        if (!_isPlaying) {
          timer.cancel();
          return;
        }
        HapticFeedback.vibrate();
      });

      // Auto-stop after 10 seconds
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 10), () {
        stopAlarm();
      });

      debugPrint('Alarm started successfully');
    } catch (e) {
      _isPlaying = false;
      debugPrint('Error playing alarm: $e');
      // Fallback to vibration if sound fails
      HapticFeedback.vibrate();
      Future.delayed(Duration(milliseconds: 500), () {
        HapticFeedback.vibrate();
      });
      Future.delayed(Duration(milliseconds: 1000), () {
        HapticFeedback.vibrate();
      });
    }
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stop();
      _autoStopTimer?.cancel();
      _vibrationTimer?.cancel();
      _isPlaying = false;
      debugPrint('Alarm stopped successfully');
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
      // Even if there's an error, mark as not playing
      _isPlaying = false;
    }
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    stopAlarm();
    _retryTimer?.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer.dispose();
  }
}
