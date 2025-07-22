import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/overlay_service.dart';
import '../utils/constants.dart';

class FloatingOverlay extends StatefulWidget {
  const FloatingOverlay({super.key});

  @override
  State<FloatingOverlay> createState() => _FloatingOverlayState();
}

class _FloatingOverlayState extends State<FloatingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _updateTimer;
  bool _isMinimized = false;
  bool _isDragging = false; // Keep this field as it's used

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: AppConstants.shortAnimationDuration,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: AppConstants.shortAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();

    _startUpdateTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.defaultPrecisionMs),
      (timer) => setState(() {}),
    );
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
    
    HapticFeedback.lightImpact();
  }

  void _handleEmergencyStop() {
    HapticFeedback.heavyImpact();
    
    // Trigger emergency stop through overlay service
    final overlayService = context.read<OverlayService>();
    overlayService.setEmergencyStopCallback(() {
      // This would be handled by the main app
    });
  }

  Color _getCountdownColor(Duration remaining) {
    if (remaining.isNegative) {
      return AppConstants.countdownExpiredColor;
    } else if (remaining.inSeconds <= 10) {
      return AppConstants.countdownCriticalColor;
    } else if (remaining.inSeconds <= 60) {
      return AppConstants.warningColor;
    } else {
      return AppConstants.countdownNormalColor;
    }
  }

  String _getCountdownStatus(Duration remaining) {
    if (remaining.isNegative) {
      return 'EXECUTING!';
    } else if (remaining.inSeconds <= 10) {
      return 'GET READY';
    } else if (remaining.inSeconds <= 60) {
      return 'FINAL MINUTE';
    } else {
      return 'COUNTDOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimerService, OverlayService>(
      builder: (context, timerService, overlayService, child) {
        final remaining = timerService.remainingTime;
        final countdownColor = _getCountdownColor(remaining);
        
        return AnimatedBuilder(
          animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  onPanUpdate: (details) {
                    // Handle dragging - would update position through overlay service
                    final newX = overlayService.overlayX + details.delta.dx;
                    final newY = overlayService.overlayY + details.delta.dy;
                    overlayService.updatePosition(newX, newY);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.backgroundColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                      border: Border.all(
                        color: countdownColor.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isMinimized ? _buildMinimizedView(remaining, countdownColor) : _buildFullView(remaining, countdownColor),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMinimizedView(Duration remaining, Color countdownColor) {
    return InkWell(
      onTap: _toggleMinimize,
      borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      child: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(AppConstants.smallSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppConstants.timerIcon,
              color: countdownColor,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              remaining.inSeconds > 99 
                  ? '${remaining.inMinutes}m'
                  : '${remaining.inSeconds}s',
              style: TextStyle(
                color: countdownColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(Duration remaining, Color countdownColor) {
    return Container(
      width: AppConstants.defaultOverlayWidth,
      height: AppConstants.defaultOverlayHeight,
      padding: const EdgeInsets.all(AppConstants.mediumSpacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCountdownStatus(remaining),
                style: AppConstants.captionStyle.copyWith(
                  color: countdownColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _toggleMinimize,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.minimize,
                        color: AppConstants.onSecondaryColor,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _handleEmergencyStop,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppConstants.errorColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        AppConstants.emergencyIcon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Countdown display
          Center(
            child: Column(
              children: [
                Text(
                  _formatOverlayTime(remaining),
                  style: AppConstants.overlayCountdownStyle.copyWith(
                    color: countdownColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (remaining.inSeconds <= 60 && !remaining.isNegative)
                  Container(
                    height: 2,
                    width: 200,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: AppConstants.surfaceColor,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: remaining.inSeconds / 60.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: countdownColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusDot('NTP', context.read<TimerService>().isNtpSynced),
              _buildStatusDot('Timer', context.read<TimerService>().isActive),
              _buildStatusDot('Clicks', context.read<OverlayService>().isOverlayActive),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppConstants.successColor : AppConstants.errorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppConstants.successColor : AppConstants.errorColor,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatOverlayTime(Duration remaining) {
    if (remaining.isNegative) {
      return 'EXECUTING';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    final milliseconds = remaining.inMilliseconds % 1000;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else if (seconds > 10) {
      return '${seconds}s';
    } else {
      return '$seconds.${(milliseconds / 100).floor()}s';
    }
  }
}

// Overlay entry point for the native overlay system
class OverlayEntryPoint extends StatelessWidget {
  const OverlayEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppConstants.darkTheme,
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: FloatingOverlay(),
      ),
    );
  }
}