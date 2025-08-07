// lib/models/active_device_response_model.dart
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'active_device_response_model.g.dart';

@JsonSerializable()
class ActiveDeviceListResponse {
  // ✅ FIXED: Make data dynamic to handle both single object and array
  @JsonKey(name: 'data')
  final dynamic data; // Can be Map<String, dynamic> or List<dynamic>

  final String? error;
  final int code;
  final String? msg;

  ActiveDeviceListResponse({
    this.data,
    this.error,
    required this.code,
    this.msg,
  });

  factory ActiveDeviceListResponse.fromJson(Map<String, dynamic> json) =>
      _$ActiveDeviceListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveDeviceListResponseToJson(this);

  bool get isSuccess => code == 0 && data != null;

  // ✅ NEW: Helper method to get devices as list
  List<ActiveDeviceListItem>? get devices {
    if (data == null) return null;

    try {
      if (data is Map<String, dynamic>) {
        // API returned a single device object
        final device = ActiveDeviceListItem.fromJson(
          data as Map<String, dynamic>,
        );
        return [device];
      } else if (data is List<dynamic>) {
        // API returned an array of devices
        return (data as List<dynamic>)
            .map(
              (json) =>
                  ActiveDeviceListItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        print(
          '🔧 ⚠️ ActiveDeviceListResponse - Unexpected data format: ${data.runtimeType}',
        );
        return null;
      }
    } catch (e) {
      print('🔧 ❌ Error parsing active device data: $e');
      return null;
    }
  }
}

@JsonSerializable()
class ActiveDeviceListItem {
  @JsonKey(name: 'dId')
  final String deviceId;

  @JsonKey(name: 'status', defaultValue: 'unknown')
  final String status;

  @JsonKey(name: 'deviceStrength', defaultValue: 0)
  final int deviceStrength;

  @JsonKey(name: 'created', defaultValue: '')
  final String created;

  @JsonKey(name: 'updated', defaultValue: '')
  final String updated;

  @JsonKey(name: 'expiryDate', defaultValue: '')
  final String expiryDate;

  @JsonKey(name: 'battery', defaultValue: 0)
  final int battery; // Additional field for active devices

  @JsonKey(name: 'uId')
  final String? userId;

  @JsonKey(name: 'offset', defaultValue: 0)
  final int offset;

  @JsonKey(name: 'location')
  final Map<String, dynamic>? location;

  ActiveDeviceListItem({
    required this.deviceId,
    this.status = 'unknown',
    this.deviceStrength = 0,
    this.created = '',
    this.updated = '',
    this.expiryDate = '',
    this.battery = 0,
    this.userId,
    this.offset = 0,
    this.location,
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
