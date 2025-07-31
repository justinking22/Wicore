import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/auth_models.dart';

part 'auth_api_client.g.dart';

@RestApi()
abstract class AuthApiClient {
  factory AuthApiClient(Dio dio, {String baseUrl}) = _AuthApiClient;

  @POST('/auth/signup')
  Future<AuthResponse> signUp(@Body() SignUpRequest request);

  @POST('/auth/login')
  Future<AuthResponse> signIn(@Body() SignInRequest request);

  @POST('/auth/logout')
  Future<void> signOut();

  @POST('/auth/refreshtoken')
  Future<AuthResponse> refreshToken(@Body() RefreshTokenRequest request);

  @POST('/auth/forgot-password')
  Future<AuthResponse> forgotPassword(@Body() ForgotPasswordRequest request);

  @POST('/auth/resend-confirmation')
  Future<AuthResponse> resendConfirmation(
    @Body() ForgotPasswordRequest request,
  );

  @POST('/auth/change-password')
  Future<AuthResponse> changePassword(@Body() ChangePasswordRequest request);
}
