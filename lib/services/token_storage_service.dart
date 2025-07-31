import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresInKey = 'expires_in';
  static const String _usernameKey = 'username';
  static const String _idKey = 'id';
  static const String _tokenExpirationKey = 'token_expiration';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
    String? username,
    String? id,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    await prefs.setInt(_expiresInKey, expiresIn);
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }
    if (id != null) {
      await prefs.setString(_idKey, id);
    }

    // Calculate and save expiration time
    final expirationTime = DateTime.now().add(Duration(seconds: expiresIn));
    await prefs.setString(
      _tokenExpirationKey,
      expirationTime.toIso8601String(),
    );
  }

  Future<AuthData?> getStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();

    final accessToken = prefs.getString(_accessTokenKey);
    if (accessToken == null) return null;

    return AuthData(
      accessToken: accessToken,
      refreshToken: prefs.getString(_refreshTokenKey),
      expiresIn: prefs.getInt(_expiresInKey),
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

    final expirationTime = DateTime.parse(expirationString);
    return DateTime.now().isAfter(expirationTime);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresInKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_idKey);
    await prefs.remove(_tokenExpirationKey);
  }
}
