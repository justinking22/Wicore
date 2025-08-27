// lib/models/incognito_user_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'incognito_user.dart';

part 'incognito_user_response.g.dart';

@JsonSerializable()
class IncognitoUserResponse {
  final bool success;
  final String? message;
  final IncognitoUser? data;
  final String? incognitoUserId;

  const IncognitoUserResponse({
    required this.success,
    this.message,
    this.data,
    this.incognitoUserId,
  });

  factory IncognitoUserResponse.fromJson(Map<String, dynamic> json) =>
      _$IncognitoUserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$IncognitoUserResponseToJson(this);
}
