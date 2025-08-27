// lib/repository/user_repository.dart
import 'package:Wicore/models/incognito_user.dart';
import 'package:Wicore/models/incognito_user_request.dart';
import 'package:Wicore/models/incognito_user_response.dart';
import 'package:Wicore/models/notification_preferences_model.dart';
import 'package:Wicore/models/user_request_model.dart';
import 'package:Wicore/models/user_response_model.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/services/user_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserRepository {
  final UserApiClient _apiClient;
  final Ref _ref;

  UserRepository(this._apiClient, this._ref);

  // Add this method to your existing UserRepository class

  Future<IncognitoUserResponse> createOrUpdateIncognitoUser({
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? birthdate,
    int? weight,
    int? height,
    String? gender,
    bool? onboarded,
    NotificationPreferences? notificationPreferences,
    int? deviceStrength,
  }) async {
    try {
      if (kDebugMode) print('Creating/updating incognito user');

      final user = IncognitoUser(
        email: email,
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        birthdate: birthdate,
        weight: weight,
        height: height,
        gender: gender,
        onboarded: onboarded ?? false,
        notificationPreferences:
            notificationPreferences ??
            const NotificationPreferences(
              lowBattery: true,
              deviceDisconnected: true,
              fallDetection: true,
            ),
        deviceStrength: deviceStrength ?? 1,
      );

      final request = IncognitoUserRequest(item: user);
      final response = await _apiClient.createOrUpdateIncognitoUser(request);

      if (kDebugMode) {
        print('Incognito user created/updated successfully');
        print('   Success: ${response.success}');
        print('   Message: ${response.message}');
        print('   Email: ${response.data?.email}');
        print('   Name: ${response.data?.firstName}');
        print('   Incognito User ID: ${response.incognitoUserId}');
      }

      // Save incognito user data locally using your existing user provider
      if (response.success && response.data != null) {
        try {
          final incognitoService = _ref.read(incognitoUserServiceProvider);
          await incognitoService.saveIncognitoUserData(response.data!);
          await incognitoService.setIncognitoMode(true);

          // Save incognito user ID if provided
          if (response.incognitoUserId != null) {
            await incognitoService.saveIncognitoUserId(
              response.incognitoUserId!,
            );
          }
        } catch (storageError) {
          if (kDebugMode)
            print(
              'Warning: Failed to save incognito data locally: $storageError',
            );
          // Continue even if local storage fails
        }
      }

      return response;
    } on DioException catch (e) {
      if (kDebugMode) print('Dio error creating incognito user: ${e.message}');
      throw _handleDioError(e);
    } catch (error) {
      if (kDebugMode) print('Unexpected error creating incognito user: $error');
      rethrow;
    }
  }

  // Helper method for social login integration
  Future<IncognitoUserResponse> setupIncognitoUserForSocialLogin({
    required String email,
    required String firstName,
    String? provider,
  }) async {
    if (kDebugMode) {
      print('Setting up incognito user for social login');
      print('   Email: $email');
      print('   Name: $firstName');
      print('   Provider: $provider');
    }

    return await createOrUpdateIncognitoUser(
      email: email,
      firstName: firstName,
      onboarded: false,
      notificationPreferences: const NotificationPreferences(
        lowBattery: true,
        deviceDisconnected: true,
        fallDetection: true,
      ),
      deviceStrength: 1,
    );
  }

  Future<UserResponse> getUser(String userId) async {
    try {
      print('🔧 Repository - Getting user: $userId');
      final response = await _apiClient.getUser(userId);
      print('🔧 ✅ Repository - User retrieved successfully');
      print('🔧 📊 Repository - User onboarded: ${response.data?.onboarded}');
      return response;
    } on DioException catch (e) {
      print('🔧 ❌ Repository - Error getting user: $e');
      throw _handleDioError(e);
    } catch (error) {
      print('🔧 ❌ Repository - Unexpected error getting user: $error');
      rethrow;
    }
  }

  // ✅ DEFINITIVE FIX: This handles the exact error from line 120 in your generated client
  Future<UserResponse> updateUser(
    String userId,
    UserUpdateRequest request,
  ) async {
    try {
      print('🔧 Repository - Updating user: $userId');
      print('🔧 Repository - Update data: ${request.toJsonNonNull()}');

      if (request.isEmpty) {
        throw Exception('No fields to update');
      }

      // Try the generated client method
      final response = await _apiClient.updateUser(userId, request);
      print('🔧 ✅ Repository - Generated client update successful');
      print('🔧 📊 Repository - Update response code: ${response.code}');
      return response;
    } catch (error) {
      print('🔧 🔍 Repository - Caught error from generated client: $error');
      print('🔧 🔍 Repository - Error type: ${error.runtimeType}');

      // Check for the specific null check error from line 120 in generated client
      if (error.toString().contains(
        'Null check operator used on a null value',
      )) {
        print(
          '🔧 💡 Repository - This is the line 120 error from user_api_client.g.dart',
        );
        print(
          '🔧 💡 Repository - The API returned 200 OK but empty body (which is correct for PATCH)',
        );
        print(
          '🔧 💡 Repository - Generated client tried UserResponse.fromJson(_result.data!) where _result.data was null',
        );

        // The update was actually successful, create a success response
        return UserResponse(
          data: null, // API doesn't return user data on successful PATCH
          code: 200,
          msg: 'Update successful',
        );
      }

      // Handle DioException separately
      if (error is DioException) {
        print('🔧 ❌ Repository - DioException during update: $error');
        throw _handleDioError(error);
      }

      // For any other unexpected error, rethrow
      print('🔧 ❌ Repository - Unexpected error during update: $error');
      rethrow;
    }
  }

  Future<UserResponse> deleteUser(String userId) async {
    try {
      print('🔧 Repository - Deleting user: $userId');
      final response = await _apiClient.deleteUser(userId);
      print('🔧 ✅ Repository - User deleted successfully');
      return response;
    } on DioException catch (e) {
      print('🔧 ❌ Repository - Error deleting user: $e');
      throw _handleDioError(e);
    } catch (error) {
      print('🔧 ❌ Repository - Unexpected error deleting user: $error');
      rethrow;
    }
  }

  // ✅ ENHANCED: Enhanced error handling with better logging
  Exception _handleDioError(DioException e) {
    print('🔧 🔍 Repository - Handling DioException: ${e.type}');
    print('🔧 🔍 Repository - Status code: ${e.response?.statusCode}');
    print('🔧 🔍 Repository - Response data: ${e.response?.data}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          print('🔧 🔐 Repository - 401 Unauthorized, clearing auth state');
          try {
            _ref.read(authNotifierProvider.notifier).setUnauthenticated();
          } catch (authError) {
            if (kDebugMode)
              print('🔧 ❌ Error setting unauthenticated: $authError');
          }
          return Exception('Authentication failed. Please sign in again.');
        }

        // Handle specific status codes
        switch (e.response?.statusCode) {
          case 400:
            return Exception('Bad request. Please check your input.');
          case 403:
            return Exception('Access forbidden. Insufficient permissions.');
          case 404:
            return Exception('User not found.');
          case 422:
            return Exception('Invalid data provided.');
          case 500:
            return Exception('Server error. Please try again later.');
        }

        if (e.response?.data != null) {
          try {
            final errorResponse = UserErrorResponse.fromJson(e.response!.data);
            return Exception('API Error: ${errorResponse.msg}');
          } catch (parseError) {
            print(
              '🔧 ⚠️ Repository - Could not parse error response: $parseError',
            );
            // If we can't parse the error response, return generic error
            return Exception('Server error: ${e.response?.statusCode}');
          }
        }
        return Exception('Server error: ${e.response?.statusCode}');

      case DioExceptionType.cancel:
        return Exception('Request was cancelled');

      case DioExceptionType.unknown:
      default:
        // Check if it's a network connectivity issue
        if (e.message?.contains('SocketException') == true) {
          return Exception(
            'No internet connection. Please check your network.',
          );
        }
        return Exception('Network error occurred. Please try again.');
    }
  }

  // ✅ ENHANCED: Helper method to validate UserUpdateRequest
  bool _isValidUpdateRequest(UserUpdateRequest request) {
    // Add any custom validation logic here
    if (request.isEmpty) {
      print('🔧 ⚠️ Repository - Update request is empty');
      return false;
    }

    // Add more validation as needed
    print('🔧 ✅ Repository - Update request is valid');
    return true;
  }

  // ✅ ENHANCED: Enhanced update method with validation
  Future<UserResponse> updateUserWithValidation(
    String userId,
    UserUpdateRequest request,
  ) async {
    if (!_isValidUpdateRequest(request)) {
      throw Exception('Invalid update request data');
    }

    return updateUser(userId, request);
  }

  // ✅ NEW: Helper method to refresh user data after operations
  Future<UserResponse> refreshUserData(String userId) async {
    try {
      print('🔧 🔄 Repository - Refreshing user data for: $userId');
      final response = await getUser(userId);
      print('🔧 ✅ Repository - User data refreshed successfully');
      return response;
    } catch (error) {
      print('🔧 ❌ Repository - Error refreshing user data: $error');
      rethrow;
    }
  }

  // ✅ NEW: Helper method to check if user exists
  Future<bool> userExists(String userId) async {
    try {
      await getUser(userId);
      return true;
    } catch (error) {
      print(
        '🔧 🔍 Repository - User $userId does not exist or error occurred: $error',
      );
      return false;
    }
  }
}

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.read(userApiClientProvider);
  return UserRepository(apiClient, ref);
});
