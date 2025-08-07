import 'package:json_annotation/json_annotation.dart';
import 'package:Wicore/models/user_request_model.dart';

part 'user_response_model.g.dart';

@JsonSerializable()
class UserResponse {
  @JsonKey(defaultValue: null)
  final UserItem? data; // Made nullable
  @JsonKey(defaultValue: 0)
  final int code;
  @JsonKey(defaultValue: '')
  final String msg;

  const UserResponse({
    this.data, // Nullable
    required this.code,
    required this.msg,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}

@JsonSerializable()
class UserErrorResponse {
  @JsonKey(defaultValue: '')
  final String error;
  @JsonKey(defaultValue: 0)
  final int code;
  @JsonKey(defaultValue: '')
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
