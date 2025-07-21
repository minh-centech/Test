# Binance Auto-Clicker

A professional Flutter application for high-precision auto-clicking during Binance coin launches.

## Features

### Core Functionality
- **High-Precision Timer System** with NTP synchronization (±10ms accuracy)
- **Rapid Auto-Click System** (100+ clicks per second)
- **Floating Overlay Interface** that stays on top of other apps
- **Multiple Click Position Support** with visual position selector
- **Emergency Stop Controls** accessible at all times

### Technical Features
- Real-time countdown display with millisecond precision
- Battery-optimized background operation
- Vibration and sound feedback
- Professional dark theme matching Binance colors
- Cross-platform support (Android primary, iOS secondary)

### Performance Targets
- Timer accuracy: ±10ms precision
- Click speed: Minimum 100 clicks per second
- Memory efficient overlay mode
- Reliable background operation

## Requirements

### Minimum Requirements
- Flutter 3.10+
- Dart 3.0+
- Android 7.0+ (API 24) / iOS 12.0+
- 100MB RAM minimum
- Network connection for NTP sync

### Permissions Required
- **System Overlay** - For floating countdown display
- **Accessibility Service** - For automated clicking (Android)
- **Notifications** - For countdown alerts
- **Wake Lock** - To prevent device sleep during countdown
- **Vibration** - For haptic feedback

## Installation

### Development Setup
1. Ensure Flutter SDK is installed
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Connect device or start emulator
5. Run `flutter run` to launch

### Production Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Usage

### Basic Setup
1. **Launch the app** and grant required permissions
2. **Set target time** for the Binance coin launch
3. **Add click positions** by tapping "Add Position" and touching screen locations
4. **Configure click settings** (speed, count, feedback options)
5. **Start countdown** and optionally enable floating overlay

### Advanced Features
- **NTP Sync**: Enable for maximum timing accuracy
- **Test Mode**: Verify click positions before live use
- **Overlay Mode**: Keep countdown visible over other apps
- **Emergency Stop**: Triple-tap or use overlay button to stop immediately

### Click Position Setup
1. Go to "Positions" tab
2. Tap "Add Position"
3. Touch the screen where you want clicks to occur
4. Repeat for multiple positions
5. Use test mode to verify accuracy

## Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── timer_config.dart    # Timer configuration
│   └── click_position.dart  # Click position model
├── services/                 # Core services
│   ├── timer_service.dart   # High-precision timing
│   ├── click_service.dart   # Auto-click functionality
│   └── overlay_service.dart # Floating overlay
├── widgets/                  # UI components
│   ├── setup_screen.dart    # Main configuration UI
│   ├── countdown_display.dart # Full-screen countdown
│   ├── position_selector.dart # Click position setup
│   └── floating_overlay.dart # Overlay widget
└── utils/                    # Utilities
    ├── constants.dart       # App constants
    └── permissions.dart     # Permission management
```

### State Management
- **Provider** pattern for service management
- **ChangeNotifier** for reactive UI updates
- **Timer** for high-frequency countdown updates

### Platform Integration
- **Method Channels** for native click functionality
- **Accessibility Service** for system-level clicking (Android)
- **Overlay Window** for floating interface
- **NTP Client** for time synchronization

## Technical Details

### Timer Precision
- Uses `DateTime.now()` with NTP offset correction
- Updates every 10ms by default (configurable to 1ms)
- Fallback to system time if NTP fails
- Compensates for processing delays

### Click Implementation
- **Android**: Uses Accessibility Service for gesture simulation
- **iOS**: Uses touch simulation through native methods
- **Fallback**: Haptic feedback simulation if native fails
- **Performance**: Batched clicks for maximum speed

### Overlay System
- **Android**: Uses SYSTEM_ALERT_WINDOW permission
- **iOS**: Limited overlay support through local notifications
- **Features**: Draggable, resizable, always-on-top
- **Battery**: Optimized rendering to minimize power usage

## Security & Privacy

### Data Handling
- No personal data collection
- No network communication except NTP sync
- All configuration stored locally
- No analytics or tracking

### Permissions Justification
- **Overlay**: Required for floating countdown display
- **Accessibility**: Required for automated clicking
- **Network**: Only used for NTP time synchronization
- **Notifications**: Optional, for countdown alerts only

## Troubleshooting

### Common Issues

**App won't start clicks:**
- Verify Accessibility Service is enabled in Android Settings
- Check that click positions are configured
- Ensure countdown timer is running

**Overlay not showing:**
- Grant "Display over other apps" permission
- Check device compatibility (Android 6.0+)
- Restart app after granting permission

**Timer inaccurate:**
- Enable NTP synchronization
- Check network connection
- Verify device system time is correct

**Clicks too slow:**
- Reduce click interval in settings
- Close other apps to free resources
- Check device performance limitations

### Performance Optimization
- Close unnecessary background apps
- Enable battery optimization exemption
- Use lower precision (20-50ms) if experiencing lag
- Minimize overlay when not needed

## Development

### Dependencies
```yaml
dependencies:
  provider: ^6.1.1              # State management
  permission_handler: ^11.3.1    # Permission management
  flutter_overlay_window: ^0.4.5 # Overlay functionality
  wakelock_plus: ^1.2.5         # Keep screen awake
  ntp: ^2.0.0                   # Time synchronization
  vibration: ^1.8.4             # Haptic feedback
  audioplayers: ^6.0.0          # Sound feedback
  flutter_local_notifications: ^17.2.2 # Notifications
  shared_preferences: ^2.2.3     # Local storage
```

### Building
- Supports Android API 24+ and iOS 12.0+
- Uses Material 3 design system
- Dark theme optimized for trading environments
- Responsive design for various screen sizes

### Testing
- Unit tests for core services
- Widget tests for UI components
- Integration tests for complete workflows
- Manual testing on real devices required for clicking functionality

## Support

### Compatibility
- **Android**: 7.0+ (API 24+) - Full functionality
- **iOS**: 12.0+ - Limited overlay support
- **Devices**: Phones and tablets
- **Orientations**: Portrait and landscape

### Known Limitations
- iOS overlay functionality is limited compared to Android
- Some Android devices may restrict background services
- Click accuracy depends on device accessibility service implementation
- Battery optimization may affect background timing

## License

This project is provided for educational purposes. Users are responsible for compliance with exchange terms of service and applicable regulations.

## Disclaimer

This application is an educational tool for demonstrating Flutter capabilities. Users must ensure compliance with:
- Exchange terms of service
- Local regulations regarding automated trading tools
- Responsible use guidelines

The developers are not responsible for any consequences arising from the use of this application.