import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:Wicore/models/fcm_notification_model.dart';

part 'fcm_api_client.g.dart';

@RestApi()
abstract class FcmApiClient {
  factory FcmApiClient(Dio dio, {String baseUrl}) = _FcmApiClient;

  @POST('/notifications/register')
  Future<FcmServerResponse> registerFcmToken(@Body() FcmTokenRequest request);
}
