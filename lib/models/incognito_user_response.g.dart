// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incognito_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncognitoUserResponse _$IncognitoUserResponseFromJson(
        Map<String, dynamic> json) =>
    IncognitoUserResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : IncognitoUser.fromJson(json['data'] as Map<String, dynamic>),
      incognitoUserId: json['incognitoUserId'] as String?,
    );

Map<String, dynamic> _$IncognitoUserResponseToJson(
        IncognitoUserResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'incognitoUserId': instance.incognitoUserId,
    };
