class ClickPosition {
  final double x;
  final double y;
  final String label;
  final bool isEnabled;

  const ClickPosition({
    required this.x,
    required this.y,
    required this.label,
    this.isEnabled = true,
  });

  ClickPosition copyWith({
    double? x,
    double? y,
    String? label,
    bool? isEnabled,
  }) {
    return ClickPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'label': label,
      'isEnabled': isEnabled,
    };
  }

  factory ClickPosition.fromJson(Map<String, dynamic> json) {
    return ClickPosition(
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      label: json['label'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClickPosition &&
        other.x == x &&
        other.y == y &&
        other.label == label &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(x, y, label, isEnabled);
  }

  @override
  String toString() {
    return 'ClickPosition(x: $x, y: $y, label: $label, enabled: $isEnabled)';
  }
}

class ClickSequence {
  final List<ClickPosition> positions;
  final int clickCount;
  final Duration clickInterval;
  final bool isEnabled;

  const ClickSequence({
    required this.positions,
    this.clickCount = 10,
    this.clickInterval = const Duration(milliseconds: 10),
    this.isEnabled = true,
  });

  ClickSequence copyWith({
    List<ClickPosition>? positions,
    int? clickCount,
    Duration? clickInterval,
    bool? isEnabled,
  }) {
    return ClickSequence(
      positions: positions ?? this.positions,
      clickCount: clickCount ?? this.clickCount,
      clickInterval: clickInterval ?? this.clickInterval,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positions': positions.map((p) => p.toJson()).toList(),
      'clickCount': clickCount,
      'clickInterval': clickInterval.inMilliseconds,
      'isEnabled': isEnabled,
    };
  }

  factory ClickSequence.fromJson(Map<String, dynamic> json) {
    return ClickSequence(
      positions: (json['positions'] as List)
          .map((p) => ClickPosition.fromJson(p))
          .toList(),
      clickCount: json['clickCount'] ?? 10,
      clickInterval: Duration(milliseconds: json['clickInterval'] ?? 10),
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  double get estimatedClicksPerSecond {
    if (clickInterval.inMilliseconds == 0) return 1000.0;
    return 1000.0 / clickInterval.inMilliseconds;
  }
}