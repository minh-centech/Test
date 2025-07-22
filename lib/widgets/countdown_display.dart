import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/click_service.dart';
import '../services/overlay_service.dart';
import '../utils/constants.dart';

class CountdownDisplay extends StatefulWidget {
  const CountdownDisplay({super.key});

  @override
  State<CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends State<CountdownDisplay> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  Timer? _overlayUpdateTimer;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start overlay updates
    _startOverlayUpdates();
    
    // Listen for timer expiration
    _setupTimerCallbacks();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _overlayUpdateTimer?.cancel();
    super.dispose();
  }

  void _startOverlayUpdates() {
    _overlayUpdateTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.defaultPrecisionMs),
      (timer) => _updateOverlay(),
    );
  }

  void _updateOverlay() {
    final overlayService = context.read<OverlayService>();
    final timerService = context.read<TimerService>();
    
    if (overlayService.isOverlayActive && timerService.isActive) {
      overlayService.updateCountdown(timerService.remainingTime);
    }
  }

  void _setupTimerCallbacks() {
    final timerService = context.read<TimerService>();
    timerService.setExpirationCallback(() async {
      developer.log('Countdown completed, executing clicks', name: 'CountdownDisplay');
      
      setState(() {
        _isExecuting = true;
      });
      
      // Show completion on overlay
      final overlayService = context.read<OverlayService>();
      await overlayService.showCompletionOverlay();
      
      // Execute clicks
      final clickService = context.read<ClickService>();
      try {
        await clickService.executeClicks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.clicksExecutedMessage),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        developer.log('Click execution failed: $e', name: 'CountdownDisplay');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Click execution failed: $e'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      } finally {
        setState(() {
          _isExecuting = false;
        });
      }
    });
  }

  void _stopCountdown() {
    final timerService = context.read<TimerService>();
    final overlayService = context.read<OverlayService>();
    final clickService = context.read<ClickService>();
    
    timerService.stopTimer();
    overlayService.hideOverlay();
    clickService.stopExecution();
    
    Navigator.of(context).pop();
  }

  void _emergencyStop() {
    final timerService = context.read<TimerService>();
    final overlayService = context.read<OverlayService>();
    final clickService = context.read<ClickService>();
    
    timerService.stopTimer();
    overlayService.hideOverlay();
    clickService.emergencyStop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('EMERGENCY STOP ACTIVATED'),
        backgroundColor: AppConstants.errorColor,
        duration: Duration(seconds: 3),
      ),
    );
    
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Countdown Active'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.onPrimaryColor,
        actions: [
          IconButton(
            onPressed: _emergencyStop,
            icon: const Icon(AppConstants.emergencyIcon),
            tooltip: 'Emergency Stop',
          ),
        ],
      ),
      body: Consumer3<TimerService, ClickService, OverlayService>(
        builder: (context, timerService, clickService, overlayService, child) {
          final remaining = timerService.remainingTime;
          final countdownColor = _getCountdownColor(remaining);
          
          // Start pulse animation for critical countdown
          if (timerService.isCriticalCountdown && !_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          } else if (!timerService.isCriticalCountdown && _pulseController.isAnimating) {
            _pulseController.stop();
            _pulseController.reset();
          }

          // Start rotation for execution
          if (_isExecuting && !_rotationController.isAnimating) {
            _rotationController.repeat();
          } else if (!_isExecuting && _rotationController.isAnimating) {
            _rotationController.stop();
            _rotationController.reset();
          }

          return Padding(
            padding: const EdgeInsets.all(AppConstants.largeSpacing),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status indicator
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatusIndicator(
                              label: 'Timer',
                              isActive: timerService.isActive,
                              icon: AppConstants.timerIcon,
                            ),
                            _StatusIndicator(
                              label: 'NTP Sync',
                              isActive: timerService.isNtpSynced,
                              icon: AppConstants.syncIcon,
                            ),
                            _StatusIndicator(
                              label: 'Overlay',
                              isActive: overlayService.isOverlayActive,
                              icon: AppConstants.overlayIcon,
                            ),
                            _StatusIndicator(
                              label: 'Clicks',
                              isActive: clickService.activeSequence?.positions.isNotEmpty ?? false,
                              icon: AppConstants.clickIcon,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                AppConstants.extraLargeSpacing.verticalSpace,

                // Main countdown display
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Card(
                        elevation: 8,
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.extraLargeSpacing),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                            gradient: LinearGradient(
                              colors: [
                                countdownColor.withOpacity(0.1),
                                countdownColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                timerService.formatRemainingTime(showMilliseconds: true),
                                style: AppConstants.countdownStyle.copyWith(
                                  color: countdownColor,
                                  fontSize: 48,
                                ),
                              ),
                              AppConstants.smallSpacing.verticalSpace,
                              Text(
                                _getCountdownStatus(remaining),
                                style: AppConstants.bodyStyle.copyWith(
                                  color: countdownColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                if (_isExecuting) ...[
                  AppConstants.largeSpacing.verticalSpace,
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Card(
                          color: AppConstants.primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                            child: Column(
                              children: [
                                const Icon(
                                  AppConstants.clickIcon,
                                  color: AppConstants.onPrimaryColor,
                                  size: 32,
                                ),
                                AppConstants.smallSpacing.verticalSpace,
                                Text(
                                  'EXECUTING CLICKS',
                                  style: AppConstants.subheadingStyle.copyWith(
                                    color: AppConstants.onPrimaryColor,
                                  ),
                                ),
                                AppConstants.smallSpacing.verticalSpace,
                                Text(
                                  'Executed: ${clickService.executedClicks}',
                                  style: AppConstants.bodyStyle.copyWith(
                                    color: AppConstants.onPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                AppConstants.extraLargeSpacing.verticalSpace,

                // Configuration summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configuration',
                          style: AppConstants.subheadingStyle,
                        ),
                        AppConstants.smallSpacing.verticalSpace,
                        _ConfigItem(
                          label: 'Target Time',
                          value: timerService.config?.targetTime.toString().split('.').first ?? 'Not set',
                        ),
                        _ConfigItem(
                          label: 'Click Positions',
                          value: '${clickService.activeSequence?.positions.length ?? 0} positions',
                        ),
                        _ConfigItem(
                          label: 'Clicks per Position',
                          value: '${clickService.activeSequence?.clickCount ?? 0} clicks',
                        ),
                        _ConfigItem(
                          label: 'Click Speed',
                          value: '${clickService.getMaxClicksPerSecond().toStringAsFixed(1)} clicks/sec',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'emergency',
            onPressed: _emergencyStop,
            backgroundColor: AppConstants.errorColor,
            child: const Icon(AppConstants.emergencyIcon),
          ),
          AppConstants.smallSpacing.verticalSpace,
          FloatingActionButton(
            heroTag: 'stop',
            onPressed: _stopCountdown,
            backgroundColor: AppConstants.warningColor,
            child: const Icon(AppConstants.stopIcon),
          ),
        ],
      ),
    );
  }

  String _getCountdownStatus(Duration remaining) {
    if (remaining.isNegative) {
      return 'Countdown Complete!';
    } else if (remaining.inSeconds <= 10) {
      return 'Get Ready!';
    } else if (remaining.inSeconds <= 60) {
      return 'Final Minute';
    } else if (remaining.inMinutes <= 5) {
      return 'Almost Time';
    } else {
      return 'Countdown Active';
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData icon;

  const _StatusIndicator({
    required this.label,
    required this.isActive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: isActive ? AppConstants.successColor : AppConstants.errorColor,
          size: 24,
        ),
        AppConstants.smallSpacing.verticalSpace,
        Text(
          label,
          style: AppConstants.captionStyle.copyWith(
            color: isActive ? AppConstants.successColor : AppConstants.errorColor,
          ),
        ),
      ],
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppConstants.captionStyle,
          ),
          Text(
            value,
            style: AppConstants.bodyStyle,
          ),
        ],
      ),
    );
  }
}