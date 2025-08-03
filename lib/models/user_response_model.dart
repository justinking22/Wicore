import 'package:json_annotation/json_annotation.dart';
import 'package:Wicore/models/user_request_model.dart';

part 'user_response_model.g.dart';

@JsonSerializable()
class UserResponse {
  final UserItem data;
  final int code;
  final String msg;

  const UserResponse({
    required this.data,
    required this.code,
    required this.msg,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}

@JsonSerializable()
class UserErrorResponse {
  final String error;
  final int code;
  final String msg;

  const UserErrorResponse({
    required this.error,
    required this.code,
    required this.msg,
  });

  factory UserErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$UserErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserErrorResponseToJson(this);
}
