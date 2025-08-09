import 'package:Wicore/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryDateKey = 'expiry_date';
  static const String _usernameKey = 'username';
  static const String _idKey = 'id';
  static const String _emailKey = 'email';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';

  /// Save tokens from sign-in response (has expiryDate, refreshToken)
  Future<void> saveSignInTokens({
    required String accessToken,
    required String refreshToken,
    required String expiryDate, // ISO format from sign-in
    required String username,
    String? id,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_expiryDateKey, expiryDate); // Use as-is (ISO format)
    await prefs.setString(_usernameKey, username);

    if (id != null) {
      await prefs.setString(_idKey, id);
    }

    if (email != null) {
      await prefs.setString(_emailKey, email);
    }

    if (kDebugMode) {
      print('💾 Saved sign-in tokens:');
      print('   Access token: ${accessToken.substring(0, 20)}...');
      print('   Refresh token: ${refreshToken.substring(0, 20)}...');
      print('   Expiry date (ISO): $expiryDate');
      print('   Username: $username');
    }
  }

  /// Save tokens from refresh response (has expiresIn, no refreshToken)
  Future<void> saveRefreshTokens({
    required String accessToken,
    required int expiresInSeconds, // Seconds format from refresh
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert expiresIn to ISO date format to match sign-in format
    final now = DateTime.now();
    final expiry = now.add(Duration(seconds: expiresInSeconds));
    final expiryDate = expiry.toIso8601String();

    // Update only access token and expiry date
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_expiryDateKey, expiryDate); // Convert to ISO format
    await prefs.setString(_usernameKey, username);

    // Keep existing refresh token - don't change it

    if (kDebugMode) {
      print('💾 Saved refresh tokens:');
      print('   New access token: ${accessToken.substring(0, 20)}...');
      print('   Converted expiresIn ($expiresInSeconds s) to ISO: $expiryDate');
      print('   Kept existing refresh token');
    }
  }

  /// Generic save method (for backwards compatibility)
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    required String expiryDate,
    String? username,
    String? id,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    await prefs.setString(_expiryDateKey, expiryDate);
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }
    if (id != null) {
      await prefs.setString(_idKey, id);
    }

    if (kDebugMode) {
      print('💾 Saved tokens (generic method):');
      print('   Access token expiry: $expiryDate');
      print(
        '   Refresh token: ${refreshToken != null ? "Updated" : "Not changed"}',
      );
    }
  }

  /// Save tokens with optional refresh token expiry (for future use)
  Future<void> saveTokensWithRefreshExpiry({
    required String accessToken,
    required String refreshToken,
    required String expiryDate,
    required String username,
    required String id,
    String? refreshTokenExpiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_expiryDateKey, expiryDate);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_idKey, id);

    if (refreshTokenExpiry != null) {
      await prefs.setString(_refreshTokenExpiryKey, refreshTokenExpiry);
      if (kDebugMode) {
        print('💾 Saved tokens with refresh expiry:');
        print('   Access expiry: $expiryDate');
        print('   Refresh expiry: $refreshTokenExpiry');
      }
    } else {
      if (kDebugMode) {
        print('💾 Saved tokens without refresh expiry');
      }
    }
  }

  Future<UserData?> getStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();

    final accessToken = prefs.getString(_accessTokenKey);
    if (accessToken == null) return null;

    return UserData(
      accessToken: accessToken,
      refreshToken: prefs.getString(_refreshTokenKey),
      expiryDate: prefs.getString(_expiryDateKey),
      username: prefs.getString(_usernameKey),
      id: prefs.getString(_idKey),
      email: prefs.getString(_emailKey),
    );
  }

  /// Alias for getStoredTokens to match your auth repository expectations
  Future<UserData?> getStoredAuthData() async {
    return await getStoredTokens();
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Get the token expiry date string (required by TokenRefreshManager)
  Future<String?> getTokenExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_expiryDateKey);
  }

  /// Get the expiry date string for access token (alias for consistency)
  Future<String?> getAccessTokenExpiryDate() async {
    return await getTokenExpiryDate();
  }

  /// Get the expiry date string for refresh token
  Future<String?> getRefreshTokenExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenExpiryKey);
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString(_expiryDateKey);

    if (expirationString == null) {
      if (kDebugMode)
        print('⏰ No expiration date found, considering token expired');
      return true;
    }

    try {
      final expirationTime = DateTime.parse(expirationString);
      final now = DateTime.now();
      // Add a small buffer (30 seconds) to avoid edge cases
      final bufferTime = now.add(const Duration(seconds: 30));
      final isExpired = expirationTime.isBefore(bufferTime);

      if (kDebugMode) {
        print('⏰ Token expiry check:');
        print('   Current time: $now');
        print('   Token expires: $expirationTime');
        print('   Buffer time: $bufferTime');
        print('   Is expired: $isExpired');
      }

      return isExpired;
    } catch (e) {
      if (kDebugMode) print('⏰ Error parsing expiration date: $e');
      return true;
    }
  }

  Future<bool> isRefreshTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = await getRefreshToken();

      if (refreshToken == null) {
        if (kDebugMode) print('🔄 No refresh token found, considering expired');
        return true;
      }

      // Check if we have a specific refresh token expiry stored
      final refreshTokenExpiryString = prefs.getString(_refreshTokenExpiryKey);

      if (refreshTokenExpiryString != null) {
        final refreshTokenExpiry = DateTime.tryParse(refreshTokenExpiryString);
        if (refreshTokenExpiry != null) {
          final now = DateTime.now();
          final bufferTime = now.add(const Duration(minutes: 1));
          final isExpired = refreshTokenExpiry.isBefore(bufferTime);

          if (kDebugMode) {
            print('🔄 Refresh token expiry check (with stored expiry):');
            print('   Current time: $now');
            print('   Refresh token expires: $refreshTokenExpiry');
            print('   Is expired: $isExpired');
          }

          return isExpired;
        }
      }

      // Since your server doesn't provide refresh token expiry,
      // assume refresh tokens last much longer than access tokens (e.g., 30 days)
      final accessTokenExpiryString = prefs.getString(_expiryDateKey);
      if (accessTokenExpiryString != null) {
        final accessTokenExpiry = DateTime.tryParse(accessTokenExpiryString);
        if (accessTokenExpiry != null) {
          // Assume refresh token expires 30 days after the access token was issued
          final refreshTokenExpiry = accessTokenExpiry.add(
            const Duration(days: 30),
          );
          final now = DateTime.now();
          final bufferTime = now.add(const Duration(minutes: 5));
          final isExpired = refreshTokenExpiry.isBefore(bufferTime);

          if (kDebugMode) {
            print('🔄 Refresh token expiry check (estimated):');
            print('   Access token expires: $accessTokenExpiry');
            print('   Estimated refresh token expires: $refreshTokenExpiry');
            print('   Is expired: $isExpired');
          }

          return isExpired;
        }
      }

      // If we can't determine expiry, assume it's still valid for safety
      // This is more lenient since refresh tokens typically last much longer
      if (kDebugMode)
        print('🔄 Cannot determine refresh token expiry, assuming valid');
      return false;
    } catch (e) {
      if (kDebugMode) print('🔄 Error checking refresh token expiry: $e');
      return true;
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();

    if (kDebugMode) print('🗑️ Clearing all stored tokens');

    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiryDateKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_idKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_refreshTokenExpiryKey);
  }

  /// Check if user has valid tokens (not expired)
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null) {
      if (kDebugMode) print('✅ No access token found');
      return false;
    }

    if (refreshToken == null) {
      if (kDebugMode) print('✅ No refresh token found');
      // Without refresh token, we can only check if access token is valid
      final isAccessExpired = await isTokenExpired();
      return !isAccessExpired;
    }

    // If access token is not expired, we have valid tokens
    final isAccessExpired = await isTokenExpired();
    if (!isAccessExpired) {
      if (kDebugMode) print('✅ Access token is still valid');
      return true;
    }

    // If access token is expired but refresh token is not, we can still refresh
    final isRefreshExpired = await isRefreshTokenExpired();
    final hasValidRefresh = !isRefreshExpired;

    if (kDebugMode) {
      print('✅ Token validity check:');
      print('   Access token expired: $isAccessExpired');
      print('   Refresh token expired: $isRefreshExpired');
      print('   Can refresh: $hasValidRefresh');
    }

    return hasValidRefresh;
  }

  /// Get time remaining until token expires (for debugging)
  Future<Duration?> getTimeUntilTokenExpiry() async {
    final expiryString = await getTokenExpiryDate();
    if (expiryString == null) return null;

    try {
      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();
      return expiry.difference(now);
    } catch (e) {
      return null;
    }
  }

  /// Get time remaining until refresh token expires (for debugging)
  Future<Duration?> getTimeUntilRefreshTokenExpiry() async {
    final refreshExpiryString = await getRefreshTokenExpiryDate();

    if (refreshExpiryString != null) {
      try {
        final expiry = DateTime.parse(refreshExpiryString);
        final now = DateTime.now();
        return expiry.difference(now);
      } catch (e) {
        return null;
      }
    }

    // Fallback to estimated expiry (30 days from access token)
    final accessExpiryString = await getTokenExpiryDate();
    if (accessExpiryString != null) {
      try {
        final accessExpiry = DateTime.parse(accessExpiryString);
        final estimatedRefreshExpiry = accessExpiry.add(
          const Duration(days: 30),
        );
        final now = DateTime.now();
        return estimatedRefreshExpiry.difference(now);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Debug method to print all stored token information
  Future<void> debugPrintTokenInfo() async {
    if (!kDebugMode) return;

    final prefs = await SharedPreferences.getInstance();

    print('🔍 === TOKEN DEBUG INFO ===');
    print(
      'Access Token: ${prefs.getString(_accessTokenKey)?.substring(0, 20) ?? 'null'}...',
    );
    print(
      'Refresh Token: ${prefs.getString(_refreshTokenKey)?.substring(0, 20) ?? 'null'}...',
    );
    print('Access Token Expiry: ${prefs.getString(_expiryDateKey) ?? 'null'}');
    print(
      'Refresh Token Expiry: ${prefs.getString(_refreshTokenExpiryKey) ?? 'null (estimated)'}',
    );
    print('Username: ${prefs.getString(_usernameKey) ?? 'null'}');
    print('Email: ${prefs.getString(_emailKey) ?? 'null'}');
    print('ID: ${prefs.getString(_idKey) ?? 'null'}');
    print('Current Time: ${DateTime.now()}');

    final timeUntilExpiry = await getTimeUntilTokenExpiry();
    if (timeUntilExpiry != null) {
      print(
        'Time Until Access Token Expires: ${timeUntilExpiry.inMinutes} minutes',
      );
    }

    final timeUntilRefreshExpiry = await getTimeUntilRefreshTokenExpiry();
    if (timeUntilRefreshExpiry != null) {
      print(
        'Time Until Refresh Token Expires: ${timeUntilRefreshExpiry.inDays} days',
      );
    }

    print('Access Token Expired: ${await isTokenExpired()}');
    print('Refresh Token Expired: ${await isRefreshTokenExpired()}');
    print('Has Valid Tokens: ${await hasValidTokens()}');
    print('🔍 === END TOKEN DEBUG ===');
  }

  /// Validate stored token data integrity
  Future<bool> validateStoredData() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final expiryDate = await getTokenExpiryDate();

      if (accessToken == null) {
        if (kDebugMode) print('⚠️ Missing access token');
        return false;
      }

      if (refreshToken == null) {
        if (kDebugMode) print('⚠️ Missing refresh token');
        return false;
      }

      if (expiryDate == null) {
        if (kDebugMode) print('⚠️ Missing expiry date');
        return false;
      }

      // Try to parse expiry date
      try {
        DateTime.parse(expiryDate);
      } catch (e) {
        if (kDebugMode) print('⚠️ Invalid expiry date format: $expiryDate');
        return false;
      }

      if (kDebugMode) print('✅ Stored token data is valid');
      return true;
    } catch (e) {
      if (kDebugMode) print('⚠️ Error validating stored data: $e');
      return false;
    }
  }
}
