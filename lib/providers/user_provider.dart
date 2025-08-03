import 'package:Wicore/models/user_response_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/services/user_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wicore/models/user_request_model.dart';
import 'package:flutter/foundation.dart';

// User API client provider using authenticated Dio
final userApiClientProvider = Provider<UserApiClient>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return UserApiClient(dio);
});

// User repository
class UserRepository {
  final UserApiClient _apiClient;
  final Ref _ref;

  UserRepository(this._apiClient, this._ref);

  Future<UserResponse> createUser(UserRequest request) async {
    try {
      return await _apiClient.createUser(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserResponse> getUser(String userId) async {
    try {
      return await _apiClient.getUser(userId);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserResponse> updateUser(String userId, UserRequest request) async {
    try {
      return await _apiClient.updateUser(userId, request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserResponse> deleteUser(String userId) async {
    try {
      return await _apiClient.deleteUser(userId);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          try {
            _ref.read(authNotifierProvider.notifier).setUnauthenticated();
          } catch (authError) {
            if (kDebugMode) print('Error setting unauthenticated: $authError');
          }
          return Exception('Authentication failed. Please sign in again.');
        }
        if (e.response?.data != null) {
          try {
            final errorResponse = UserErrorResponse.fromJson(e.response!.data);
            return Exception('API Error: ${errorResponse.msg}');
          } catch (_) {
            return Exception('Server error: ${e.response?.statusCode}');
          }
        }
        return Exception('Server error: ${e.response?.statusCode}');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
      default:
        return Exception('Network error occurred');
    }
  }
}

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.read(userApiClientProvider);
  return UserRepository(apiClient, ref);
});

// User state notifier
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
    } catch (error, stackTrace) {
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUser(String userId, UserRequest request) async {
    state = const AsyncValue.loading();
    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final response = await _repository.updateUser(userId, request);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
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
    } catch (error, stackTrace) {
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCurrentUserProfile(UserRequest request) async {
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
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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

// Helper provider to get current user data from profile - FIXED
final currentUserDataProvider = Provider<UserItem?>((ref) {
  final userState = ref.watch(userProvider);
  return userState.maybeWhen(
    data: (response) => response?.data, // Now data is directly UserItem
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
