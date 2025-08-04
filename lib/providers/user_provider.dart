// lib/providers/user_provider.dart (Corrected type mismatch)
import 'package:Wicore/models/user_response_model.dart';
import 'package:Wicore/models/user_request_model.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/repository/user_repository.dart';
import 'package:Wicore/services/user_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// User API client provider using authenticated Dio
final userApiClientProvider = Provider<UserApiClient>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return UserApiClient(dio);
});

// User state notifier - CORRECTED
class UserNotifier extends StateNotifier<AsyncValue<UserResponse?>> {
  final UserRepository _repository;
  final Ref _ref;

  UserNotifier(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> createUser(UserRequest request) async {
    state = const AsyncValue.loading();
    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final response = await _repository.createUser(request);
      state = AsyncValue.data(response);

      print('🔧 ✅ UserNotifier - User created successfully');
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error creating user: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> getUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final response = await _repository.getUser(userId);
      state = AsyncValue.data(response);

      print('🔧 ✅ UserNotifier - User retrieved successfully');
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error getting user: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // FIXED: Changed from UserRequest to UserUpdateRequest
  Future<void> updateUser(String userId, UserUpdateRequest request) async {
    state = const AsyncValue.loading();
    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final response = await _repository.updateUser(userId, request);
      state = AsyncValue.data(response);

      print('🔧 ✅ UserNotifier - User updated successfully');
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error updating user: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final response = await _repository.deleteUser(userId);
      state = AsyncValue.data(response);

      print('🔧 ✅ UserNotifier - User deleted successfully');
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error deleting user: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> getCurrentUserProfile() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authNotifierProvider);
      final authNotifier = _ref.read(authNotifierProvider.notifier);

      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final userData = authState.userData;
      if (userData?.id == null && userData?.username == null) {
        throw Exception('No user ID available');
      }

      final userId = userData?.id ?? userData?.username ?? '';
      final response = await _repository.getUser(userId);
      state = AsyncValue.data(response);

      print('🔧 ✅ UserNotifier - Current user profile loaded');
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error getting current user profile: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // FIXED: Changed from UserRequest to UserUpdateRequest
  Future<void> updateCurrentUserProfile(UserUpdateRequest request) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authNotifierProvider);
      final authNotifier = _ref.read(authNotifierProvider.notifier);

      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final userData = authState.userData;
      if (userData?.id == null && userData?.username == null) {
        throw Exception('No user ID available');
      }

      final userId = userData?.id ?? userData?.username ?? '';
      final response = await _repository.updateUser(userId, request);
      state = AsyncValue.data(response);

      print('🔧 ✅ UserNotifier - Current user profile updated');
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error updating current user profile: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // NEW: Convenience method to update specific fields
  Future<void> updateCurrentUserFields({
    String? firstName,
    String? lastName,
    int? age,
    int? deviceStrength,
  }) async {
    final updateRequest = UserUpdateRequest(
      firstName: firstName,
      lastName: lastName,
      age: age,
      deviceStrength: deviceStrength,
    );

    await updateCurrentUserProfile(updateRequest);
  }

  // NEW: Convenience method to update from existing UserItem
  Future<void> updateFromUserItem(
    UserItem userItem, {
    int? deviceStrength,
  }) async {
    final updateRequest = UserUpdateRequest.fromUserItem(
      userItem,
      deviceStrength: deviceStrength,
    );

    await updateCurrentUserProfile(updateRequest);
  }

  void clearState() {
    state = const AsyncValue.data(null);
  }
}

// User state provider
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserResponse?>>((ref) {
      final repository = ref.read(userRepositoryProvider);
      return UserNotifier(repository, ref);
    });

// Convenience provider to get current user profile
final currentUserProfileProvider = Provider<AsyncValue<UserResponse?>>((ref) {
  return ref.watch(userProvider);
});

// Provider to automatically fetch current user profile when authenticated
final autoFetchCurrentUserProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
    if (next && (previous == false)) {
      Future.microtask(() {
        ref.read(userProvider.notifier).getCurrentUserProfile();
      });
    } else if (!next && (previous == true)) {
      ref.read(userProvider.notifier).clearState();
    }
  });

  if (isAuthenticated) {
    Future.microtask(() {
      ref.read(userProvider.notifier).getCurrentUserProfile();
    });
  }

  return;
});

// Helper provider to check if current user profile is loaded
final isCurrentUserProfileLoadedProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  return userState.maybeWhen(
    data: (response) => response != null,
    orElse: () => false,
  );
});

// Helper provider to get current user data from profile
final currentUserDataProvider = Provider<UserItem?>((ref) {
  final userState = ref.watch(userProvider);
  return userState.maybeWhen(
    data: (response) => response?.data,
    orElse: () => null,
  );
});

// Helper provider to clear user data when signing out
final userAuthStateListener = Provider<void>((ref) {
  ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
    if (!next && (previous == true)) {
      ref.read(userProvider.notifier).clearState();
    }
  });
  return;
});
