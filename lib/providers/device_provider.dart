// lib/providers/device_provider.dart - CLEANED VERSION
import 'package:Wicore/models/active_device_model.dart';
import 'package:Wicore/models/device_unpair_response_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/services/device_api_client.dart';
import 'package:Wicore/states/device_state.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/device_repository.dart';
import '../models/device_request_model.dart';
import '../models/device_response_model.dart';

// ✅ KEEP: DeviceNotifier for pairing/unpairing operations
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

        // ✅ KEEP: Invalidate the simplified providers
        _ref.invalidate(allDevicesProvider);
        _ref.invalidate(activeDeviceProvider);
      } else if (response.code == -106) {
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

        // ✅ KEEP: Invalidate the simplified providers
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

      print('🔧 DeviceNotifier - Starting unpair for device: $deviceId');

      // Call repository unpair method (returns DeviceUnpairResponse)
      final response = await _repository.unpairDevice(deviceId);

      if (response.isSuccess) {
        print('🔧 ✅ Unpair successful - Code: ${response.code}');

        // Log unpair success details if data is available
        if (response.data != null) {
          final data = response.data!;
          print(
            '🔧 📱 Device ${data.deviceId} status changed to: ${data.status}',
          );
          print('🔧 🕒 Updated at: ${data.updated}');
          print('🔧 📅 Expires: ${data.expiryDate}');

          // Verify that device is actually unpaired
          if (data.isUnpaired) {
            print('🔧 ✅ Device successfully unpaired (status: expired)');
          } else {
            print(
              '🔧 ⚠️  Warning: Device unpaired but status is: ${data.status}',
            );
          }
        }

        // Clear paired device if it matches the unpaired device
        final currentPairedDevice = _ref.read(deviceDataProvider);
        if (currentPairedDevice?.deviceId == deviceId) {
          _ref.read(deviceDataProvider.notifier).state = null;
          state = state.copyWith(pairedDevice: null);
          print('🔧 🗑️ Cleared paired device from state');
        }

        // Refresh device lists after unpairing
        _ref.invalidate(allDevicesProvider);
        _ref.invalidate(activeDeviceProvider);
        print('🔧 🔄 Invalidated device providers');

        state = state.copyWith(isLoading: false, error: null);
        return true;
      } else {
        // Handle unpair failure
        final errorMessage = response.error ?? response.msg ?? 'Unpair failed';
        print(
          '🔧 ❌ Unpair failed - Code: ${response.code}, Error: $errorMessage',
        );

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } catch (e) {
      print('🔧 ❌ Unpair exception: $e');

      // Handle authentication errors
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication expired. Please sign in again.',
        );
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }

      return false;
    }
  }

  // ✅ NEW: Helper method to get last unpair result if needed
  bool wasLastUnpairSuccessful() {
    return state.error == null && !state.isLoading;
  }

  // You can also add a method to get unpair result details if needed
  DeviceUnpairData? getLastUnpairResult() {
    // This could be stored in state if you need to access unpair details in UI
    return null; // Implement based on your needs
  }

  void clearState() {
    _ref.read(deviceDataProvider.notifier).state = null;
    state = DeviceState();
  }

  void refreshDeviceLists() {
    _ref.invalidate(allDevicesProvider);
    _ref.invalidate(activeDeviceProvider);
  }
}

// ✅ KEEP: Core infrastructure providers
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

// ✅ KEEP & UPDATE: Simplified All Devices Provider
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

// ✅ KEEP & UPDATE: Simplified Active Device Provider
final activeDeviceProvider = FutureProvider.autoDispose<ActiveDeviceData?>((
  ref,
) async {
  final apiClient = ref.watch(deviceApiClientProvider);
  final authState = ref.watch(authNotifierProvider);

  if (!authState.isAuthenticated) {
    return null;
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
      return response.data!;
    } else {
      return null;
    }
  } catch (e) {
    if (e.toString().contains('Authentication failed') ||
        e.toString().contains('401')) {
      ref.read(authNotifierProvider.notifier).setUnauthenticated();
    }
    return null;
  }
});

// ✅ KEEP: Filtered providers (simplified)
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

// ✅ KEEP: Device-specific providers (simplified)
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

// ✅ KEEP: Utility providers (simplified)
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
