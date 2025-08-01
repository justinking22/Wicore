// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_password_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangePasswordResponse _$ChangePasswordResponseFromJson(
        Map<String, dynamic> json) =>
    ChangePasswordResponse(
      data: json['data'] == null
          ? null
          : ChangePasswordData.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChangePasswordResponseToJson(
        ChangePasswordResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };

ChangePasswordData _$ChangePasswordDataFromJson(Map<String, dynamic> json) =>
    ChangePasswordData(
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ChangePasswordDataToJson(ChangePasswordData instance) =>
    <String, dynamic>{
      'message': instance.message,
    };
