import 'package:json_annotation/json_annotation.dart';
import 'incognito_user.dart';

part 'incognito_user_request.g.dart';

@JsonSerializable()
class IncognitoUserRequest {
  final IncognitoUser item;

  const IncognitoUserRequest({required this.item});

  factory IncognitoUserRequest.fromJson(Map<String, dynamic> json) =>
      _$IncognitoUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$IncognitoUserRequestToJson(this);
}
