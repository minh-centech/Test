import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Binance Auto-Clicker';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Professional auto-clicking tool for Binance coin launches';

  // Timer Configuration
  static const int defaultPrecisionMs = 10;
  static const int minPrecisionMs = 1;
  static const int maxPrecisionMs = 100;
  static const Duration defaultCountdownDuration = Duration(minutes: 5);

  // NTP Servers (in order of preference)
  static const List<String> ntpServers = [
    'time.google.com',
    'pool.ntp.org',
    'time.cloudflare.com',
    'time.nist.gov',
  ];

  // Click Configuration
  static const int defaultClickCount = 10;
  static const int minClickCount = 1;
  static const int maxClickCount = 100;
  static const Duration defaultClickInterval = Duration(milliseconds: 10);
  static const Duration minClickInterval = Duration(milliseconds: 1);
  static const Duration maxClickInterval = Duration(milliseconds: 1000);

  // Performance Targets
  static const double targetClicksPerSecond = 100.0;
  static const int maxConcurrentPositions = 10;

  // Feedback Settings
  static const int vibrationDuration = 50; // milliseconds
  static const double clickSoundVolume = 0.5;

  // UI Constants
  static const double defaultOverlayWidth = 300.0;
  static const double defaultOverlayHeight = 120.0;
  static const double minOverlaySize = 80.0;
  static const double maxOverlaySize = 500.0;

  // Colors
  static const Color primaryColor = Color(0xFFF0B90B); // Binance Yellow
  static const Color secondaryColor = Color(0xFF1E2329); // Binance Dark
  static const Color successColor = Color(0xFF02C076); // Binance Green
  static const Color errorColor = Color(0xFFFF6838); // Binance Red
  static const Color warningColor = Color(0xFFFF9500); // Warning Orange
  static const Color backgroundColor = Color(0xFF0B0E11);
  static const Color surfaceColor = Color(0xFF1E2329);
  static const Color onPrimaryColor = Color(0xFF000000);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);

  // Timer Display Colors
  static const Color countdownNormalColor = Colors.white;
  static const Color countdownCriticalColor = Color(0xFFFF6838);
  static const Color countdownExpiredColor = Color(0xFF02C076);

  // Status Colors
  static const Color statusIdleColor = Colors.grey;
  static const Color statusActiveColor = Color(0xFF02C076);
  static const Color statusExecutingColor = Color(0xFFF0B90B);
  static const Color statusErrorColor = Color(0xFFFF6838);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: onSecondaryColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: onSecondaryColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: onSecondaryColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  static const TextStyle countdownStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: countdownNormalColor,
  );

  static const TextStyle overlayCountdownStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: countdownNormalColor,
  );

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Border Radius
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double circularRadius = 50.0;

  // Button Dimensions
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 36.0;
  static const double largeButtonHeight = 56.0;
  static const double buttonBorderRadius = mediumRadius;

  // Input Field Dimensions
  static const double inputHeight = 48.0;
  static const double inputBorderRadius = mediumRadius;

  // Icons
  static const IconData timerIcon = Icons.timer;
  static const IconData clickIcon = Icons.touch_app;
  static const IconData overlayIcon = Icons.picture_in_picture;
  static const IconData settingsIcon = Icons.settings;
  static const IconData playIcon = Icons.play_arrow;
  static const IconData stopIcon = Icons.stop;
  static const IconData pauseIcon = Icons.pause;
  static const IconData emergencyIcon = Icons.emergency;
  static const IconData testIcon = Icons.bug_report;
  static const IconData positionIcon = Icons.my_location;
  static const IconData syncIcon = Icons.sync;
  static const IconData soundIcon = Icons.volume_up;
  static const IconData vibrationIcon = Icons.vibration;

  // Error Messages
  static const String noPermissionError = 'Required permissions not granted';
  static const String overlayNotSupportedError = 'Overlay not supported on this device';
  static const String ntpSyncFailedError = 'Failed to synchronize with time servers';
  static const String noPositionsError = 'No click positions configured';
  static const String timerNotConfiguredError = 'Timer not configured';
  static const String clickExecutionError = 'Failed to execute clicks';

  // Success Messages
  static const String permissionGrantedMessage = 'All permissions granted';
  static const String ntpSyncSuccessMessage = 'Time synchronized successfully';
  static const String positionAddedMessage = 'Click position added';
  static const String timerStartedMessage = 'Timer started';
  static const String clicksExecutedMessage = 'Clicks executed successfully';

  // Storage Keys
  static const String timerConfigKey = 'timer_config';
  static const String clickPositionsKey = 'click_positions';
  static const String settingsKey = 'app_settings';
  static const String overlaySettingsKey = 'overlay_settings';

  // Default Settings
  static const Map<String, dynamic> defaultSettings = {
    'soundEnabled': true,
    'vibrationEnabled': true,
    'overlayEnabled': true,
    'ntpSyncEnabled': true,
    'precisionMs': defaultPrecisionMs,
    'clickCount': defaultClickCount,
    'clickInterval': 10, // milliseconds
  };

  // Validation Rules
  static const int minTargetTimeMinutes = 1;
  static const int maxTargetTimeHours = 24;
  static const int maxPositionLabelLength = 50;
  static const double minScreenCoordinate = 0.0;
  static const double maxScreenCoordinate = 10000.0;

  // Performance Monitoring
  static const Duration performanceMonitorInterval = Duration(seconds: 1);
  static const int maxPerformanceEntries = 100;

  // Network Configuration
  static const Duration ntpTimeout = Duration(seconds: 5);
  static const int maxNtpRetries = 3;
  static const Duration networkRetryDelay = Duration(seconds: 2);

  // Theme Data
  static ThemeData get darkTheme => ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: surfaceColor,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: successColor,
          surface: surfaceColor,
          background: backgroundColor,
          error: errorColor,
          onPrimary: onPrimaryColor,
          onSecondary: onSecondaryColor,
          onSurface: onSecondaryColor,
          onBackground: onSecondaryColor,
          onError: onSecondaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: onPrimaryColor,
            minimumSize: const Size(double.infinity, buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonBorderRadius),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputBorderRadius),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(mediumSpacing),
        ),
        cardTheme: CardTheme(
          color: surfaceColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(largeRadius),
          ),
        ),
      );
}

// Extension for easier color access
extension AppColorsExtension on ColorScheme {
  Color get success => AppConstants.successColor;
  Color get warning => AppConstants.warningColor;
  Color get countdownNormal => AppConstants.countdownNormalColor;
  Color get countdownCritical => AppConstants.countdownCriticalColor;
  Color get countdownExpired => AppConstants.countdownExpiredColor;
}

// Extension for spacing
extension SpacingExtension on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}