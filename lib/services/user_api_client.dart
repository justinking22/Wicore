// lib/services/user_api_client.dart
import 'package:Wicore/models/incognito_user_request.dart';
import 'package:Wicore/models/incognito_user_response.dart';
import 'package:Wicore/models/user_response_model.dart';
import 'package:Wicore/models/user_request_model.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api_client.g.dart';

@RestApi()
abstract class UserApiClient {
  factory UserApiClient(Dio dio) = _UserApiClient;

  @GET('/user/{userId}')
  Future<UserResponse> getUser(@Path('userId') String userId);

  /// Create/Update incognito user via POST /user

  @POST('/user')
  Future<IncognitoUserResponse> createOrUpdateIncognitoUser(
    @Body() IncognitoUserRequest request,
  );

  @PATCH('/user/{userId}')
  Future<UserResponse> updateUser(
    @Path('userId') String userId,
    @Body() UserUpdateRequest request,
  );

  @DELETE('/user/{userId}')
  Future<UserResponse> deleteUser(@Path('userId') String userId);
}
