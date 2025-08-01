import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api_client.dart';
import '../services/token_storage_service.dart';

import '../models/sign_up_request_model.dart';
import '../models/sign_up_response_model.dart';
import '../models/sign_in_request_model.dart';
import '../models/sign_in_response_model.dart';
import '../models/refresh_token_request_model.dart';
import '../models/refresh_token_response_model.dart';
import '../models/forgot_password_request_model.dart';
import '../models/forgot_password_response_model.dart';
import '../models/resend_confirmation_request_model.dart';
import '../models/resend_confirmation_response_model.dart';
import '../models/change_password_request_model.dart';
import '../models/change_password_response_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthApiClient _apiClient;
  final TokenStorageService _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<SignUpServerResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final request = SignUpRequest(email: email, password: password);

      final serverResponse = await _apiClient.signUp(request);

      // Save user ID if available
      if (serverResponse.data?.id != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', serverResponse.data!.id!);
      }

      return serverResponse;
    } on DioException catch (e) {
      return _handleSignUpDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error during signup: $e');
      return SignUpServerResponse(data: null, code: -1);
    }
  }

  Future<SignInServerResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final request = SignInRequest(email: email, password: password);
      final serverResponse = await _apiClient.signIn(request);

      if (serverResponse.isSuccess &&
          serverResponse.data?.accessToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: serverResponse.data!.accessToken!,
          refreshToken: serverResponse.data!.refreshToken,
          expiryDate: serverResponse.data!.expiryDate ?? '',
          username: serverResponse.data!.username,
          id: null, // Sign in doesn't return ID
        );

        if (kDebugMode) {
          print('✅ Login successful, tokens saved');
        }
      }

      return serverResponse;
    } on DioException catch (e) {
      return _handleSignInDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error during login: $e');
      return SignInServerResponse(data: null, code: -1);
    }
  }

  Future<void> signOut() async {
    try {
      await _tokenStorage.clearTokens();
      if (kDebugMode) print('✅ Signed out successfully');
    } catch (e) {
      if (kDebugMode) print('Error during logout: $e');
      // Clear tokens even on error
      await _tokenStorage.clearTokens();
      rethrow;
    }
  }

  Future<RefreshTokenResponse> refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      final userName = await _tokenStorage.getUsername();

      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final request = RefreshTokenRequest(
        refreshToken: refreshToken,
        username: userName ?? '',
      );
      final serverResponse = await _apiClient.refreshToken(request);

      // ✅ Fixed: Access the nested data structure correctly
      if (serverResponse.isSuccess &&
          serverResponse.data?.accessToken != null) {
        // Get existing data to preserve some fields
        final existingData = await getStoredAuthData();

        await _tokenStorage.saveTokens(
          accessToken: serverResponse.data!.accessToken!,
          refreshToken: serverResponse.data!.refreshToken ?? refreshToken,
          expiryDate: serverResponse.data!.expiryDate ?? '',
          username: serverResponse.data!.username ?? existingData?.username,
          id: existingData?.id,
        );

        if (kDebugMode) print('✅ Token refreshed successfully');
      }

      return serverResponse;
    } on DioException catch (e) {
      return _handleRefreshTokenDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error refreshing token: $e');
      return RefreshTokenResponse(data: null, code: -1);
    }
  }

  Future<ForgotPasswordResponse> forgotPassword({required String email}) async {
    try {
      final request = ForgotPasswordRequest(email: email);
      final serverResponse = await _apiClient.forgotPassword(request);

      return serverResponse;
    } on DioException catch (e) {
      return _handleForgotPasswordDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error requesting password reset: $e');
      return ForgotPasswordResponse(data: null, code: -1);
    }
  }

  Future<ResendConfirmationResponse> resendConfirmationCode({
    required String email,
  }) async {
    try {
      final request = ResendConfirmationRequest(email: email);
      final serverResponse = await _apiClient.resendConfirmation(request);

      return serverResponse;
    } on DioException catch (e) {
      return _handleResendConfirmationDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error resending confirmation code: $e');
      return ResendConfirmationResponse(data: null, code: -1);
    }
  }

  Future<ChangePasswordResponse> changePassword({
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
      final serverResponse = await _apiClient.changePassword(request);

      return serverResponse;
    } on DioException catch (e) {
      return _handleChangePasswordDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error confirming password reset: $e');
      return ChangePasswordResponse(data: null, code: -1);
    }
  }

  Future<UserData?> getStoredAuthData() async {
    return await _tokenStorage.getStoredTokens();
  }

  Future<bool> isTokenExpired() async {
    return await _tokenStorage.isTokenExpired();
  }

  // Individual error handlers for each response type
  SignUpServerResponse _handleSignUpDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return SignUpServerResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return SignUpServerResponse(data: null, code: e.response?.statusCode ?? -1);
  }

  SignInServerResponse _handleSignInDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return SignInServerResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return SignInServerResponse(data: null, code: e.response?.statusCode ?? -1);
  }

  RefreshTokenResponse _handleRefreshTokenDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return RefreshTokenResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return RefreshTokenResponse(data: null, code: -1);
  }

  ForgotPasswordResponse _handleForgotPasswordDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return ForgotPasswordResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return ForgotPasswordResponse(
      data: null,
      code: e.response?.statusCode ?? -1,
    );
  }

  ResendConfirmationResponse _handleResendConfirmationDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return ResendConfirmationResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return ResendConfirmationResponse(
      data: null,
      code: e.response?.statusCode ?? -1,
    );
  }

  ChangePasswordResponse _handleChangePasswordDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return ChangePasswordResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return ChangePasswordResponse(
      data: null,
      code: e.response?.statusCode ?? -1,
    );
  }
}
