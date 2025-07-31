import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api_client.dart';
import '../services/token_storage_service.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final AuthApiClient _apiClient;
  final TokenStorageService _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final request = SignUpRequest(
        email: email,
        password: password,
        name: name,
      );

      final response = await _apiClient.signUp(request);

      // Save user ID if available
      if (response.data?.id != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', response.data!.id!);
      }

      return response;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error during signup: $e');
      return AuthResponse(
        success: false,
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final request = SignInRequest(email: email, password: password);
      final response = await _apiClient.signIn(request);

      if (response.success && response.data?.accessToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: response.data!.accessToken!,
          refreshToken: response.data!.refreshToken,
          expiresIn: response.data!.expiresIn ?? 43200,
          username: response.data!.username,
          id: response.data!.id,
        );

        if (kDebugMode) {
          print('✅ Login successful, tokens saved');
        }
      }

      return response;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error during login: $e');
      return AuthResponse(
        success: false,
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  Future<AuthResponse> signOut() async {
    try {
      await _apiClient.signOut();
      await _tokenStorage.clearTokens();

      if (kDebugMode) print('✅ Signed out successfully');

      return AuthResponse(success: true, message: 'Signed out successfully');
    } catch (e) {
      if (kDebugMode) print('Error during logout: $e');
      // Clear tokens even on error
      await _tokenStorage.clearTokens();
      return AuthResponse(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  Future<AuthResponse> refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return AuthResponse(
          success: false,
          message: 'No refresh token available',
        );
      }

      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _apiClient.refreshToken(request);

      if (response.success && response.data?.accessToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: response.data!.accessToken!,
          refreshToken: response.data!.refreshToken ?? refreshToken,
          expiresIn: response.data!.expiresIn ?? 43200,
          username: response.data!.username,
          id: response.data!.id,
        );

        if (kDebugMode) print('✅ Token refreshed successfully');
      }

      return response;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error refreshing token: $e');
      return AuthResponse(success: false, message: 'Failed to refresh token');
    }
  }

  Future<AuthResponse> forgotPassword({required String email}) async {
    try {
      final request = ForgotPasswordRequest(email: email);
      return await _apiClient.forgotPassword(request);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error requesting password reset: $e');
      return AuthResponse(
        success: false,
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  Future<AuthResponse> resendConfirmationCode({required String email}) async {
    try {
      final request = ForgotPasswordRequest(email: email);
      return await _apiClient.resendConfirmation(request);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error resending confirmation code: $e');
      return AuthResponse(
        success: false,
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  Future<AuthResponse> changePassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      final request = ChangePasswordRequest(
        email: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      return await _apiClient.changePassword(request);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error confirming password reset: $e');
      return AuthResponse(
        success: false,
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  Future<AuthData?> getStoredAuthData() async {
    return await _tokenStorage.getStoredTokens();
  }

  Future<bool> isTokenExpired() async {
    return await _tokenStorage.isTokenExpired();
  }

  AuthResponse _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return AuthResponse.fromJson(data);
      }
    }

    return AuthResponse(
      success: false,
      message: e.message ?? 'Network error occurred',
    );
  }
}
