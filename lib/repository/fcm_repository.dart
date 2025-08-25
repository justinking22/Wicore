import 'package:flutter/foundation.dart';
import 'package:Wicore/services/fcm_api_client.dart';
import 'package:Wicore/models/fcm_notification_model.dart';
import 'package:Wicore/models/emergency_resolve_model.dart'; // Add this import

class FcmRepository {
  final FcmApiClient _apiClient;

  FcmRepository(this._apiClient);

  // Your existing FCM token registration method
  Future<FcmServerResponse> registerFcmToken(String deviceToken) async {
    try {
      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

      final request = FcmTokenRequest(
        deviceToken: deviceToken,
        platform: platform,
      );

      if (kDebugMode) {
        print('📤 Registering FCM token...');
        print('📤 Platform: $platform');
        print('📤 Token: ${deviceToken.substring(0, 20)}...');
      }

      final response = await _apiClient.registerFcmToken(request);

      if (kDebugMode) {
        print('✅ FCM token registered successfully');
        print('✅ Endpoint ARN: ${response.data.endpointArn.data.endpointArn}');
        print('✅ User ID: ${response.data.endpointArn.data.uId}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to register FCM token: $e');
      }
      rethrow;
    }
  }

  // 🔥 NEW: Emergency resolve - Just call the endpoint, no parameters needed
  Future<EmergencyResolveResponse> resolveEmergency() async {
    try {
      if (kDebugMode) {
        print('🚨 Calling /notifications/resolve endpoint...');
        print('🚨 No parameters needed - just calling the endpoint');
      }

      // Simple call with no parameters
      final response = await _apiClient.resolveEmergency();

      if (kDebugMode) {
        print('✅ Emergency resolve endpoint called successfully');
        print('✅ Response code: ${response.code}');
        print('✅ Data code: ${response.data.code}');
        print('✅ Success: ${response.isSuccess}');
        print('✅ Emergency items returned: ${response.emergencyItems.length}');

        if (response.emergencyItems.isNotEmpty) {
          print('✅ Sample emergency item:');
          final item = response.emergencyItems.first;
          print('   - Device ID: ${item.dId}');
          print('   - User ID: ${item.uId}');
          print('   - Resolved: ${item.isResolved ? "Yes" : "No"}');
          print('   - Updated: ${item.updated}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to call resolve emergency endpoint: $e');
      }
      rethrow;
    }
  }
}
