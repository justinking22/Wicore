import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/repository/fcm_repository.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/states/fcm_token_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:Wicore/repository/fcm_repository.dart';
import 'package:Wicore/models/fcm_notification_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'dart:async';

class FcmTokenNotifier extends StateNotifier<FcmTokenState> {
  final FcmRepository _repository;
  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSubscription;

  FcmTokenNotifier(this._repository, this._ref) : super(const FcmTokenState()) {
    _initializeFcmToken();
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeFcmToken() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Wait for auth initialization before proceeding
      await _ref.read(authNotifierProvider.notifier).waitForInitialization();

      // Check if user is authenticated
      final authState = _ref.read(authNotifierProvider);
      if (authState.status != AuthStatus.authenticated) {
        if (kDebugMode)
          print('🔥 User not authenticated, skipping FCM token registration');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Get FCM token
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        state = state.copyWith(token: token);

        if (kDebugMode) {
          print('🔥 =========================');
          print('🔥 INITIAL FCM TOKEN:');
          print('🔥 $token');
          print('🔥 =========================');
        }

        // Send initial token to backend
        await _registerTokenWithBackend(token, isInitial: true);

        // Set up token refresh listener
        _setupTokenRefreshListener();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get FCM token',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error initializing FCM token: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupTokenRefreshListener() {
    // Cancel existing subscription if any
    _tokenRefreshSubscription?.cancel();

    // Listen for token refresh events
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(
          (newToken) {
            if (kDebugMode) {
              print('🔥 =========================');
              print('🔥 FCM TOKEN REFRESHED:');
              print('🔥 $newToken');
              print('🔥 Refresh count: ${state.refreshCount + 1}');
              print('🔥 =========================');
            }

            // Update state with new token
            state = state.copyWith(
              token: newToken,
              refreshCount: state.refreshCount + 1,
            );

            // Send refreshed token to backend
            _registerTokenWithBackend(newToken, isRefresh: true);
          },
          onError: (error) {
            if (kDebugMode) print('❌ FCM token refresh error: $error');
            state = state.copyWith(error: 'Token refresh failed: $error');
          },
        );

    if (kDebugMode) {
      print('✅ FCM token refresh listener set up successfully');
    }
  }

  Future<void> _registerTokenWithBackend(
    String token, {
    bool isInitial = false,
    bool isRefresh = false,
  }) async {
    try {
      // Ensure user is authenticated before sending to backend
      final authState = _ref.read(authNotifierProvider);
      if (authState.status != AuthStatus.authenticated) {
        if (kDebugMode)
          print('🔥 User not authenticated, skipping backend registration');
        return;
      }

      final registrationType =
          isInitial ? 'INITIAL' : (isRefresh ? 'REFRESH' : 'UPDATE');

      if (kDebugMode) {
        print('🔥 📤 Sending FCM token to backend ($registrationType)...');
        print('🔥 📤 Token: ${token.substring(0, 30)}...');
        print('🔥 📤 User ID: ${authState.userData?.id ?? 'unknown'}');
      }

      final response = await _repository.registerFcmToken(token);

      state = state.copyWith(
        registrationResponse: response,
        isLoading: false,
        error: null,
        lastRegistered: DateTime.now(),
      );

      if (kDebugMode) {
        print(
          '🔥 ✅ FCM token successfully registered with backend ($registrationType)',
        );
        print('🔥 ✅ Server User ID: ${response.data.endpointArn.data.uId}');
        print(
          '🔥 ✅ Endpoint ARN: ${response.data.endpointArn.data.endpointArn}',
        );
        print('🔥 ✅ Platform: ${response.data.endpointArn.data.platform}');
        print('🔥 ✅ Registration time: ${state.lastRegistered}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to register FCM token with backend: $e');
        if (isRefresh) {
          print('❌ This was a token REFRESH attempt');
        }
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      // Don't throw error - FCM token generation should still work even if backend fails
    }
  }

  Future<void> refreshToken() async {
    if (kDebugMode) print('🔥 Manual FCM token refresh requested');

    // Cancel existing subscription
    _tokenRefreshSubscription?.cancel();

    // Delete current token to force refresh
    await FirebaseMessaging.instance.deleteToken();

    // Re-initialize to get new token
    await _initializeFcmToken();
  }

  // Method to manually register token (useful after login)
  Future<void> registerTokenIfAuthenticated() async {
    final authState = _ref.read(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated) {
      if (state.token != null) {
        if (kDebugMode)
          print('🔥 Registering existing FCM token after authentication');
        await _registerTokenWithBackend(state.token!, isInitial: false);
      } else {
        if (kDebugMode) print('🔥 No existing FCM token, initializing new one');
        await _initializeFcmToken();
      }
    }
  }

  // Method to handle user logout
  void handleUserLogout() {
    if (kDebugMode)
      print('🔥 User logged out, canceling FCM token refresh listener');
    _tokenRefreshSubscription?.cancel();

    // Optionally clear the token state
    state = const FcmTokenState();
  }

  // Method to force re-registration (useful for testing)
  Future<void> forceReRegister() async {
    if (state.token != null) {
      if (kDebugMode) print('🔥 Force re-registering current FCM token');
      await _registerTokenWithBackend(state.token!, isInitial: false);
    }
  }
}

final fcmTokenProvider = StateNotifierProvider<FcmTokenNotifier, FcmTokenState>(
  (ref) {
    final repository = ref.read(fcmRepositoryProvider);
    return FcmTokenNotifier(repository, ref);
  },
);

// Additional providers for easy access
final currentFcmTokenProvider = Provider<String?>((ref) {
  return ref.watch(fcmTokenProvider).token;
});

final fcmRegistrationStatusProvider = Provider<bool>((ref) {
  final state = ref.watch(fcmTokenProvider);
  return state.registrationResponse != null && state.error == null;
});

final fcmTokenRefreshCountProvider = Provider<int>((ref) {
  return ref.watch(fcmTokenProvider).refreshCount;
});
