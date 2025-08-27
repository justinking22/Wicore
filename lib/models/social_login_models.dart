// lib/models/social_login_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'social_login_models.g.dart';

@JsonSerializable()
class SocialLoginData {
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? expiryDate;
  final String? username;
  final String? userId;
  final String? email;
  final String? provider;

  const SocialLoginData({
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiryDate,
    this.username,
    this.userId,
    this.email,
    this.provider,
  });

  factory SocialLoginData.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginDataFromJson(json);

  Map<String, dynamic> toJson() => _$SocialLoginDataToJson(this);

  @override
  String toString() {
    return 'SocialLoginData{accessToken: ${accessToken?.substring(0, 20)}..., provider: $provider, userId: $userId}';
  }
}

@JsonSerializable()
class SocialLoginServerResponse {
  final bool isSuccess;
  final String? message;
  final SocialLoginData? data;
  final String? errorCode;

  const SocialLoginServerResponse({
    required this.isSuccess,
    this.message,
    this.data,
    this.errorCode,
  });

  factory SocialLoginServerResponse.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginServerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SocialLoginServerResponseToJson(this);

  @override
  String toString() {
    return 'SocialLoginServerResponse{isSuccess: $isSuccess, message: $message, provider: ${data?.provider}}';
  }
}
