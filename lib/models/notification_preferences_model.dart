// lib/models/notification_preferences_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences_model.g.dart';

@JsonSerializable()
class NotificationPreferences {
  @JsonKey(defaultValue: null, includeIfNull: false)
  final bool? lowBattery;

  @JsonKey(defaultValue: null, includeIfNull: false)
  final bool? deviceDisconnected;

  @JsonKey(defaultValue: null, includeIfNull: false)
  final bool? fallDetection;

  const NotificationPreferences({
    this.lowBattery,
    this.deviceDisconnected,
    this.fallDetection,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  // Helper method to create from UI state
  factory NotificationPreferences.fromUI({
    bool? batteryLow,
    bool? connectionDisabled,
    bool? userFallConfirmed,
  }) {
    return NotificationPreferences(
      lowBattery: batteryLow,
      deviceDisconnected: connectionDisabled,
      fallDetection: userFallConfirmed,
    );
  }

  bool get isEmpty =>
      lowBattery == null && deviceDisconnected == null && fallDetection == null;

  @override
  String toString() {
    return 'NotificationPreferences(lowBattery: $lowBattery, deviceDisconnected: $deviceDisconnected, fallDetection: $fallDetection)';
  }
}
