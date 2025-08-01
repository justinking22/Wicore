import 'package:Wicore/models/change_password_request_model.dart';
import 'package:Wicore/models/change_password_response_model.dart';
import 'package:Wicore/models/forgot_password_request_model.dart';
import 'package:Wicore/models/forgot_password_response_model.dart';
import 'package:Wicore/models/refresh_token_request_model.dart';
import 'package:Wicore/models/refresh_token_response_model.dart';
import 'package:Wicore/models/resend_confirmation_request_model.dart';
import 'package:Wicore/models/resend_confirmation_response_model.dart';
import 'package:Wicore/models/sign_in_request_model.dart';
import 'package:Wicore/models/sign_in_response_model.dart';
import 'package:Wicore/models/sign_up_request_model.dart';
import 'package:Wicore/models/sign_up_response_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api_client.g.dart';

@RestApi()
abstract class AuthApiClient {
  factory AuthApiClient(Dio dio, {String baseUrl}) = _AuthApiClient;

  @POST('/auth/signup')
  Future<SignUpServerResponse> signUp(@Body() SignUpRequest request);

  @POST('/auth/login')
  Future<SignInServerResponse> signIn(@Body() SignInRequest request);

  @POST('/auth/refresh-token')
  Future<RefreshTokenResponse> refreshToken(
    @Body() RefreshTokenRequest request,
  );

  @POST('/auth/forgot-password')
  Future<ForgotPasswordResponse> forgotPassword(
    @Body() ForgotPasswordRequest request,
  );

  @POST('/auth/resend-confirmation')
  Future<ResendConfirmationResponse> resendConfirmation(
    @Body() ResendConfirmationRequest request,
  );

  @POST('/auth/change-password')
  Future<ChangePasswordResponse> changePassword(
    @Body() ChangePasswordRequest request,
  );
}
