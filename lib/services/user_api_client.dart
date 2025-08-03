import 'package:Wicore/models/user_response_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:Wicore/models/user_request_model.dart';

part 'user_api_client.g.dart';

@RestApi()
abstract class UserApiClient {
  factory UserApiClient(Dio dio) = _UserApiClient;

  @POST('/user')
  Future<UserResponse> createUser(@Body() UserRequest request);

  @GET('/user/{userId}')
  Future<UserResponse> getUser(@Path('userId') String userId);

  @PATCH('/user/{userId}')
  Future<UserResponse> updateUser(
    @Path('userId') String userId,
    @Body() UserRequest request,
  );

  @DELETE('/user/{userId}')
  Future<UserResponse> deleteUser(@Path('userId') String userId);
}
