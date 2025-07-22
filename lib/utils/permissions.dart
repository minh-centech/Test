import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  // Required permissions for the app
  static final List<Permission> requiredPermissions = [
    Permission.systemAlertWindow, // For overlay
    // Permission.accessibilityService, // For auto-clicking (Android) - Not available in permission_handler
    Permission.notification, // For notifications
  ];

  // Optional permissions that enhance functionality
  static final List<Permission> optionalPermissions = [
    Permission.ignoreBatteryOptimizations, // For background operation
    Permission.scheduleExactAlarm, // For precise timing
  ];

  // Check if all required permissions are granted
  static Future<bool> hasAllRequiredPermissions() async {
    try {
      for (Permission permission in requiredPermissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          developer.log('Permission not granted: $permission', name: 'PermissionHelper');
          return false;
        }
      }
      return true;
    } catch (e) {
      developer.log('Error checking permissions: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Request all required permissions
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    developer.log('Requesting all required permissions', name: 'PermissionHelper');
    
    try {
      // Request required permissions
      final results = await requiredPermissions.request();
      
      // Log results
      for (var entry in results.entries) {
        developer.log('Permission ${entry.key}: ${entry.value}', name: 'PermissionHelper');
      }
      
      return results;
    } catch (e) {
      developer.log('Error requesting permissions: $e', name: 'PermissionHelper');
      return {};
    }
  }

  // Request specific permission
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      developer.log('Permission $permission: $status', name: 'PermissionHelper');
      return status;
    } catch (e) {
      developer.log('Error requesting permission $permission: $e', name: 'PermissionHelper');
      return PermissionStatus.denied;
    }
  }

  // Check overlay permission specifically
  static Future<bool> hasOverlayPermission() async {
    try {
      final status = await Permission.systemAlertWindow.status;
      return status.isGranted;
    } catch (e) {
      developer.log('Error checking overlay permission: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Request overlay permission
  static Future<bool> requestOverlayPermission() async {
    try {
      final status = await Permission.systemAlertWindow.request();
      final isGranted = status.isGranted;
      
      developer.log('Overlay permission ${isGranted ? 'granted' : 'denied'}', name: 'PermissionHelper');
      
      return isGranted;
    } catch (e) {
      developer.log('Error requesting overlay permission: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Check accessibility permission
  static Future<bool> hasAccessibilityPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // Not required on iOS
    }

    try {
      // Note: Accessibility service permission needs to be handled manually on Android
      // through system settings, not through permission_handler package
      return true; // Always return true as we can't check this permission programmatically
    } catch (e) {
      developer.log('Error checking accessibility permission: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Request accessibility permission
  static Future<bool> requestAccessibilityPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // Not required on iOS
    }

    try {
      // Note: Accessibility service permission needs to be handled manually on Android
      // User needs to enable it in Android Settings > Accessibility
      developer.log('Accessibility permission needs manual setup in Android Settings', name: 'PermissionHelper');
      return true; // Return true as we can't request this permission programmatically
    } catch (e) {
      developer.log('Error requesting accessibility permission: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Check notification permission
  static Future<bool> hasNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      developer.log('Error checking notification permission: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      final isGranted = status.isGranted;
      
      developer.log('Notification permission ${isGranted ? 'granted' : 'denied'}', name: 'PermissionHelper');
      
      return isGranted;
    } catch (e) {
      developer.log('Error requesting notification permission: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Check battery optimization exemption
  static Future<bool> hasBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      developer.log('Error checking battery optimization: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Request battery optimization exemption
  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      final isGranted = status.isGranted;
      
      developer.log('Battery optimization exemption ${isGranted ? 'granted' : 'denied'}', name: 'PermissionHelper');
      
      return isGranted;
    } catch (e) {
      developer.log('Error requesting battery optimization exemption: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Get comprehensive permission status
  static Future<Map<String, PermissionStatus>> getPermissionStatus() async {
    final Map<String, PermissionStatus> status = {};

    try {
      // Check all permissions
      final allPermissions = [...requiredPermissions, ...optionalPermissions];
      
      for (Permission permission in allPermissions) {
        try {
          status[permission.toString()] = await permission.status;
        } catch (e) {
          developer.log('Error checking permission $permission: $e', name: 'PermissionHelper');
          status[permission.toString()] = PermissionStatus.denied;
        }
      }
    } catch (e) {
      developer.log('Error getting permission status: $e', name: 'PermissionHelper');
    }

    return status;
  }

  // Check if permission is permanently denied
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      developer.log('Error checking if permission is permanently denied: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Open app settings for manually granting permissions
  static Future<bool> openAppSettings() async {
    try {
      final opened = await openAppSettings();
      developer.log('App settings ${opened ? 'opened' : 'failed to open'}', name: 'PermissionHelper');
      return opened;
    } catch (e) {
      developer.log('Error opening app settings: $e', name: 'PermissionHelper');
      return false;
    }
  }

  // Get permission description for user
  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.systemAlertWindow:
        return 'Display floating countdown overlay on top of other apps';
      // case Permission.accessibilityService:
      //   return 'Enable automatic clicking functionality';
      case Permission.notification:
        return 'Show countdown and execution notifications';
      case Permission.ignoreBatteryOptimizations:
        return 'Keep app running in background for accurate timing';
      case Permission.scheduleExactAlarm:
        return 'Schedule precise timer alarms';
      default:
        return 'Required for app functionality';
    }
  }

  // Get user-friendly permission name
  static String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.systemAlertWindow:
        return 'Overlay Permission';
      // case Permission.accessibilityService:
      //   return 'Accessibility Service';
      case Permission.notification:
        return 'Notifications';
      case Permission.ignoreBatteryOptimizations:
        return 'Battery Optimization';
      case Permission.scheduleExactAlarm:
        return 'Exact Alarms';
      default:
        return permission.toString().split('.').last;
    }
  }

  // Validate that the app can function properly
  static Future<List<String>> validateAppFunctionality() async {
    final List<String> issues = [];

    try {
      // Check critical permissions
      if (!await hasOverlayPermission()) {
        issues.add('Overlay permission required for floating countdown');
      }

      if (!await hasAccessibilityPermission()) {
        issues.add('Accessibility permission required for auto-clicking');
      }

      if (!await hasNotificationPermission()) {
        issues.add('Notification permission recommended for alerts');
      }

      // Check optional but important permissions
      if (!await hasBatteryOptimizationExemption()) {
        issues.add('Battery optimization exemption recommended for background operation');
      }

    } catch (e) {
      developer.log('Error validating app functionality: $e', name: 'PermissionHelper');
      issues.add('Unable to check all permissions');
    }

    return issues;
  }

  // Setup method to request all permissions in sequence
  static Future<bool> setupPermissions() async {
    developer.log('Starting permission setup', name: 'PermissionHelper');

    try {
      // Request required permissions first
      final requiredResults = await requestAllPermissions();
      
      // Check if all required permissions are granted
      bool allRequiredGranted = true;
      for (var entry in requiredResults.entries) {
        if (!entry.value.isGranted) {
          allRequiredGranted = false;
          break;
        }
      }

      // Request optional permissions
      for (Permission permission in optionalPermissions) {
        try {
          await requestPermission(permission);
        } catch (e) {
          developer.log('Optional permission $permission failed: $e', name: 'PermissionHelper');
        }
      }

      developer.log('Permission setup completed. All required: $allRequiredGranted', name: 'PermissionHelper');
      return allRequiredGranted;

    } catch (e) {
      developer.log('Permission setup error: $e', name: 'PermissionHelper');
      return false;
    }
  }
}