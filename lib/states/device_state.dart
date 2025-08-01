import '../models/device_response_model.dart';

class DeviceState {
  final DeviceResponseData? pairedDevice;
  final bool isLoading;
  final String? error;

  DeviceState({this.pairedDevice, this.isLoading = false, this.error});

  DeviceState copyWith({
    DeviceResponseData? pairedDevice,
    bool? isLoading,
    String? error,
  }) {
    return DeviceState(
      pairedDevice: pairedDevice ?? this.pairedDevice,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
