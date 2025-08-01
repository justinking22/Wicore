// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInServerResponse _$SignInServerResponseFromJson(
        Map<String, dynamic> json) =>
    SignInServerResponse(
      data: json['data'] == null
          ? null
          : SignInData.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SignInServerResponseToJson(
        SignInServerResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };

SignInData _$SignInDataFromJson(Map<String, dynamic> json) => SignInData(
      expiryDate: json['expiryDate'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      username: json['username'] as String?,
    );

Map<String, dynamic> _$SignInDataToJson(SignInData instance) =>
    <String, dynamic>{
      'expiryDate': instance.expiryDate,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'username': instance.username,
    };
