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

  // Updated method to use UserUpdateRequest (this looks correct in your code)
  Future<UserResponse> updateUser(
    String deviceId,
    UserUpdateRequest request,
  ) async {
    try {
      print('🔧 Repository - Updating user: $deviceId');
      print('🔧 Repository - Update data: ${request.toJsonNonNull()}');

      if (request.isEmpty) {
        throw Exception('No fields to update');
      }

      return await _apiClient.updateUser(deviceId, request);
    } on DioException catch (e) {
      print('🔧 ❌ Repository - Error updating user: $e');
      throw _handleDioError(e);
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

    // Example validations
    if (request.age != null && (request.age! < 0 || request.age! > 150)) {
      return false;
    }

    if (request.deviceStrength != null && request.deviceStrength! < 0) {
      return false;
    }

    if (request.firstName != null && request.firstName!.trim().isEmpty) {
      return false;
    }

    if (request.lastName != null && request.lastName!.trim().isEmpty) {
      return false;
    }

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
