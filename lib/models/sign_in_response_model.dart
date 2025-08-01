import 'package:json_annotation/json_annotation.dart';

part 'sign_in_response_model.g.dart';

@JsonSerializable()
class SignInServerResponse {
  final SignInData? data;
  final int? code;

  SignInServerResponse({this.data, this.code});

  factory SignInServerResponse.fromJson(Map<String, dynamic> json) =>
      _$SignInServerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SignInServerResponseToJson(this);

  bool get isSuccess => data?.accessToken != null;
  String get message => isSuccess ? 'Login successful' : 'Login failed';
}

@JsonSerializable()
class SignInData {
  final String? expiryDate;
  final String? accessToken;
  final String? refreshToken;
  final String? username;

  SignInData({
    this.expiryDate,
    this.accessToken,
    this.refreshToken,
    this.username,
  });

  factory SignInData.fromJson(Map<String, dynamic> json) =>
      _$SignInDataFromJson(json);
  Map<String, dynamic> toJson() => _$SignInDataToJson(this);

  // Helper method to calculate expiry seconds
  int? get expiresInSeconds {
    if (expiryDate == null) return null;
    final expiryDateTime = DateTime.parse(expiryDate!);
    final now = DateTime.now();
    return expiryDateTime.difference(now).inSeconds;
  }
}
