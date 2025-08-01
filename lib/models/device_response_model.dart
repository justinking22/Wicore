import 'package:json_annotation/json_annotation.dart';

part 'device_response_model.g.dart';

@JsonSerializable()
class DeviceResponse {
  final DeviceResponseData? data;
  final String? error;
  final String? msg;
  final int code;

  DeviceResponse({this.data, this.error, this.msg, required this.code});

  factory DeviceResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceResponseToJson(this);
}

@JsonSerializable()
class DeviceResponseData {
  @JsonKey(name: 'dId')
  final String deviceId;
  final int offset;
  @JsonKey(name: 'uId')
  final String userId;
  final String expiryDate;
  final String status;
  final int deviceStrength;
  final String created;
  final String updated;

  DeviceResponseData({
    required this.deviceId,
    required this.offset,
    required this.userId,
    required this.expiryDate,
    required this.status,
    required this.deviceStrength,
    required this.created,
    required this.updated,
  });

  factory DeviceResponseData.fromJson(Map<String, dynamic> json) =>
      _$DeviceResponseDataFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceResponseDataToJson(this);
}
