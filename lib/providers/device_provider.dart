import 'package:Wicore/models/active_device_response_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/services/device_api_client.dart';
import 'package:Wicore/states/device_state.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/device_repository.dart';
import '../models/device_request_model.dart';
import '../models/device_response_model.dart';

class DeviceNotifier extends StateNotifier<DeviceState> {
  final DeviceRepository _repository;
  final Ref _ref;

  DeviceNotifier(this._repository, this._ref) : super(DeviceState());

  Future<void> pairDevice(String deviceId, int offset) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check authentication before proceeding
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

        // Invalidate device lists to refresh them after pairing
        _ref.invalidate(allUserDevicesProvider);
        _ref.invalidate(activeDevicesProvider);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.msg ?? response.error ?? 'Pairing failed',
        );
      }
    } catch (e) {
      // Check if it's an authentication error
      if (e.toString().contains('Authentication failed')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearState() {
    _ref.read(deviceDataProvider.notifier).state = null;
    state = DeviceState();
  }

  void refreshDeviceLists() {
    _ref.invalidate(allUserDevicesProvider);
    _ref.invalidate(activeDevicesProvider);
  }
}

// Your existing providers
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
      return DeviceNotifier(repository, ref);
    });

final deviceDataProvider = StateProvider<DeviceResponseData?>((ref) => null);

// Enhanced provider for getting all user devices with better error handling
final allUserDevicesProvider = FutureProvider.autoDispose<DeviceListResponse>((
  ref,
) async {
  final apiClient = ref.watch(deviceApiClientProvider);
  final authState = ref.watch(authNotifierProvider);

  print('🔧 Auth check - isAuthenticated: ${authState.isAuthenticated}');
  print('🔧 Auth check - username: ${authState.userData?.username}');

  // Enhanced authentication check
  if (!authState.isAuthenticated) {
    print('🔧 ❌ User not authenticated');
    throw Exception('User not authenticated');
  }

  // Get user ID - prefer id over username, but fall back to username
  final userId = authState.userData?.id ?? authState.userData?.username;

  if (userId == null) {
    print('🔧 ❌ No user ID available');
    throw Exception('No user ID available');
  }

  print('🔧 ✅ Fetching all devices for userId: $userId');

  try {
    // Ensure we have a valid token before making the request
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final token = await authNotifier.getValidToken();

    if (token == null) {
      throw Exception('No valid authentication token available');
    }

    return await apiClient.getAllDevices(userId: userId);
  } catch (e) {
    print('🔧 ❌ Error fetching all devices: $e');

    // If it's an auth error, trigger sign out
    if (e.toString().contains('Authentication failed') ||
        e.toString().contains('401')) {
      ref.read(authNotifierProvider.notifier).setUnauthenticated();
    }

    rethrow;
  }
});

// Provider for just the device list data from all devices endpoint
final userDeviceListProvider = FutureProvider.autoDispose<
  List<DeviceListItem>
>((ref) async {
  print('🔧 userDeviceListProvider called');

  try {
    final response = await ref.watch(allUserDevicesProvider.future);

    if (response.isSuccess && response.devices != null) {
      print(
        '🔧 ✅ userDeviceListProvider - ${response.devices!.length} devices found',
      );
      return response.devices!;
    }

    print('🔧 ❌ userDeviceListProvider - Failed: ${response.error}');
    throw Exception(response.error ?? 'Failed to fetch devices');
  } catch (e) {
    print('🔧 ❌ userDeviceListProvider error: $e');
    rethrow;
  }
});

// Provider for active user devices only (filtered from all devices)
final activeUserDevicesProvider =
    FutureProvider.autoDispose<List<DeviceListItem>>((ref) async {
      final devices = await ref.watch(userDeviceListProvider.future);
      return devices.where((device) => device.status == 'active').toList();
    });

// Provider for expired user devices only
final expiredUserDevicesProvider =
    FutureProvider.autoDispose<List<DeviceListItem>>((ref) async {
      final devices = await ref.watch(userDeviceListProvider.future);
      return devices.where((device) => device.status == 'expired').toList();
    });

// Provider for device count by status
final deviceStatusCountProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final devices = await ref.watch(userDeviceListProvider.future);
  final statusCount = <String, int>{};

  for (final device in devices) {
    statusCount[device.status] = (statusCount[device.status] ?? 0) + 1;
  }

  return statusCount;
});

// Enhanced provider for active devices using existing /device/active endpoint

// Helper provider to clear device data when user signs out
final deviceAuthStateListener = Provider<void>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
    if (!next && previous == null) {
      // User just signed out, clear device data
      ref.read(deviceNotifierProvider.notifier).clearState();
      ref.invalidate(allUserDevicesProvider);
      ref.invalidate(activeDevicesProvider);
    }
  });

  return;
});
final activeDevicesProvider = FutureProvider.autoDispose<
  ActiveDeviceListResponse
>((ref) async {
  final apiClient = ref.watch(deviceApiClientProvider);
  final authState = ref.watch(authNotifierProvider);

  print(
    '🔧 Active devices - Auth check - isAuthenticated: ${authState.isAuthenticated}',
  );

  if (!authState.isAuthenticated) {
    print('🔧 ❌ Active devices authentication failed');
    throw Exception('User not authenticated');
  }

  final userId = authState.userData?.id ?? authState.userData?.username;

  if (userId == null) {
    print('🔧 ❌ No user ID available for active devices');
    throw Exception('No user ID available');
  }

  print('🔧 ✅ Fetching active devices for userId: $userId');

  try {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final token = await authNotifier.getValidToken();

    if (token == null) {
      throw Exception('No valid authentication token available');
    }

    return await apiClient.getActiveDevices(userId: userId);
  } catch (e) {
    print('🔧 ❌ Error fetching active devices: $e');

    if (e.toString().contains('Authentication failed') ||
        e.toString().contains('401')) {
      ref.read(authNotifierProvider.notifier).setUnauthenticated();
    }

    rethrow;
  }
});

// Provider for just the active device list data with battery info
final activeDeviceListProvider = FutureProvider.autoDispose<
  List<ActiveDeviceListItem>
>((ref) async {
  print('🔧 activeDeviceListProvider called');

  try {
    final response = await ref.watch(activeDevicesProvider.future);

    if (response.isSuccess && response.devices != null) {
      print(
        '🔧 ✅ activeDeviceListProvider - ${response.devices!.length} active devices found',
      );
      return response.devices!;
    }

    print('🔧 ❌ activeDeviceListProvider - Failed: ${response.error}');
    throw Exception(response.error ?? 'Failed to fetch active devices');
  } catch (e) {
    print('🔧 ❌ activeDeviceListProvider error: $e');
    rethrow;
  }
});

// Provider for battery levels of active devices
final deviceBatteryLevelsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      final activeDevices = await ref.watch(activeDeviceListProvider.future);
      final batteryLevels = <String, int>{};

      for (final device in activeDevices) {
        batteryLevels[device.deviceId] = device.battery;
      }

      return batteryLevels;
    });

// Provider for low battery devices (battery < 20%)
final lowBatteryDevicesProvider =
    FutureProvider.autoDispose<List<ActiveDeviceListItem>>((ref) async {
      final activeDevices = await ref.watch(activeDeviceListProvider.future);
      return activeDevices.where((device) => device.battery < 20).toList();
    });
