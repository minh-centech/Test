import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/click_position.dart';
import '../utils/constants.dart';

class ClickService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('binance_auto_clicker/clicks');
  
  bool _isExecuting = false;
  bool _isTestMode = false;
  int _executedClicks = 0;
  ClickSequence? _activeSequence;
  Timer? _clickTimer;
  AudioPlayer? _audioPlayer;

  // Getters
  bool get isExecuting => _isExecuting;
  bool get isTestMode => _isTestMode;
  int get executedClicks => _executedClicks;
  ClickSequence? get activeSequence => _activeSequence;

  ClickService() {
    _initializeAudio();
    _setupMethodChannel();
  }

  // Initialize audio player for feedback
  void _initializeAudio() {
    _audioPlayer = AudioPlayer();
  }

  // Setup method channel for native click implementation
  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'clickExecuted':
          _handleClickExecuted(call.arguments);
          break;
        case 'sequenceCompleted':
          _handleSequenceCompleted(call.arguments);
          break;
        case 'clickError':
          _handleClickError(call.arguments);
          break;
        default:
          developer.log('Unknown method: ${call.method}', name: 'ClickService');
      }
    });
  }

  // Configure click sequence
  void configureSequence(ClickSequence sequence) {
    _activeSequence = sequence;
    notifyListeners();
    developer.log('Click sequence configured: ${sequence.positions.length} positions, ${sequence.clickCount} clicks each', name: 'ClickService');
  }

  // Execute rapid clicks at configured positions
  Future<void> executeClicks({bool testMode = false}) async {
    if (_activeSequence == null || _activeSequence!.positions.isEmpty) {
      throw Exception('No click sequence configured');
    }

    if (_isExecuting) {
      developer.log('Click execution already in progress', name: 'ClickService');
      return;
    }

    _isExecuting = true;
    _isTestMode = testMode;
    _executedClicks = 0;
    notifyListeners();

    try {
      developer.log('Starting click execution - ${testMode ? 'TEST MODE' : 'LIVE MODE'}', name: 'ClickService');
      
      // Provide haptic feedback
      await _triggerHapticFeedback();
      
      // Play start sound if enabled
      await _playClickSound();

      if (testMode) {
        await _executeTestClicks();
      } else {
        await _executeLiveClicks();
      }

    } catch (e) {
      developer.log('Click execution error: $e', name: 'ClickService');
      rethrow;
    } finally {
      _isExecuting = false;
      _isTestMode = false;
      notifyListeners();
    }
  }

  // Execute test clicks (slower, with visual feedback)
  Future<void> _executeTestClicks() async {
    final sequence = _activeSequence!;
    
    for (int i = 0; i < sequence.positions.length; i++) {
      final position = sequence.positions[i];
      if (!position.isEnabled) continue;

      developer.log('Test clicking at position: ${position.label} (${position.x}, ${position.y})', name: 'ClickService');
      
      // Simulate click with visual feedback
      await _simulateClick(position);
      
      // Wait longer between test clicks for visibility
      await Future.delayed(const Duration(milliseconds: 500));
      
      _executedClicks++;
      notifyListeners();
    }
  }

  // Execute live rapid clicks
  Future<void> _executeLiveClicks() async {
    final sequence = _activeSequence!;
    final enabledPositions = sequence.positions.where((p) => p.isEnabled).toList();
    
    if (enabledPositions.isEmpty) {
      throw Exception('No enabled click positions');
    }

    // Execute rapid clicks for each position
    for (final position in enabledPositions) {
      await _executeRapidClicksAtPosition(position, sequence.clickCount, sequence.clickInterval);
    }
  }

  // Execute rapid clicks at a specific position
  Future<void> _executeRapidClicksAtPosition(ClickPosition position, int count, Duration interval) async {
    developer.log('Executing $count rapid clicks at ${position.label}', name: 'ClickService');

    try {
      // Use native implementation for high-speed clicking
      final result = await _channel.invokeMethod('executeRapidClicks', {
        'x': position.x,
        'y': position.y,
        'count': count,
        'intervalMs': interval.inMilliseconds,
      });
      
      developer.log('Native click execution result: $result', name: 'ClickService');
      
    } catch (e) {
      developer.log('Native click failed, using fallback: $e', name: 'ClickService');
      await _fallbackRapidClicks(position, count, interval);
    }
  }

  // Fallback rapid clicking implementation
  Future<void> _fallbackRapidClicks(ClickPosition position, int count, Duration interval) async {
    for (int i = 0; i < count; i++) {
      await _simulateClick(position);
      _executedClicks++;
      
      if (interval.inMilliseconds > 0 && i < count - 1) {
        await Future.delayed(interval);
      }
      
      notifyListeners();
    }
  }

  // Simulate a single click
  Future<void> _simulateClick(ClickPosition position) async {
    try {
      // Attempt to use system-level click if available
      await _channel.invokeMethod('simulateClick', {
        'x': position.x,
        'y': position.y,
      });
    } catch (e) {
      // Fallback to basic tap simulation
      developer.log('System click failed, using basic simulation: $e', name: 'ClickService');
      
      // Trigger haptic feedback as click simulation
      HapticFeedback.lightImpact();
    }
  }

  // Test single position
  Future<void> testPosition(ClickPosition position) async {
    developer.log('Testing position: ${position.label}', name: 'ClickService');
    
    await _triggerHapticFeedback();
    await _simulateClick(position);
    await _playClickSound();
  }

  // Stop current execution
  void stopExecution() {
    if (!_isExecuting) return;
    
    _clickTimer?.cancel();
    _clickTimer = null;
    
    try {
      _channel.invokeMethod('stopExecution');
    } catch (e) {
      developer.log('Stop execution error: $e', name: 'ClickService');
    }
    
    _isExecuting = false;
    notifyListeners();
    
    developer.log('Click execution stopped', name: 'ClickService');
  }

  // Emergency stop all operations
  Future<void> emergencyStop() async {
    stopExecution();
    
    try {
      await _channel.invokeMethod('emergencyStop');
    } catch (e) {
      developer.log('Emergency stop error: $e', name: 'ClickService');
    }
    
    developer.log('EMERGENCY STOP ACTIVATED', name: 'ClickService');
  }

  // Haptic feedback
  Future<void> _triggerHapticFeedback() async {
    try {
      // Try device vibration first
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: AppConstants.vibrationDuration);
      } else {
        // Fallback to system haptic feedback
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // Final fallback
      HapticFeedback.lightImpact();
      developer.log('Vibration error: $e', name: 'ClickService');
    }
  }

  // Audio feedback
  Future<void> _playClickSound() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.play(AssetSource('sounds/click.wav'));
      }
    } catch (e) {
      developer.log('Audio playback error: $e', name: 'ClickService');
    }
  }

  // Method channel handlers
  void _handleClickExecuted(dynamic arguments) {
    _executedClicks++;
    notifyListeners();
  }

  void _handleSequenceCompleted(dynamic arguments) {
    _isExecuting = false;
    notifyListeners();
    developer.log('Click sequence completed', name: 'ClickService');
  }

  void _handleClickError(dynamic arguments) {
    developer.log('Click error: $arguments', name: 'ClickService');
  }

  // Calculate theoretical maximum clicks per second
  double getMaxClicksPerSecond() {
    if (_activeSequence == null) return 0.0;
    return _activeSequence!.estimatedClicksPerSecond;
  }

  // Get execution statistics
  Map<String, dynamic> getExecutionStats() {
    return {
      'executedClicks': _executedClicks,
      'isExecuting': _isExecuting,
      'isTestMode': _isTestMode,
      'activePositions': _activeSequence?.positions.where((p) => p.isEnabled).length ?? 0,
      'totalPositions': _activeSequence?.positions.length ?? 0,
      'maxClicksPerSecond': getMaxClicksPerSecond(),
    };
  }

  @override
  void dispose() {
    stopExecution();
    _audioPlayer?.dispose();
    super.dispose();
  }
}