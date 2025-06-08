import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? _customAlarmUrl;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _listenToAlarmSoundChanges();
      await _loadCustomAlarmUrl();
      if (_customAlarmUrl != null && _customAlarmUrl!.isNotEmpty) {
        await _audioPlayer.setUrl(_customAlarmUrl!);
      } else {
        await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
      }
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(1.0);
      _isInitialized = true;
      debugPrint('AlarmService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AlarmService: $e');
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: 2), initialize);
    }
  }

  Future<void> _listenToAlarmSoundChanges() async {
    _userDocSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
          final newUrl = doc.data()?['alarmSoundUrl'] as String?;
          if (newUrl != _customAlarmUrl) {
            _customAlarmUrl = newUrl;
            _isInitialized = false;
            await initialize();
          }
        });
  }

  Future<void> _loadCustomAlarmUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _customAlarmUrl = null;
        return;
      }
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && doc.data() != null && doc['alarmSoundUrl'] != null) {
        _customAlarmUrl = doc['alarmSoundUrl'];
      } else {
        _customAlarmUrl = null;
      }
    } catch (e) {
      debugPrint('Error loading custom alarm url: $e');
      _customAlarmUrl = null;
    }
  }

  Future<void> refreshCustomAlarmSound() async {
    _isInitialized = false;
    await initialize();
  }

  Future<void> playAlarm() async {
    if (_isPlaying) {
      debugPrint('Alarm already playing');
      return;
    }
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        HapticFeedback.vibrate();
        return;
      }
    }
    try {
      debugPrint('Starting alarm sound...');
      _isPlaying = true;
      HapticFeedback.heavyImpact();
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
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
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 10), () {
        stopAlarm();
      });
      debugPrint('Alarm started successfully');
    } catch (e) {
      _isPlaying = false;
      debugPrint('Error playing alarm: $e');
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
      _isPlaying = false;
    }
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    stopAlarm();
    _retryTimer?.cancel();
    _vibrationTimer?.cancel();
    _userDocSubscription?.cancel();
    _audioPlayer.dispose();
  }
}
