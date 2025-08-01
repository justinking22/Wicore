import 'package:Wicore/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryDateKey = 'expiry_date';
  static const String _usernameKey = 'username';
  static const String _idKey = 'id';
  static const String _tokenExpirationKey = 'token_expiration';

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

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString(_tokenExpirationKey);

    if (expirationString == null) return true;

    try {
      final expirationTime = DateTime.parse(expirationString);
      return DateTime.now().isAfter(expirationTime);
    } catch (e) {
      // If parsing fails, consider token expired
      return true;
    }
  }

  // ✅ Fixed method signature and implementation
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiryDateKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_idKey);
    await prefs.remove(_tokenExpirationKey);
  }
}
