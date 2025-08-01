import 'package:json_annotation/json_annotation.dart';

part 'sign_up_response_model.g.dart';

@JsonSerializable()
class SignUpServerResponse {
  final SignUpData? data;
  final int? code;

  SignUpServerResponse({this.data, this.code});

  factory SignUpServerResponse.fromJson(Map<String, dynamic> json) =>
      _$SignUpServerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SignUpServerResponseToJson(this);

  bool get isSuccess => data?.id != null;
  String get message => isSuccess ? 'Signup successful' : 'Signup failed';
  bool get requiresConfirmation => data?.confirmed == false;
}

@JsonSerializable()
class SignUpData {
  final String? id;
  final bool? confirmed;

  SignUpData({this.id, this.confirmed});

  factory SignUpData.fromJson(Map<String, dynamic> json) =>
      _$SignUpDataFromJson(json);
  Map<String, dynamic> toJson() => _$SignUpDataToJson(this);
}