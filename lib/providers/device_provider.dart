import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/services/device_api_client.dart';
import 'package:Wicore/states/device_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/device_repository.dart';
import '../models/device_request_model.dart';
import '../models/device_response_model.dart';

class DeviceNotifier extends StateNotifier<DeviceState> {
  final DeviceRepository _repository;
  final Ref _ref; // Add Ref to access other providers

  DeviceNotifier(this._repository, this._ref) : super(DeviceState());

  Future<void> pairDevice(String deviceId, int offset) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.registerDevice(
        DeviceRequest(deviceId: deviceId, offset: offset),
      );

      if (response.code == 0 && response.data != null) {
        // Update the device data provider
        _ref.read(deviceDataProvider.notifier).state = response.data;

        state = state.copyWith(pairedDevice: response.data, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.msg ?? response.error ?? 'Pairing failed',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearState() {
    // Clear both state and device data provider
    _ref.read(deviceDataProvider.notifier).state = null;
    state = DeviceState();
  }
}

// Add to your existing providers
final deviceApiClientProvider = Provider<DeviceApiClient>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  print('Creating DeviceApiClient with baseUrl: ${dio.options.baseUrl}');
  return DeviceApiClient(dio);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final apiClient = ref.watch(deviceApiClientProvider);
  return DeviceRepository(apiClient);
});

final deviceNotifierProvider =
    StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
      final repository = ref.watch(deviceRepositoryProvider);
      // Pass ref to DeviceNotifier
      return DeviceNotifier(repository, ref);
    });

// Provider to access individual device data parameters
final deviceDataProvider = StateProvider<DeviceResponseData?>((ref) => null);
