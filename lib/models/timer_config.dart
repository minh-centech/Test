class TimerConfig {
  final DateTime targetTime;
  final bool isNtpSynced;
  final int precisionMs;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const TimerConfig({
    required this.targetTime,
    this.isNtpSynced = true,
    this.precisionMs = 10,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  TimerConfig copyWith({
    DateTime? targetTime,
    bool? isNtpSynced,
    int? precisionMs,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return TimerConfig(
      targetTime: targetTime ?? this.targetTime,
      isNtpSynced: isNtpSynced ?? this.isNtpSynced,
      precisionMs: precisionMs ?? this.precisionMs,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetTime': targetTime.toIso8601String(),
      'isNtpSynced': isNtpSynced,
      'precisionMs': precisionMs,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory TimerConfig.fromJson(Map<String, dynamic> json) {
    return TimerConfig(
      targetTime: DateTime.parse(json['targetTime']),
      isNtpSynced: json['isNtpSynced'] ?? true,
      precisionMs: json['precisionMs'] ?? 10,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  Duration get remainingTime {
    final now = DateTime.now();
    return targetTime.difference(now);
  }

  bool get isExpired => remainingTime.isNegative;
}