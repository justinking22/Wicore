// lib/utilities/device_list_state.dart
import 'package:Wicore/models/device_list_response_model.dart';

class DeviceListState {
  final List<DeviceListItem> devices;
  final bool isLoading;
  final String? error;
  final bool isRefreshing;

  const DeviceListState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
    this.isRefreshing = false,
  });

  DeviceListState copyWith({
    List<DeviceListItem>? devices,
    bool? isLoading,
    String? error,
    bool? isRefreshing,
  }) {
    return DeviceListState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
