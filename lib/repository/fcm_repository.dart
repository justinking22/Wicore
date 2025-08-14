import 'package:flutter/foundation.dart';
import 'package:Wicore/services/fcm_api_client.dart';
import 'package:Wicore/models/fcm_notification_model.dart';

class FcmRepository {
  final FcmApiClient _apiClient;

  FcmRepository(this._apiClient);

  Future<FcmServerResponse> registerFcmToken(String deviceToken) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      
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
}