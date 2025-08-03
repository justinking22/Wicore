// lib/providers/device_list_provider.dart
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/device_provider.dart';
import 'package:Wicore/states/device_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wicore/repository/device_repository.dart';

class DeviceListNotifier extends StateNotifier<DeviceListState> {
  final DeviceRepository _repository;
  final Ref _ref;

  DeviceListNotifier(this._repository, this._ref)
    : super(const DeviceListState());

  Future<void> loadActiveDevices({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);

    print(
      '🔧 DeviceList - Auth check - isAuthenticated: ${authState.isAuthenticated}',
    );

    // Enhanced authentication check
    if (!authState.isAuthenticated) {
      print('🔧 ❌ DeviceList authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    // Get user ID - prefer id over username, but fall back to username
    final userId = authState.userData?.id ?? authState.userData?.username;

    if (userId == null) {
      print('🔧 ❌ DeviceList - No user ID available');
      state = state.copyWith(
        error: 'No user ID available',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    print('🔧 ✅ Loading active devices for userId: $userId');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
    );

    try {
      // Ensure we have a valid token before making the request
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'No valid authentication token available',
        );
        return;
      }

      final response = await _repository.getActiveDevices(userId);

      if (response.isSuccess) {
        state = state.copyWith(
          devices: response.devices ?? [],
          isLoading: false,
          isRefreshing: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: response.msg ?? response.error ?? 'No active devices found',
        );
      }
    } catch (e) {
      print('🔧 ❌ Error loading active devices: $e');

      // Check if it's an authentication error
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Authentication failed. Please sign in again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadAllDevices({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);

    // Enhanced authentication check
    if (!authState.isAuthenticated) {
      print('🔧 ❌ DeviceList loadAll authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    // Get user ID - prefer id over username, but fall back to username
    final userId = authState.userData?.id ?? authState.userData?.username;

    if (userId == null) {
      print('🔧 ❌ DeviceList loadAll - No user ID available');
      state = state.copyWith(
        error: 'No user ID available',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    print('🔧 ✅ Loading all devices for userId: $userId');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
    );

    try {
      // Ensure we have a valid token before making the request
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'No valid authentication token available',
        );
        return;
      }

      final response = await _repository.getAllUserDevices(userId);

      if (response.isSuccess) {
        state = state.copyWith(
          devices: response.devices ?? [],
          isLoading: false,
          isRefreshing: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: response.msg ?? response.error ?? 'No devices found',
        );
      }
    } catch (e) {
      print('🔧 ❌ Error loading all devices: $e');

      // Check if it's an authentication error
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Authentication failed. Please sign in again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: e.toString(),
        );
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearState() {
    state = const DeviceListState();
  }
}

// Provider for DeviceListNotifier
final deviceListNotifierProvider =
    StateNotifierProvider<DeviceListNotifier, DeviceListState>((ref) {
      final repository = ref.watch(deviceRepositoryProvider);
      return DeviceListNotifier(repository, ref);
    });
