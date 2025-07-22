import 'package:flutter_test/flutter_test.dart';
import 'package:binance_auto_clicker/models/timer_config.dart';
import 'package:binance_auto_clicker/models/click_position.dart';
import 'package:binance_auto_clicker/services/timer_service.dart';
import 'package:binance_auto_clicker/services/click_service.dart';

void main() {
  group('Timer Configuration Tests', () {
    test('Timer config creation and serialization', () {
      final targetTime = DateTime.now().add(const Duration(minutes: 5));
      final config = TimerConfig(
        targetTime: targetTime,
        isNtpSynced: true,
        precisionMs: 10,
        soundEnabled: true,
        vibrationEnabled: true,
      );

      expect(config.targetTime, equals(targetTime));
      expect(config.isNtpSynced, isTrue);
      expect(config.precisionMs, equals(10));
      expect(config.soundEnabled, isTrue);
      expect(config.vibrationEnabled, isTrue);

      // Test serialization
      final json = config.toJson();
      final deserializedConfig = TimerConfig.fromJson(json);
      
      expect(deserializedConfig.targetTime, equals(config.targetTime));
      expect(deserializedConfig.isNtpSynced, equals(config.isNtpSynced));
      expect(deserializedConfig.precisionMs, equals(config.precisionMs));
    });

    test('Timer expiration check', () {
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));
      final config = TimerConfig(targetTime: pastTime);
      
      expect(config.isExpired, isTrue);
      expect(config.remainingTime.isNegative, isTrue);
    });
  });

  group('Click Position Tests', () {
    test('Click position creation and properties', () {
      const position = ClickPosition(
        x: 100.0,
        y: 200.0,
        label: 'Test Position',
        isEnabled: true,
      );

      expect(position.x, equals(100.0));
      expect(position.y, equals(200.0));
      expect(position.label, equals('Test Position'));
      expect(position.isEnabled, isTrue);
    });

    test('Click sequence configuration', () {
      const positions = [
        ClickPosition(x: 100, y: 100, label: 'Position 1'),
        ClickPosition(x: 200, y: 200, label: 'Position 2'),
      ];

      const sequence = ClickSequence(
        positions: positions,
        clickCount: 10,
        clickInterval: Duration(milliseconds: 10),
      );

      expect(sequence.positions.length, equals(2));
      expect(sequence.clickCount, equals(10));
      expect(sequence.clickInterval.inMilliseconds, equals(10));
      expect(sequence.estimatedClicksPerSecond, equals(100.0));
    });
  });

  group('Service Tests', () {
    test('Timer service initialization', () {
      final timerService = TimerService();
      
      expect(timerService.isActive, isFalse);
      expect(timerService.isSyncing, isFalse);
      expect(timerService.isNtpSynced, isFalse);
      expect(timerService.remainingTime, equals(Duration.zero));
    });

    test('Click service initialization', () {
      final clickService = ClickService();
      
      expect(clickService.isExecuting, isFalse);
      expect(clickService.isTestMode, isFalse);
      expect(clickService.executedClicks, equals(0));
      expect(clickService.activeSequence, isNull);
    });

    test('Timer formatting', () {
      final timerService = TimerService();
      
      // Mock remaining time for testing
      final config = TimerConfig(
        targetTime: DateTime.now().add(const Duration(
          hours: 1,
          minutes: 30,
          seconds: 45,
          milliseconds: 123,
        )),
      );
      
      timerService.configure(config);
      
      final formatted = timerService.formatRemainingTime(showMilliseconds: true);
      expect(formatted, matches(RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}$')));
      
      final formattedNoMs = timerService.formatRemainingTime(showMilliseconds: false);
      expect(formattedNoMs, matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
    });
  });

  group('Click Performance Tests', () {
    test('Click speed calculations', () {
      const sequence = ClickSequence(
        positions: [ClickPosition(x: 0, y: 0, label: 'Test')],
        clickCount: 10,
        clickInterval: Duration(milliseconds: 5),
      );

      expect(sequence.estimatedClicksPerSecond, equals(200.0));
    });

    test('Multiple position sequence', () {
      final positions = List.generate(5, (index) => 
        ClickPosition(x: index * 100.0, y: index * 100.0, label: 'Pos $index')
      );

      final sequence = ClickSequence(positions: positions);
      
      expect(sequence.positions.length, equals(5));
      expect(sequence.positions.every((p) => p.isEnabled), isTrue);
    });
  });

  group('Integration Tests', () {
    test('Complete workflow simulation', () {
      // Create timer configuration
      final targetTime = DateTime.now().add(const Duration(seconds: 30));
      final timerConfig = TimerConfig(targetTime: targetTime);
      
      // Create click sequence
      const clickSequence = ClickSequence(
        positions: [
          ClickPosition(x: 500, y: 500, label: 'Buy Button'),
          ClickPosition(x: 600, y: 600, label: 'Confirm Button'),
        ],
        clickCount: 5,
        clickInterval: Duration(milliseconds: 20),
      );
      
      // Initialize services
      final timerService = TimerService();
      final clickService = ClickService();
      
      // Configure services
      timerService.configure(timerConfig);
      clickService.configureSequence(clickSequence);
      
      // Verify configuration
      expect(timerService.config, isNotNull);
      expect(clickService.activeSequence, isNotNull);
      expect(clickService.activeSequence!.positions.length, equals(2));
      expect(clickService.getMaxClicksPerSecond(), equals(50.0));
    });
  });
}