import 'package:json_annotation/json_annotation.dart';

part 'change_password_response_model.g.dart';

@JsonSerializable()
class ChangePasswordResponse {
  final ChangePasswordData? data;
  final int? code;

  ChangePasswordResponse({this.data, this.code});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordResponseToJson(this);

  bool get isSuccess => data?.message != null;
  String get message => data?.message ?? 'Password changed successfully';
}

@JsonSerializable()
class ChangePasswordData {
  final String? message;

  ChangePasswordData({this.message});

  factory ChangePasswordData.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordDataFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordDataToJson(this);
}