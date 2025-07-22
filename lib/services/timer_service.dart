import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import '../models/timer_config.dart';
import '../utils/constants.dart';

class TimerService extends ChangeNotifier {
  Timer? _timer;
  DateTime? _ntpOffset;
  TimerConfig? _config;
  bool _isActive = false;
  bool _isSyncing = false;
  Duration _remainingTime = Duration.zero;
  DateTime? _lastUpdate;

  // Getters
  bool get isActive => _isActive;
  bool get isSyncing => _isSyncing;
  Duration get remainingTime => _remainingTime;
  TimerConfig? get config => _config;
  bool get isExpired => _remainingTime.isNegative || _remainingTime.inMilliseconds <= 0;
  bool get isNtpSynced => _ntpOffset != null;

  // High precision timer using DateTime.now() with NTP offset
  DateTime get accurateTime {
    final now = DateTime.now();
    if (_ntpOffset != null) {
      return now.add(_ntpOffset!.difference(DateTime.now()));
    }
    return now;
  }

  // Initialize NTP synchronization
  Future<bool> initializeNtpSync() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    notifyListeners();

    try {
      developer.log('Synchronizing with NTP servers...', name: 'TimerService');
      
      // Try multiple NTP servers for reliability
      for (String server in AppConstants.ntpServers) {
        try {
          final ntpTime = await NTP.now(lookUpAddress: server);
          _ntpOffset = ntpTime;
          developer.log('NTP sync successful with $server', name: 'TimerService');
          _isSyncing = false;
          notifyListeners();
          return true;
        } catch (e) {
          developer.log('NTP sync failed with $server: $e', name: 'TimerService');
          continue;
        }
      }
      
      developer.log('All NTP servers failed, using local time', name: 'TimerService');
      _ntpOffset = null;
      return false;
    } catch (e) {
      developer.log('NTP initialization error: $e', name: 'TimerService');
      _ntpOffset = null;
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Configure timer
  void configure(TimerConfig config) {
    _config = config;
    _calculateRemainingTime();
    notifyListeners();
  }

  // Start the high-precision timer
  void startTimer() {
    if (_config == null) {
      throw Exception('Timer not configured');
    }

    if (_isActive) {
      stopTimer();
    }

    _isActive = true;
    _lastUpdate = accurateTime;

    // Use a high-frequency timer for precision
    _timer = Timer.periodic(Duration(milliseconds: _config!.precisionMs), (timer) {
      _calculateRemainingTime();
      
      if (isExpired) {
        _handleTimerExpired();
      }
    });

    developer.log('Timer started with ${_config!.precisionMs}ms precision', name: 'TimerService');
    notifyListeners();
  }

  // Stop the timer
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    developer.log('Timer stopped', name: 'TimerService');
    notifyListeners();
  }

  // Calculate remaining time with high precision
  void _calculateRemainingTime() {
    if (_config == null) return;

    final now = accurateTime;
    _remainingTime = _config!.targetTime.difference(now);
    _lastUpdate = now;
  }

  // Handle timer expiration
  void _handleTimerExpired() {
    if (!_isActive) return;

    developer.log('Timer expired! Remaining: ${_remainingTime.inMilliseconds}ms', name: 'TimerService');
    
    stopTimer();
    _onTimerExpired?.call();
  }

  // Callback for timer expiration
  VoidCallback? _onTimerExpired;
  void setExpirationCallback(VoidCallback callback) {
    _onTimerExpired = callback;
  }

  // Format remaining time for display
  String formatRemainingTime({bool showMilliseconds = true}) {
    if (_remainingTime.isNegative) {
      return showMilliseconds ? '00:00:00.000' : '00:00:00';
    }

    final hours = _remainingTime.inHours;
    final minutes = (_remainingTime.inMinutes % 60);
    final seconds = (_remainingTime.inSeconds % 60);
    final milliseconds = (_remainingTime.inMilliseconds % 1000);

    if (showMilliseconds) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}.'
             '${milliseconds.toString().padLeft(3, '0')}';
    } else {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Get time until target in different units
  int get millisecondsRemaining => _remainingTime.inMilliseconds;
  int get secondsRemaining => _remainingTime.inSeconds;
  int get minutesRemaining => _remainingTime.inMinutes;
  int get hoursRemaining => _remainingTime.inHours;

  // Check if timer is in critical countdown phase (< 1 minute)
  bool get isCriticalCountdown => _remainingTime.inSeconds <= 60 && _remainingTime.inSeconds > 0;

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}