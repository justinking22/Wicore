import 'package:json_annotation/json_annotation.dart';

part 'active_device_model.g.dart';

@JsonSerializable()
class ActiveDeviceResponse {
  final ActiveDeviceData? data;
  final String? error;
  final int? code;
  final String? msg;

  ActiveDeviceResponse({this.data, this.error, this.code, this.msg});

  factory ActiveDeviceResponse.fromJson(Map<String, dynamic> json) =>
      _$ActiveDeviceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveDeviceResponseToJson(this);

  bool get isSuccess => code == 0 || (code == null && error == null);
}

@JsonSerializable()
class ActiveDeviceData {
  final String? updated;
  final String? expiryDate;
  final String? status;
  final String? created;
  final int? offset;
  @JsonKey(name: 'uId')
  final String? userId;
  final int? deviceStrength;
  @JsonKey(name: 'dId')
  final String? deviceId;
  final int? battery;
  final DeviceLocation? location;

  ActiveDeviceData({
    this.updated,
    this.expiryDate,
    this.status,
    this.created,
    this.offset,
    this.userId,
    this.deviceStrength,
    this.deviceId,
    this.battery,
    this.location,
  });

  factory ActiveDeviceData.fromJson(Map<String, dynamic> json) =>
      _$ActiveDeviceDataFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveDeviceDataToJson(this);

  String get safeDeviceId => deviceId ?? '';
  String get safeStatus => status ?? 'unknown';
  int get batteryLevel => battery ?? 0;
  int get signalStrength => deviceStrength ?? 0;
  String get safeUserId => userId ?? '';
}

@JsonSerializable()
class DeviceLocation {
  final double? latitude;
  final double? longitude;

  DeviceLocation({this.latitude, this.longitude});

  factory DeviceLocation.fromJson(Map<String, dynamic> json) =>
      _$DeviceLocationFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceLocationToJson(this);
}
