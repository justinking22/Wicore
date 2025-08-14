// lib/models/device_unpair_response_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'device_unpair_response_model.g.dart';

@JsonSerializable()
class DeviceUnpairResponse {
  final DeviceUnpairData? data;
  final int code;
  final String? error;
  final String? msg;

  DeviceUnpairResponse({this.data, required this.code, this.error, this.msg});

  factory DeviceUnpairResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceUnpairResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceUnpairResponseToJson(this);

  bool get isSuccess => code == 0;

  @override
  String toString() {
    return 'DeviceUnpairResponse{code: $code, deviceId: ${data?.deviceId}, status: ${data?.status}, error: $error}';
  }
}

@JsonSerializable()
class DeviceUnpairData {
  @JsonKey(name: 'dId')
  final String deviceId;

  @JsonKey(name: 'uId')
  final String userId;

  final String status;
  final String created;
  final String updated;
  final String expiryDate;
  final int deviceStrength;
  final int offset;

  DeviceUnpairData({
    required this.deviceId,
    required this.userId,
    required this.status,
    required this.created,
    required this.updated,
    required this.expiryDate,
    required this.deviceStrength,
    required this.offset,
  });

  factory DeviceUnpairData.fromJson(Map<String, dynamic> json) =>
      _$DeviceUnpairDataFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceUnpairDataToJson(this);

  // Helper method to check if device was successfully unpaired
  bool get isUnpaired => status == 'expired';

  @override
  String toString() {
    return 'DeviceUnpairData{deviceId: $deviceId, status: $status, updated: $updated}';
  }
}
