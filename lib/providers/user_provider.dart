import 'package:Wicore/models/user_response_model.dart';
import 'package:Wicore/models/user_request_model.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/repository/user_repository.dart';
import 'package:Wicore/services/user_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// User API client provider using authenticated Dio
final userApiClientProvider = Provider<UserApiClient>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return UserApiClient(dio);
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

  Future<void> updateUser(String userId, UserUpdateRequest request) async {
    state = const AsyncValue.loading();
    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final response = await _repository.updateUser(userId, request);
      // Handle null response.data safely
      if (response != null) {
        state = AsyncValue.data(response);
        print('🔧 ✅ UserNotifier - User updated successfully');
      } else {
        // If response is null, refresh the current user profile
        print(
          '🔧 ⚠️ UserNotifier - Received null response, refreshing profile',
        );
        await getCurrentUserProfile();
      }
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
  // Replace your updateCurrentUserProfile method in UserNotifier with this:

  Future<void> updateCurrentUserProfile(UserUpdateRequest request) async {
    try {
      print(
        '🔧 🔄 UserNotifier - Starting profile update with: ${request.toJson()}',
      );

      // Validate the request
      if (request.isEmpty) {
        print('🔧 ⚠️ UserNotifier - Update request is empty, skipping');
        return;
      }

      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final authState = _ref.read(authNotifierProvider);
      final userData = authState.userData;

      final userId = userData?.id ?? userData?.username;
      if (userId == null || userId.isEmpty) {
        throw Exception('No user ID available for update');
      }

      print('🔧 🔍 UserNotifier - Updating user ID: $userId');

      // Call repository - it will handle the generated client error
      final response = await _repository.updateUser(userId, request);

      if (response != null) {
        if (response.code == 200 || response.code == 201) {
          print(
            '🔧 ✅ UserNotifier - Repository handled update successfully (code: ${response.code})',
          );

          // Always refresh user profile after successful update
          print(
            '🔧 🔄 UserNotifier - Refreshing user profile to get latest data',
          );
          await getCurrentUserProfile();

          print(
            '🔧 ✅ UserNotifier - Update and refresh completed successfully',
          );
          return; // ✅ Important: return here on success, don't set error state
        } else {
          throw Exception(
            'Update failed with code: ${response.code}, message: ${response.msg}',
          );
        }
      } else {
        throw Exception('Received null response from repository');
      }
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error in updateCurrentUserProfile: $error');
      print('🔧 📚 Stack trace: $stackTrace');

      // Set error state and rethrow only for actual errors
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // ✅ Also update getCurrentUserProfile to be more robust:
  Future<void> getCurrentUserProfile() async {
    try {
      print('🔧 🔄 UserNotifier - Loading current user profile');
      state = const AsyncValue.loading();

      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final authState = _ref.read(authNotifierProvider);
      final userData = authState.userData;

      if (userData?.id == null && userData?.username == null) {
        throw Exception('No user ID available');
      }

      final userId = userData?.id ?? userData?.username ?? '';
      print('🔧 🔍 UserNotifier - Fetching profile for user ID: $userId');

      final response = await _repository.getUser(userId);

      if (response != null) {
        state = AsyncValue.data(response);
        print('🔧 ✅ UserNotifier - Current user profile loaded successfully');
        print('🔧 📊 UserNotifier - User data: ${response.data?.toJson()}');
      } else {
        print('🔧 ⚠️ UserNotifier - Received null response for user profile');
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error getting current user profile: $error');
      print('🔧 📚 Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

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

  void clearState() {
    state = const AsyncValue.data(null);
    print('🔧 🧹 UserNotifier - State cleared');
  }

  // Helper method to safely get current user data
  UserItem? get currentUser {
    return state.maybeWhen(
      data: (response) => response?.data,
      orElse: () => null,
    );
  }

  // Helper method to check if user is onboarded
  bool get isOnboarded {
    final user = currentUser;
    return user?.onboarded ?? false;
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
      print('🔧 🔄 Auto-fetching user profile on authentication');
      Future.microtask(() {
        ref.read(userProvider.notifier).getCurrentUserProfile();
      });
    } else if (!next && (previous == true)) {
      print('🔧 🧹 Clearing user state on logout');
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
    data: (response) => response?.data != null,
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
