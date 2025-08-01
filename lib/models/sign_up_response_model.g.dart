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
    );

Map<String, dynamic> _$SignUpServerResponseToJson(
        SignUpServerResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
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
