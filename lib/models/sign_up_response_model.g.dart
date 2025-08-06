// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUpServerResponse _$SignUpServerResponseFromJson(
        Map<String, dynamic> json) =>
    SignUpServerResponse(
      data: json['data'] == null
          ? null
          : SignUpData.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num?)?.toInt(),
      msg: json['msg'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$SignUpServerResponseToJson(
        SignUpServerResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
      'msg': instance.msg,
      'error': instance.error,
    };

SignUpData _$SignUpDataFromJson(Map<String, dynamic> json) => SignUpData(
      id: json['id'] as String?,
      confirmed: json['confirmed'] as bool?,
    );

Map<String, dynamic> _$SignUpDataToJson(SignUpData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'confirmed': instance.confirmed,
    };
