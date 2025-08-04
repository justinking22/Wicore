// lib/models/active_device_response_model.dart
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'active_device_response_model.g.dart';

@JsonSerializable()
class ActiveDeviceListResponse {
  @JsonKey(name: 'data')
  final List<ActiveDeviceListItem>? devices;

  final String? error;
  final int code;
  final String? msg;

  ActiveDeviceListResponse({
    this.devices,
    this.error,
    required this.code,
    this.msg,
  });

  factory ActiveDeviceListResponse.fromJson(Map<String, dynamic> json) =>
      _$ActiveDeviceListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveDeviceListResponseToJson(this);

  bool get isSuccess => code == 0 && devices != null;
}

@JsonSerializable()
class ActiveDeviceListItem {
  @JsonKey(name: 'dId')
  final String deviceId;
  final String status;
  final int deviceStrength;
  final String created;
  final String updated;
  final String expiryDate;
  final int battery; // Additional field for active devices

  ActiveDeviceListItem({
    required this.deviceId,
    required this.status,
    required this.deviceStrength,
    required this.created,
    required this.updated,
    required this.expiryDate,
    required this.battery,
  });

  factory ActiveDeviceListItem.fromJson(Map<String, dynamic> json) =>
      _$ActiveDeviceListItemFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveDeviceListItemToJson(this);

  // Convenience method to convert to regular DeviceListItem if needed
  DeviceListItem toDeviceListItem() {
    return DeviceListItem(
      deviceId: deviceId,
      status: status,
      deviceStrength: deviceStrength,
      created: created,
      updated: updated,
      expiryDate: expiryDate,
    );
  }
}
