import 'package:Wicore/models/notification_preferences_model.dart';
import 'package:Wicore/models/user_response_model.dart';
import 'package:Wicore/models/user_request_model.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/repository/user_repository.dart';
import 'package:Wicore/services/user_api_client.dart';
import 'package:Wicore/states/auth_status.dart';
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

  // Future<void> createUser(UserRequest request) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     final authNotifier = _ref.read(authNotifierProvider.notifier);
  //     final token = await authNotifier.getValidToken();
  //     if (token == null) {
  //       throw Exception('No valid authentication token available');
  //     }

  //     final response = await _repository.createUser(request);
  //     state = AsyncValue.data(response);

  //     print('🔧 ✅ UserNotifier - User created successfully');
  //   } catch (error, stackTrace) {
  //     print('🔧 ❌ UserNotifier - Error creating user: $error');
  //     state = AsyncValue.error(error, stackTrace);
  //   }
  // }

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

  // ✅ ENHANCED: Replace your updateCurrentUserProfile method with this:
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

  // ✅ ENHANCED: Better error handling in getCurrentUserProfile
  Future<void> getCurrentUserProfile() async {
    try {
      print('🔧 🔄 UserNotifier - Loading current user profile');

      // Don't set loading state if we already have data (prevents UI flicker)
      final hasExistingData = state.maybeWhen(
        data: (response) => response?.data != null,
        orElse: () => false,
      );

      if (!hasExistingData) {
        state = const AsyncValue.loading();
      }

      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        throw Exception('No valid authentication token available');
      }

      final authState = _ref.read(authNotifierProvider);
      final userData = authState.userData;

      if (userData?.id == null && userData?.username == null) {
        throw Exception('No user ID available in auth state');
      }

      final userId = userData?.id ?? userData?.username ?? '';
      print('🔧 🔍 UserNotifier - Fetching profile for user ID: $userId');
      print('🔧 🔍 UserNotifier - Auth user data: ${userData!}');

      final response = await _repository.getUser(userId);

      if (response != null) {
        state = AsyncValue.data(response);
        print('🔧 ✅ UserNotifier - Current user profile loaded successfully');
        print(
          '🔧 📊 UserNotifier - Onboarded status: ${response.data?.onboarded}',
        );
        print(
          '🔧 📊 UserNotifier - Full user data: ${response.data?.toJson()}',
        );
      } else {
        print('🔧 ⚠️ UserNotifier - Received null response for user profile');
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error getting current user profile: $error');
      print('🔧 📚 Stack trace: $stackTrace');

      // Don't overwrite existing data with error state unless it's a critical error
      final hasExistingData = state.maybeWhen(
        data: (response) => response?.data != null,
        orElse: () => false,
      );

      if (!hasExistingData) {
        state = AsyncValue.error(error, stackTrace);
      } else {
        print('🔧 ⚠️ UserNotifier - Keeping existing data, error logged');
      }
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
  // Add these methods to your UserNotifier class

  // Add these methods to your UserNotifier class

  // Method to update a single notification setting while preserving others
  Future<void> updateSingleNotificationSetting({
    bool? batteryLow,
    bool? connectionDisabled,
    bool? userFallConfirmed,
  }) async {
    try {
      // Get current notification settings from the user profile
      final currentUser = this.currentUser;
      final currentNotifications = currentUser?.notificationPreferences;

      String settingName = '';
      bool settingValue = false;

      // Determine which setting is being updated and preserve others
      final updatedBatteryLow =
          batteryLow ?? currentNotifications?.lowBattery ?? true;
      final updatedConnectionDisabled =
          connectionDisabled ??
          currentNotifications?.deviceDisconnected ??
          true;
      final updatedUserFallConfirmed =
          userFallConfirmed ?? currentNotifications?.fallDetection ?? true;

      // Determine which setting is being updated for logging
      if (batteryLow != null) {
        settingName = 'lowBattery';
        settingValue = batteryLow;
      } else if (connectionDisabled != null) {
        settingName = 'deviceDisconnected';
        settingValue = connectionDisabled;
      } else if (userFallConfirmed != null) {
        settingName = 'fallDetection';
        settingValue = userFallConfirmed;
      } else {
        throw Exception('No notification setting provided to update');
      }

      print('🔧 🔔 UserNotifier - Updating $settingName = $settingValue');
      print(
        '🔧 🔔 UserNotifier - Sending all three: battery=$updatedBatteryLow, connection=$updatedConnectionDisabled, fall=$updatedUserFallConfirmed',
      );

      // Create notification preferences with ALL three values (as required by API)
      final notificationPreferences = NotificationPreferences(
        lowBattery: updatedBatteryLow,
        deviceDisconnected: updatedConnectionDisabled,
        fallDetection: updatedUserFallConfirmed,
      );

      final updateRequest = UserUpdateRequest.notificationsOnly(
        preferences: notificationPreferences,
      );

      print('🔧 🔔 PATCH request JSON: ${updateRequest.toJsonNonNull()}');

      await updateCurrentUserProfile(updateRequest);

      print('🔧 ✅ UserNotifier - Notification settings updated successfully');
    } catch (error, stackTrace) {
      print('🔧 ❌ UserNotifier - Error updating notification settings: $error');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Convenience methods for individual settings (preserving others)
  Future<void> updateBatteryLowNotification(bool enabled) async {
    await updateSingleNotificationSetting(batteryLow: enabled);
  }

  Future<void> updateConnectionDisconnectedNotification(bool enabled) async {
    await updateSingleNotificationSetting(connectionDisabled: enabled);
  }

  Future<void> updateFallDetectionNotification(bool enabled) async {
    await updateSingleNotificationSetting(userFallConfirmed: enabled);
  }

  // Method to update all notification preferences at once
  Future<void> updateAllNotificationPreferences({
    required bool batteryLow,
    required bool connectionDisabled,
    required bool userFallConfirmed,
  }) async {
    try {
      print('🔧 🔔 UserNotifier - Updating all notification preferences');
      print('🔧 🔔 Battery Low: $batteryLow');
      print('🔧 🔔 Connection Disabled: $connectionDisabled');
      print('🔧 🔔 Fall Detection: $userFallConfirmed');

      final notificationPreferences = NotificationPreferences(
        lowBattery: batteryLow,
        deviceDisconnected: connectionDisabled,
        fallDetection: userFallConfirmed,
      );

      final updateRequest = UserUpdateRequest.notificationsOnly(
        preferences: notificationPreferences,
      );

      print('🔧 🔔 Update request JSON: ${updateRequest.toJsonNonNull()}');

      await updateCurrentUserProfile(updateRequest);

      print(
        '🔧 ✅ UserNotifier - All notification preferences updated successfully',
      );
    } catch (error, stackTrace) {
      print(
        '🔧 ❌ UserNotifier - Error updating all notification preferences: $error',
      );
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Helper method to check if user is onboarded
  bool get isOnboarded {
    final user = currentUser;
    final onboarded = user?.onboarded ?? false;
    print('🔧 📊 UserNotifier - isOnboarded getter: $onboarded');
    return onboarded;
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

// ✅ ENHANCED: Improved auto-fetch provider with better timing and error handling
final autoFetchCurrentUserProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final authState = ref.watch(authNotifierProvider);

  // Listen for authentication changes
  ref.listen<bool>(isAuthenticatedProvider, (previous, next) async {
    print('🔧 📡 Auto-fetch - Auth state changed: $previous -> $next');

    if (next && (previous == false)) {
      print('🔧 📡 Auto-fetch - User just authenticated, fetching profile');

      // Small delay to ensure auth state is fully settled
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        await ref.read(userProvider.notifier).getCurrentUserProfile();
        print('🔧 ✅ Auto-fetch - User profile loaded successfully');
      } catch (error) {
        print('🔧 ❌ Auto-fetch - Error loading user profile: $error');

        // Retry once after a delay
        await Future.delayed(const Duration(seconds: 1));
        try {
          await ref.read(userProvider.notifier).getCurrentUserProfile();
          print('🔧 ✅ Auto-fetch - User profile loaded on retry');
        } catch (retryError) {
          print('🔧 ❌ Auto-fetch - Retry failed: $retryError');
        }
      }
    } else if (!next && (previous == true)) {
      print('🔧 🧹 Auto-fetch - User logged out, clearing user state');
      ref.read(userProvider.notifier).clearState();
    }
  });

  // Initial fetch if already authenticated
  if (isAuthenticated && authState.status == AuthStatus.authenticated) {
    final currentUserState = ref.read(userProvider);

    // Only fetch if we don't already have user data
    currentUserState.whenOrNull(
      data: (response) {
        if (response?.data == null) {
          print(
            '🔧 📡 Auto-fetch - No user data found, fetching initial profile',
          );
          Future.microtask(() async {
            try {
              await ref.read(userProvider.notifier).getCurrentUserProfile();
              print('🔧 ✅ Auto-fetch - Initial user profile loaded');
            } catch (error) {
              print('🔧 ❌ Auto-fetch - Error loading initial profile: $error');
            }
          });
        } else {
          print('🔧 ✅ Auto-fetch - User data already available');
          print('🔧 📊 Auto-fetch - Onboarded: ${response?.data?.onboarded}');
        }
      },
    );

    // If state is loading or error, try to fetch
    if (currentUserState is AsyncLoading || currentUserState is AsyncError) {
      print('🔧 📡 Auto-fetch - User state is loading/error, fetching profile');
      Future.microtask(() async {
        try {
          await ref.read(userProvider.notifier).getCurrentUserProfile();
          print('🔧 ✅ Auto-fetch - User profile refreshed');
        } catch (error) {
          print('🔧 ❌ Auto-fetch - Error refreshing profile: $error');
        }
      });
    }
  }

  return;
});

// Helper provider to check if current user profile is loaded
final isCurrentUserProfileLoadedProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  final isLoaded = userState.maybeWhen(
    data: (response) => response?.data != null,
    orElse: () => false,
  );
  print('🔧 📊 isCurrentUserProfileLoadedProvider - $isLoaded');
  return isLoaded;
});

// Helper provider to get current user data from profile
final currentUserDataProvider = Provider<UserItem?>((ref) {
  final userState = ref.watch(userProvider);
  final userData = userState.maybeWhen(
    data: (response) => response?.data,
    orElse: () => null,
  );
  print('🔧 📊 currentUserDataProvider - onboarded: ${userData?.onboarded}');
  return userData;
});

// ✅ ENHANCED: Helper provider to get onboarded status specifically
final isUserOnboardedProvider = Provider<bool>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  final isOnboarded = userData?.onboarded ?? false;
  print('🔧 📊 isUserOnboardedProvider - $isOnboarded');
  return isOnboarded;
});

