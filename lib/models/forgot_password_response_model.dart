import 'package:json_annotation/json_annotation.dart';

part 'forgot_password_response_model.g.dart';

@JsonSerializable()
class ForgotPasswordResponse {
  final ForgotPasswordData? data;
  final int? code;

  ForgotPasswordResponse({this.data, this.code});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ForgotPasswordResponseToJson(this);

  bool get isSuccess => data?.message != null;
  String get message => data?.message ?? 'Password reset request processed';
}

@JsonSerializable()
class ForgotPasswordData {
  final String? message;

  ForgotPasswordData({this.message});

  factory ForgotPasswordData.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordDataFromJson(json);
  Map<String, dynamic> toJson() => _$ForgotPasswordDataToJson(this);
}