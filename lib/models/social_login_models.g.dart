// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_login_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialLoginData _$SocialLoginDataFromJson(Map<String, dynamic> json) =>
    SocialLoginData(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      idToken: json['idToken'] as String?,
      expiryDate: json['expiryDate'] as String?,
      username: json['username'] as String?,
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      provider: json['provider'] as String?,
    );

Map<String, dynamic> _$SocialLoginDataToJson(SocialLoginData instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'idToken': instance.idToken,
      'expiryDate': instance.expiryDate,
      'username': instance.username,
      'userId': instance.userId,
      'email': instance.email,
      'provider': instance.provider,
    };

SocialLoginServerResponse _$SocialLoginServerResponseFromJson(
        Map<String, dynamic> json) =>
    SocialLoginServerResponse(
      isSuccess: json['isSuccess'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : SocialLoginData.fromJson(json['data'] as Map<String, dynamic>),
      errorCode: json['errorCode'] as String?,
    );

Map<String, dynamic> _$SocialLoginServerResponseToJson(
        SocialLoginServerResponse instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'message': instance.message,
      'data': instance.data,
      'errorCode': instance.errorCode,
    };
