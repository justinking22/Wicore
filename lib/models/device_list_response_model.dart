// lib/models/device_list_response_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'device_list_response_model.g.dart';

@JsonSerializable()
class DeviceListResponse {
  @JsonKey(name: 'data')
  final List<DeviceListItem>? devices;

  final String? error;
  final int code;
  final String? msg;

  DeviceListResponse({this.devices, this.error, required this.code, this.msg});

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceListResponseToJson(this);

  bool get isSuccess => code == 0 && devices != null;
}

@JsonSerializable()
class DeviceListItem {
  @JsonKey(name: 'dId')
  final String deviceId;
  final String status;
  final int deviceStrength;
  final String created;
  final String updated;
  final String expiryDate;

  DeviceListItem({
    required this.deviceId,
    required this.status,
    required this.deviceStrength,
    required this.created,
    required this.updated,
    required this.expiryDate,
  });

  factory DeviceListItem.fromJson(Map<String, dynamic> json) =>
      _$DeviceListItemFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceListItemToJson(this);
}
