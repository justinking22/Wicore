// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    NotificationPreferences(
      lowBattery: json['lowBattery'] as bool?,
      deviceDisconnected: json['deviceDisconnected'] as bool?,
      fallDetection: json['fallDetection'] as bool?,
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
    NotificationPreferences instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('lowBattery', instance.lowBattery);
  writeNotNull('deviceDisconnected', instance.deviceDisconnected);
  writeNotNull('fallDetection', instance.fallDetection);
  return val;
}
