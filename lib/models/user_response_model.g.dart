// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
      data: UserItem.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String,
    );

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
      'msg': instance.msg,
    };

UserErrorResponse _$UserErrorResponseFromJson(Map<String, dynamic> json) =>
    UserErrorResponse(
      error: json['error'] as String,
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String,
    );

Map<String, dynamic> _$UserErrorResponseToJson(UserErrorResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'code': instance.code,
      'msg': instance.msg,
    };
