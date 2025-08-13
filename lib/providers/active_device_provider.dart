import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wicore/models/active_device_model.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/services/device_api_client.dart';
import 'package:Wicore/repository/device_repository.dart';
import 'package:Wicore/states/device_state.dart';
import 'package:Wicore/models/device_request_model.dart';
import 'package:Wicore/models/device_response_model.dart';

// KEEP your existing DeviceNotifier for pairing/unpairing
class DeviceNotifier extends StateNotifier<DeviceState> {
  final DeviceRepository _repository;
  final Ref _ref;

  DeviceNotifier(this._repository, this._ref) : super(DeviceState());

  Future<void> pairDevice(String deviceId, int offset) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication required. Please sign in again.',
        );
        return;
      }

      final response = await _repository.registerDevice(
        DeviceRequest(deviceId: deviceId, offset: offset),
      );

      if (response.code == 0 && response.data != null) {
        _ref.read(deviceDataProvider.notifier).state = response.data;
        state = state.copyWith(pairedDevice: response.data, isLoading: false);

        // Refresh device lists after pairing
        _ref.invalidate(allDevicesProvider);
        _ref.invalidate(activeDeviceProvider);
      } else if (response.code == -106) {
        // Device already paired
        final deviceData = DeviceResponseData(
          deviceId: deviceId,
          offset: offset,
          userId: '',
          expiryDate: '',
          status: 'active',
          deviceStrength: 0,
          created: DateTime.now().toIso8601String(),
          updated: DateTime.now().toIso8601String(),
        );

        _ref.read(deviceDataProvider.notifier).state = deviceData;
        state = state.copyWith(pairedDevice: deviceData, isLoading: false);

        // Refresh device lists after pairing
        _ref.invalidate(allDevicesProvider);
        _ref.invalidate(activeDeviceProvider);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.msg ?? response.error ?? 'Pairing failed',
        );
      }
    } catch (e) {
      if (e.toString().contains('Authentication failed')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> unpairDevice(String deviceId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication required. Please sign in again.',
        );
        return false;
      }

      final response = await _repository.unpairDevice(deviceId);

      if (response.code == 0) {
        final currentPairedDevice = _ref.read(deviceDataProvider);
        if (currentPairedDevice?.deviceId == deviceId) {
          _ref.read(deviceDataProvider.notifier).state = null;
          state = state.copyWith(pairedDevice: null);
        }

        // Refresh device lists after unpairing
        _ref.invalidate(allDevicesProvider);
        _ref.invalidate(activeDeviceProvider);

        state = state.copyWith(isLoading: false, error: null);
        return true;
      } else {
        final errorMessage = response.error ?? response.msg ?? 'Unpair failed';
        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } catch (e) {
      if (e.toString().contains('Authentication failed')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
      }

      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearState() {
    _ref.read(deviceDataProvider.notifier).state = null;
    state = DeviceState();
  }
}

// Core Providers
final deviceApiClientProvider = Provider<DeviceApiClient>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return DeviceApiClient(dio);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final apiClient = ref.watch(deviceApiClientProvider);
  return DeviceRepository(apiClient);
});

final deviceNotifierProvider =
    StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
      final repository = ref.watch(deviceRepositoryProvider);
      return DeviceNotifier(repository, ref);
    });

final deviceDataProvider = StateProvider<DeviceResponseData?>((ref) => null);

// SIMPLIFIED: All Devices Provider (from /device/all)
final allDevicesProvider = FutureProvider.autoDispose<List<DeviceListItem>>((
  ref,
) async {
  final apiClient = ref.watch(deviceApiClientProvider);
  final authState = ref.watch(authNotifierProvider);

  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }

  final userId = authState.userData?.id ?? authState.userData?.username;
  if (userId == null) {
    throw Exception('No user ID available');
  }

  final authNotifier = ref.read(authNotifierProvider.notifier);
  final token = await authNotifier.getValidToken();
  if (token == null) {
    throw Exception('No valid authentication token available');
  }

  try {
    final response = await apiClient.getAllDevices(userId: userId);

    if (response.isSuccess && response.data != null) {
      print('🔧 ✅ Loaded ${response.data!.length} devices from /device/all');
      return response.data!;
    } else {
      print('🔧 ❌ Failed to load devices: ${response.error}');
      throw Exception(response.error ?? 'Failed to fetch devices');
    }
  } catch (e) {
    if (e.toString().contains('Authentication failed') ||
        e.toString().contains('401')) {
      ref.read(authNotifierProvider.notifier).setUnauthenticated();
    }
    rethrow;
  }
});