// Helper provider to clear user data when signing out
final userAuthStateListener = Provider<void>((ref) {
  ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
    if (!next && (previous == true)) {
      print('🔧 🧹 userAuthStateListener - Clearing user state on logout');
      ref.read(userProvider.notifier).clearState();
    }
  });
  return;
});
final currentNotificationPreferencesProvider =
    Provider<NotificationPreferences?>((ref) {
      final userData = ref.watch(currentUserDataProvider);
      final notifications = userData?.notificationPreferences;
      print('🔧 📊 currentNotificationPreferencesProvider - $notifications');
      return notifications;
    });

// Provider to watch for notification changes
final notificationStateProvider =
    Provider<AsyncValue<NotificationPreferences?>>((ref) {
      final userState = ref.watch(userProvider);
      return userState.when(
        data:
            (response) =>
                AsyncValue.data(response?.data?.notificationPreferences),
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

// Helper provider to get individual notification settings
final batteryLowNotificationProvider = Provider<bool>((ref) {
  final notifications = ref.watch(currentNotificationPreferencesProvider);
  return notifications?.lowBattery ?? true; // Default to true if not set
});

final connectionDisconnectedNotificationProvider = Provider<bool>((ref) {
  final notifications = ref.watch(currentNotificationPreferencesProvider);
  return notifications?.deviceDisconnected ??
      true; // Default to true if not set
});

final fallDetectionNotificationProvider = Provider<bool>((ref) {
  final notifications = ref.watch(currentNotificationPreferencesProvider);
  return notifications?.fallDetection ?? true; // Default to true if not set
});
