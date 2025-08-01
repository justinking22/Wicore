// lib/providers/device_list_provider.dart
import 'package:Wicore/providers/authentication_provider.dart';
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

    // Get current user ID
    final userId = _ref.read(authNotifierProvider).userData?.id;
    if (userId == null) {
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
    );

    try {
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
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
