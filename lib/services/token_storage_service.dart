import 'package:Wicore/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryDateKey = 'expiry_date';
  static const String _usernameKey = 'username';
  static const String _idKey = 'id';
  static const String _tokenExpirationKey = 'token_expiration';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';

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

    // Calculate and save expiration time
    await prefs.setString(_tokenExpirationKey, expiryDate);
  }

  /// Save tokens with optional refresh token expiry
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
    await prefs.setString(_tokenExpirationKey, expiryDate);

    if (refreshTokenExpiry != null) {
      await prefs.setString(_refreshTokenExpiryKey, refreshTokenExpiry);
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

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString(_tokenExpirationKey);

    if (expirationString == null) return true;

    try {
      final expirationTime = DateTime.parse(expirationString);
      // Add a small buffer (e.g., 30 seconds) to avoid edge cases
      final bufferTime = DateTime.now().add(const Duration(seconds: 30));
      return expirationTime.isBefore(bufferTime);
    } catch (e) {
      // If parsing fails, consider token expired
      return true;
    }
  }

  Future<bool> isRefreshTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return true;

      // Check if we have a specific refresh token expiry stored
      final refreshTokenExpiryString = prefs.getString(_refreshTokenExpiryKey);

      if (refreshTokenExpiryString != null) {
        final refreshTokenExpiry = DateTime.tryParse(refreshTokenExpiryString);
        if (refreshTokenExpiry != null) {
          final now = DateTime.now();
          // Add a small buffer (e.g., 1 minute) to avoid edge cases
          final bufferTime = now.add(const Duration(minutes: 1));
          return refreshTokenExpiry.isBefore(bufferTime);
        }
      }

      // If no specific refresh token expiry is stored,
      // assume refresh tokens are valid for a longer period than access tokens
      final accessTokenExpiryString = prefs.getString(_expiryDateKey);
      if (accessTokenExpiryString != null) {
        final accessTokenExpiry = DateTime.tryParse(accessTokenExpiryString);
        if (accessTokenExpiry != null) {
          // Assume refresh token expires 30 days after access token
          // You should adjust this based on your server's actual refresh token expiry
          final refreshTokenExpiry = accessTokenExpiry.add(
            const Duration(days: 30),
          );
          final now = DateTime.now();
          final bufferTime = now.add(const Duration(minutes: 1));
          return refreshTokenExpiry.isBefore(bufferTime);
        }
      }

      // If we can't determine expiry, assume it's expired for safety
      return true;
    } catch (e) {
      // If there's any error, assume expired for safety
      return true;
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiryDateKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_idKey);
    await prefs.remove(_tokenExpirationKey);
    await prefs.remove(_refreshTokenExpiryKey);
  }

  /// Clear all tokens including refresh token expiry (alias for clearTokens)
  Future<void> clearAllTokens() async {
    await clearTokens();
  }

  /// Check if user has valid tokens (not expired)
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      return false;
    }

    // If access token is not expired, we have valid tokens
    if (!(await isTokenExpired())) {
      return true;
    }

    // If access token is expired but refresh token is not, we can still refresh
    return !(await isRefreshTokenExpired());
  }

  /// Get the expiry date string for access token
  Future<String?> getAccessTokenExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_expiryDateKey);
  }

  /// Get the expiry date string for refresh token
  Future<String?> getRefreshTokenExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenExpiryKey);
  }
}
