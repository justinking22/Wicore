// lib/services/incognito_user_service.dart
import 'package:Wicore/models/notification_preferences_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/incognito_user.dart';

class IncognitoUserService {
  static const String _incognitoUserIdKey = 'incognito_user_id';
  static const String _incognitoUserDataKey = 'incognito_user_data';
  static const String _isIncognitoModeKey = 'is_incognito_mode';

  /// Save incognito user ID
  Future<void> saveIncognitoUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_incognitoUserIdKey, userId);
    await prefs.setBool(_isIncognitoModeKey, true);

    if (kDebugMode) {
      print('💾 Saved incognito user ID: $userId');
    }
  }

  /// Get incognito user ID
  Future<String?> getIncognitoUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_incognitoUserIdKey);
  }

  /// Save incognito user data locally
  Future<void> saveIncognitoUserData(IncognitoUser userData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(userData.toJson());
    await prefs.setString(_incognitoUserDataKey, jsonString);

    if (kDebugMode) {
      print('💾 Saved incognito user data locally');
    }
  }

  /// Get incognito user data from local storage
  Future<IncognitoUser?> getIncognitoUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_incognitoUserDataKey);

      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return IncognitoUser.fromJson(jsonMap);
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting incognito user data: $e');
      return null;
    }
  }

  /// Check if user is in incognito mode
  Future<bool> isIncognitoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isIncognitoModeKey) ?? false;
  }

  /// Set incognito mode status
  Future<void> setIncognitoMode(bool isIncognito) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isIncognitoModeKey, isIncognito);

    if (kDebugMode) {
      print('💾 Set incognito mode: $isIncognito');
    }
  }

  /// Clear all incognito data
  Future<void> clearIncognitoData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_incognitoUserIdKey);
    await prefs.remove(_incognitoUserDataKey);
    await prefs.setBool(_isIncognitoModeKey, false);

    if (kDebugMode) {
      print('🗑️ Cleared all incognito data');
    }
  }

  /// Debug method to print all incognito data
  Future<void> debugPrintIncognitoInfo() async {
    if (!kDebugMode) return;

    final userId = await getIncognitoUserId();
    final userData = await getIncognitoUserData();
    final isIncognito = await isIncognitoMode();

    print('🔍 === INCOGNITO DEBUG INFO ===');
    print('Is Incognito Mode: $isIncognito');
    print('Incognito User ID: $userId');
    print('Incognito User Data: ${userData?.firstName ?? 'null'}');
    print('Incognito User Email: ${userData?.email ?? 'null'}');
    print('🔍 === END INCOGNITO DEBUG ===');
  }

  /// Generate a temporary incognito user ID (for offline use)
  String generateTempIncognitoId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 31) % 100000;
    return 'temp_incognito_$random';
  }

  /// Create default incognito user data
  IncognitoUser createDefaultIncognitoUser({String? email, String? firstName}) {
    return IncognitoUser(
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
}
