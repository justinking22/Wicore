import 'package:json_annotation/json_annotation.dart';

part 'device_request_model.g.dart';

@JsonSerializable()
class DeviceRequest {
  @JsonKey(name: 'dId')
  final String deviceId;
  final int offset;

  DeviceRequest({required this.deviceId, required this.offset});

  factory DeviceRequest.fromJson(Map<String, dynamic> json) =>
      _$DeviceRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceRequestToJson(this);
}
