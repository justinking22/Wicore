import 'package:json_annotation/json_annotation.dart';

part 'change_password_request_model.g.dart';
@JsonSerializable()
class ChangePasswordRequest {
  final String email;
  final String newPassword;
  final String confirmationCode;

  ChangePasswordRequest({
    required this.email,
    required this.newPassword,
    required this.confirmationCode,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}