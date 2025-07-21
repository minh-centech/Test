import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/timer_config.dart';

class OverlayService extends ChangeNotifier {
  bool _isOverlayActive = false;
  bool _isOverlayEnabled = false;
  bool _isDraggable = true;
  double _overlayX = 100.0;
  double _overlayY = 100.0;
  StreamSubscription? _overlaySubscription;

  // Getters
  bool get isOverlayActive => _isOverlayActive;
  bool get isOverlayEnabled => _isOverlayEnabled;
  bool get isDraggable => _isDraggable;
  double get overlayX => _overlayX;
  double get overlayY => _overlayY;

  // Initialize overlay service
  Future<bool> initialize() async {
    try {
      // Check if overlay permission is granted
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      _isOverlayEnabled = hasPermission;
      
      if (hasPermission) {
        _setupOverlayListeners();
        developer.log('Overlay service initialized successfully', name: 'OverlayService');
      } else {
        developer.log('Overlay permission not granted', name: 'OverlayService');
      }
      
      notifyListeners();
      return hasPermission;
    } catch (e) {
      developer.log('Overlay initialization error: $e', name: 'OverlayService');
      return false;
    }
  }

  // Request overlay permission
  Future<bool> requestOverlayPermission() async {
    try {
      final isGranted = await FlutterOverlayWindow.requestPermission();
      _isOverlayEnabled = isGranted;
      
      if (isGranted) {
        _setupOverlayListeners();
      }
      
      notifyListeners();
      developer.log('Overlay permission ${isGranted ? 'granted' : 'denied'}', name: 'OverlayService');
      return isGranted;
    } catch (e) {
      developer.log('Overlay permission request error: $e', name: 'OverlayService');
      return false;
    }
  }

  // Setup overlay event listeners
  void _setupOverlayListeners() {
    _overlaySubscription?.cancel();
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      developer.log('Overlay event: $data', name: 'OverlayService');
      
      if (data is Map) {
        _handleOverlayEvent(data);
      }
    });
  }

  // Handle overlay events
  void _handleOverlayEvent(Map data) {
    switch (data['type']) {
      case 'position_changed':
        _overlayX = data['x']?.toDouble() ?? _overlayX;
        _overlayY = data['y']?.toDouble() ?? _overlayY;
        notifyListeners();
        break;
      case 'overlay_closed':
        _isOverlayActive = false;
        notifyListeners();
        break;
      case 'emergency_stop':
        _handleEmergencyStop();
        break;
      default:
        break;
    }
  }

  // Show floating countdown overlay
  Future<bool> showCountdownOverlay(TimerConfig config) async {
    if (!_isOverlayEnabled) {
      developer.log('Overlay not enabled, requesting permission', name: 'OverlayService');
      final hasPermission = await requestOverlayPermission();
      if (!hasPermission) return false;
    }

    try {
      // Enable wake lock to keep screen on
      await WakelockPlus.enable();
      
      await FlutterOverlayWindow.showOverlay(
        enableDrag: _isDraggable,
        overlayTitle: "Binance Auto-Clicker",
        overlayContent: 'Countdown Active',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        width: 300,
        height: 120,
        startPosition: OverlayPosition(_overlayX.toInt(), _overlayY.toInt()),
      );

      _isOverlayActive = true;
      notifyListeners();
      
      developer.log('Countdown overlay shown', name: 'OverlayService');
      return true;
    } catch (e) {
      developer.log('Show overlay error: $e', name: 'OverlayService');
      return false;
    }
  }

  // Update overlay content
  Future<void> updateOverlayContent({
    String? title,
    String? content,
    Map<String, dynamic>? data,
  }) async {
    if (!_isOverlayActive) return;

    try {
      await FlutterOverlayWindow.shareData({
        'action': 'update_content',
        'title': title,
        'content': content,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      developer.log('Update overlay content error: $e', name: 'OverlayService');
    }
  }

  // Update countdown display
  Future<void> updateCountdown(Duration remaining) async {
    if (!_isOverlayActive) return;

    final hours = remaining.inHours;
    final minutes = (remaining.inMinutes % 60);
    final seconds = (remaining.inSeconds % 60);
    final milliseconds = (remaining.inMilliseconds % 1000);

    final formattedTime = '${hours.toString().padLeft(2, '0')}:'
                         '${minutes.toString().padLeft(2, '0')}:'
                         '${seconds.toString().padLeft(2, '0')}.'
                         '${milliseconds.toString().padLeft(3, '0')}';

    await updateOverlayContent(
      title: 'Countdown',
      content: formattedTime,
      data: {
        'remaining_ms': remaining.inMilliseconds,
        'is_critical': remaining.inSeconds <= 10,
        'is_expired': remaining.isNegative,
      },
    );
  }

  // Show completion overlay
  Future<void> showCompletionOverlay() async {
    await updateOverlayContent(
      title: 'EXECUTING',
      content: 'Clicks Started!',
      data: {
        'status': 'executing',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Hide overlay
  Future<void> hideOverlay() async {
    if (!_isOverlayActive) return;

    try {
      await FlutterOverlayWindow.closeOverlay();
      await WakelockPlus.disable();
      
      _isOverlayActive = false;
      notifyListeners();
      
      developer.log('Overlay hidden', name: 'OverlayService');
    } catch (e) {
      developer.log('Hide overlay error: $e', name: 'OverlayService');
    }
  }

  // Toggle overlay draggable state
  void setDraggable(bool draggable) {
    _isDraggable = draggable;
    notifyListeners();
    
    // If overlay is active, restart with new settings
    if (_isOverlayActive) {
      _restartOverlay();
    }
  }

  // Update overlay position
  void updatePosition(double x, double y) {
    _overlayX = x;
    _overlayY = y;
    notifyListeners();
  }

  // Restart overlay with current settings
  Future<void> _restartOverlay() async {
    if (!_isOverlayActive) return;
    
    try {
      await hideOverlay();
      await Future.delayed(const Duration(milliseconds: 100));
      // Note: Would need to restore with current config
      // This would typically be managed by the calling service
    } catch (e) {
      developer.log('Restart overlay error: $e', name: 'OverlayService');
    }
  }

  // Handle emergency stop from overlay
  void _handleEmergencyStop() {
    developer.log('Emergency stop triggered from overlay', name: 'OverlayService');
    // Notify listeners that emergency stop was requested
    _onEmergencyStop?.call();
  }

  // Emergency stop callback
  VoidCallback? _onEmergencyStop;
  void setEmergencyStopCallback(VoidCallback callback) {
    _onEmergencyStop = callback;
  }

  // Check if overlay is supported on current platform
  bool get isOverlaySupported {
    // Overlay is primarily supported on Android
    return defaultTargetPlatform == TargetPlatform.android;
  }

  // Get overlay status info
  Map<String, dynamic> getOverlayStatus() {
    return {
      'isSupported': isOverlaySupported,
      'isEnabled': _isOverlayEnabled,
      'isActive': _isOverlayActive,
      'isDraggable': _isDraggable,
      'position': {'x': _overlayX, 'y': _overlayY},
    };
  }

  @override
  void dispose() {
    hideOverlay();
    _overlaySubscription?.cancel();
    super.dispose();
  }
}