// lib/utilities/device_list_state.dart
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:Wicore/models/active_device_response_model.dart';

enum DeviceListType { all, active }

class DeviceListState {
  final List<dynamic>
  devices; // Can hold both DeviceListItem and ActiveDeviceListItem
  final bool isLoading;
  final String? error;
  final bool isRefreshing;
  final DeviceListType type;

  const DeviceListState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
    this.isRefreshing = false,
    this.type = DeviceListType.all,
  });

  DeviceListState copyWith({
    List<dynamic>? devices,
    bool? isLoading,
    String? error,
    bool? isRefreshing,
    DeviceListType? type,
  }) {
    return DeviceListState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      type: type ?? this.type,
    );
  }

  // Convenience getters for type-safe access
  List<DeviceListItem> get allDevices =>
      devices.whereType<DeviceListItem>().toList();

  List<ActiveDeviceListItem> get activeDevices =>
      devices.whereType<ActiveDeviceListItem>().toList();

  // Check if current list contains active devices with battery info
  bool get hasActiveDevices =>
      devices.any((device) => device is ActiveDeviceListItem);

  // Get battery levels if available
  Map<String, int> get batteryLevels {
    final Map<String, int> levels = {};
    for (final device in devices) {
      if (device is ActiveDeviceListItem) {
        levels[device.deviceId] = device.battery;
      }
    }
    return levels;
  }

  // Get devices with low battery (< 20%)
  List<ActiveDeviceListItem> get lowBatteryDevices {
    return devices
        .whereType<ActiveDeviceListItem>()
        .where((device) => device.battery < 20)
        .toList();
  }

  // Get device count by status
  Map<String, int> get deviceStatusCount {
    final Map<String, int> statusCount = {};
    for (final device in devices) {
      final status = device.status as String;
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    return statusCount;
  }

  @override
  String toString() {
    return 'DeviceListState(devices: ${devices.length}, isLoading: $isLoading, error: $error, isRefreshing: $isRefreshing, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceListState &&
        other.devices == devices &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isRefreshing == isRefreshing &&
        other.type == type;
  }

  @override
  int get hashCode {
    return devices.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        isRefreshing.hashCode ^
        type.hashCode;
  }
}