// SIMPLIFIED: Active Device Provider (from /device/active)
final activeDeviceProvider = FutureProvider.autoDispose<ActiveDeviceData?>((
  ref,
) async {
  final apiClient = ref.watch(deviceApiClientProvider);
  final authState = ref.watch(authNotifierProvider);

  if (!authState.isAuthenticated) {
    return null; // Return null instead of throwing for better UX
  }

  final userId = authState.userData?.id ?? authState.userData?.username;
  if (userId == null) {
    return null;
  }

  final authNotifier = ref.read(authNotifierProvider.notifier);
  final token = await authNotifier.getValidToken();
  if (token == null) {
    return null;
  }

  try {
    final response = await apiClient.getActiveDevices(userId: userId);

    if (response.isSuccess && response.data != null) {
      print('🔧 ✅ Loaded active device: ${response.data!.safeDeviceId}');
      print(
        '🔧 📱 Battery: ${response.data!.batteryLevel}% - Signal: ${response.data!.signalStrength}',
      );
      return response.data!;
    } else {
      print('🔧 ❌ No active device found or error: ${response.error}');
      return null;
    }
  } catch (e) {
    if (e.toString().contains('Authentication failed') ||
        e.toString().contains('401')) {
      ref.read(authNotifierProvider.notifier).setUnauthenticated();
    }
    print('🔧 ❌ Error fetching active device: $e');
    return null;
  }
});

// Filtered Providers
final activeDevicesFromAllProvider = Provider<AsyncValue<List<DeviceListItem>>>(
  (ref) {
    final allDevicesAsync = ref.watch(allDevicesProvider);
    return allDevicesAsync.when(
      data:
          (devices) => AsyncValue.data(
            devices.where((device) => device.status == 'active').toList(),
          ),
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    );
  },
);

final expiredDevicesProvider = Provider<AsyncValue<List<DeviceListItem>>>((
  ref,
) {
  final allDevicesAsync = ref.watch(allDevicesProvider);
  return allDevicesAsync.when(
    data:
        (devices) => AsyncValue.data(
          devices.where((device) => device.status == 'expired').toList(),
        ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Device-specific Providers
final deviceByIdProvider = Provider.family<AsyncValue<DeviceListItem?>, String>(
  (ref, deviceId) {
    final allDevicesAsync = ref.watch(allDevicesProvider);
    return allDevicesAsync.when(
      data: (devices) {
        try {
          final device = devices.firstWhere((d) => d.deviceId == deviceId);
          return AsyncValue.data(device);
        } catch (e) {
          return const AsyncValue.data(null);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    );
  },
);

final deviceBatteryProvider = Provider.family<AsyncValue<int?>, String>((
  ref,
  deviceId,
) {
  final activeDeviceAsync = ref.watch(activeDeviceProvider);
  return activeDeviceAsync.when(
    data: (activeDevice) {
      if (activeDevice?.safeDeviceId == deviceId) {
        return AsyncValue.data(activeDevice!.batteryLevel);
      }
      return const AsyncValue.data(null);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final deviceSignalProvider = Provider.family<AsyncValue<int?>, String>((
  ref,
  deviceId,
) {
  final activeDeviceAsync = ref.watch(activeDeviceProvider);
  return activeDeviceAsync.when(
    data: (activeDevice) {
      if (activeDevice?.safeDeviceId == deviceId) {
        return AsyncValue.data(activeDevice!.signalStrength);
      }
      return const AsyncValue.data(null);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Utility Providers
final deviceStatusCountProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final allDevicesAsync = ref.watch(allDevicesProvider);
  return allDevicesAsync.when(
    data: (devices) {
      final statusCount = <String, int>{};
      for (final device in devices) {
        statusCount[device.status] = (statusCount[device.status] ?? 0) + 1;
      }
      return AsyncValue.data(statusCount);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final lowBatteryDeviceProvider = Provider<AsyncValue<bool>>((ref) {
  final activeDeviceAsync = ref.watch(activeDeviceProvider);
  return activeDeviceAsync.when(
    data: (activeDevice) {
      if (activeDevice != null) {
        return AsyncValue.data(activeDevice.batteryLevel < 20);
      }
      return const AsyncValue.data(false);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
