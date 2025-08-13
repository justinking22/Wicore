// lib/models/device_list_response_model.dart - FIXED
import 'package:json_annotation/json_annotation.dart';

part 'device_list_response_model.g.dart';

@JsonSerializable()
class DeviceListResponse {
  final List<DeviceListItem>? data;
  final int code;
  final String? error;
  final String? msg;

  DeviceListResponse({this.data, required this.code, this.error, this.msg});

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceListResponseToJson(this);

  bool get isSuccess => code == 0;

  // For backward compatibility
  List<DeviceListItem>? get devices => data;

  @override
  String toString() {
    return 'DeviceListResponse{code: $code, devices: ${data?.length}, error: $error}';
  }
}

@JsonSerializable()
class DeviceListItem {
  @JsonKey(name: 'dId')
  final String deviceId;
  final String status;
  final String created;
  final String updated;
  final String expiryDate;
  final int deviceStrength;
  final int offset;
  @JsonKey(name: 'uId')
  final String userId;

  DeviceListItem({
    required this.deviceId,
    required this.status,
    required this.created,
    required this.updated,
    required this.expiryDate,
    required this.deviceStrength,
    required this.offset,
    required this.userId,
  });

  factory DeviceListItem.fromJson(Map<String, dynamic> json) =>
      _$DeviceListItemFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceListItemToJson(this);

  @override
  String toString() {
    return 'DeviceListItem{deviceId: $deviceId, status: $status, strength: $deviceStrength}';
  }
}
