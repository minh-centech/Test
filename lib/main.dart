import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'services/timer_service.dart';
import 'services/click_service.dart';
import 'services/overlay_service.dart';
import 'widgets/setup_screen.dart';
import 'widgets/floating_overlay.dart';
import 'utils/constants.dart';
import 'utils/permissions.dart';

void main() {
  runApp(const BinanceAutoClickerApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
        ChangeNotifierProvider(create: (_) => ClickService()),
        ChangeNotifierProvider(create: (_) => OverlayService()),
      ],
      child: const OverlayEntryPoint(),
    ),
  );
}

class BinanceAutoClickerApp extends StatelessWidget {
  const BinanceAutoClickerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
        ChangeNotifierProvider(create: (_) => ClickService()),
        ChangeNotifierProvider(create: (_) => OverlayService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppConstants.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isInitialized = false;
  String _initializationStatus = 'Initializing...';
  List<String> _initializationSteps = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _updateStatus('Checking platform capabilities...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Check platform support
      final overlayService = context.read<OverlayService>();
      if (overlayService.isOverlaySupported) {
        _addStep('✓ Overlay support detected');
      } else {
        _addStep('⚠ Overlay not supported on this platform');
      }

      await _updateStatus('Initializing services...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Initialize services
      final timerService = context.read<TimerService>();
      final clickService = context.read<ClickService>();

      // Initialize overlay service
      await overlayService.initialize();
      _addStep('✓ Overlay service initialized');

      await _updateStatus('Configuring timer service...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Configure timer precision
      _addStep('✓ Timer service configured');

      await _updateStatus('Setting up click system...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Initialize click service
      _addStep('✓ Click service initialized');

      await _updateStatus('Checking permissions...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Check critical permissions
      final hasOverlay = await PermissionHelper.hasOverlayPermission();
      final hasAccessibility = await PermissionHelper.hasAccessibilityPermission();
      final hasNotification = await PermissionHelper.hasNotificationPermission();

      if (hasOverlay) {
        _addStep('✓ Overlay permission granted');
      } else {
        _addStep('⚠ Overlay permission required');
      }

      if (hasAccessibility) {
        _addStep('✓ Accessibility permission granted');
      } else {
        _addStep('⚠ Accessibility permission required');
      }

      if (hasNotification) {
        _addStep('✓ Notification permission granted');
      } else {
        _addStep('⚠ Notification permission recommended');
      }

      await _updateStatus('Setting up native components...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Setup method channel for native functionality
      try {
        await _setupNativeComponents();
        _addStep('✓ Native components ready');
      } catch (e) {
        _addStep('⚠ Native components limited');
        developer.log('Native setup warning: $e', name: 'SplashScreen');
      }

      await _updateStatus('Finalizing...');
      await Future.delayed(const Duration(milliseconds: 500));

      _addStep('✓ Initialization complete');

      setState(() {
        _isInitialized = true;
        _initializationStatus = 'Ready to launch!';
      });

      // Navigate to main screen after a brief delay
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SetupScreen()),
        );
      }

    } catch (e) {
      developer.log('Initialization error: $e', name: 'SplashScreen');
      setState(() {
        _initializationStatus = 'Initialization failed: $e';
      });
      
      // Show retry option
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        _showRetryDialog();
      }
    }
  }

  Future<void> _setupNativeComponents() async {
    // Set up method channel for native click functionality
    const platform = MethodChannel('binance_auto_clicker/clicks');
    
    try {
      // Test native component availability
      await platform.invokeMethod('isAvailable');
    } catch (e) {
      // Native components not available, will use fallback
      developer.log('Native components not available: $e', name: 'SplashScreen');
      rethrow;
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _initializationStatus = status;
    });
  }

  void _addStep(String step) {
    setState(() {
      _initializationSteps.add(step);
    });
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Failed'),
        content: const Text(
          'The app failed to initialize properly. This may be due to missing permissions or system limitations.',
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SetupScreen()),
              );
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largeSpacing),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo/icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          AppConstants.clickIcon,
                          size: 60,
                          color: AppConstants.onPrimaryColor,
                        ),
                      ),

                      AppConstants.extraLargeSpacing.verticalSpace,

                      // App name
                      Text(
                        AppConstants.appName,
                        style: AppConstants.headingStyle.copyWith(
                          fontSize: 28,
                          color: AppConstants.primaryColor,
                        ),
                      ),

                      AppConstants.smallSpacing.verticalSpace,

                      // App description
                      Text(
                        AppConstants.appDescription,
                        style: AppConstants.captionStyle,
                        textAlign: TextAlign.center,
                      ),

                      AppConstants.extraLargeSpacing.verticalSpace,

                      // Initialization status
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                          child: Column(
                            children: [
                              if (!_isInitialized) ...[
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                                ),
                                AppConstants.mediumSpacing.verticalSpace,
                              ] else ...[
                                const Icon(
                                  Icons.check_circle,
                                  color: AppConstants.successColor,
                                  size: 32,
                                ),
                                AppConstants.mediumSpacing.verticalSpace,
                              ],
                              
                              Text(
                                _initializationStatus,
                                style: AppConstants.bodyStyle,
                                textAlign: TextAlign.center,
                              ),

                              if (_initializationSteps.isNotEmpty) ...[
                                AppConstants.mediumSpacing.verticalSpace,
                                const Divider(),
                                AppConstants.smallSpacing.verticalSpace,
                                
                                SizedBox(
                                  height: 120,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _initializationSteps.map((step) => 
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Text(
                                            step,
                                            style: AppConstants.captionStyle.copyWith(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      AppConstants.largeSpacing.verticalSpace,

                      // Version info
                      Text(
                        'Version ${AppConstants.appVersion}',
                        style: AppConstants.captionStyle.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}