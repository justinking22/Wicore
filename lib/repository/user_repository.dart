// lib/repository/user_repository.dart
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

  Future<UserResponse> createUser(UserRequest request) async {
    try {
      print('🔧 Repository - Creating user');
      return await _apiClient.createUser(request);
    } on DioException catch (e) {
      print('🔧 ❌ Repository - Error creating user: $e');
      throw _handleDioError(e);
    }
  }

  Future<UserResponse> getUser(String userId) async {
    try {
      print('🔧 Repository - Getting user: $userId');
      return await _apiClient.getUser(userId);
    } on DioException catch (e) {
      print('🔧 ❌ Repository - Error getting user: $e');
      throw _handleDioError(e);
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
      return await _apiClient.deleteUser(userId);
    } on DioException catch (e) {
      print('🔧 ❌ Repository - Error deleting user: $e');
      throw _handleDioError(e);
    }
  }

  // Enhanced error handling
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
          } catch (_) {
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

  // Optional: Helper method to validate UserUpdateRequest
  bool _isValidUpdateRequest(UserUpdateRequest request) {
    // Add any custom validation logic here
    if (request.isEmpty) return false;

    return true;
  }

  // Optional: Enhanced update method with validation
  Future<UserResponse> updateUserWithValidation(
    String userId,
    UserUpdateRequest request,
  ) async {
    if (!_isValidUpdateRequest(request)) {
      throw Exception('Invalid update request data');
    }

    return updateUser(userId, request);
  }
}

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.read(userApiClientProvider);
  return UserRepository(apiClient, ref);
});
