// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resend_confirmation_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResendConfirmationResponse _$ResendConfirmationResponseFromJson(
        Map<String, dynamic> json) =>
    ResendConfirmationResponse(
      data: json['data'] == null
          ? null
          : ResendConfirmationData.fromJson(
              json['data'] as Map<String, dynamic>),
      code: (json['code'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ResendConfirmationResponseToJson(
        ResendConfirmationResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };

ResendConfirmationData _$ResendConfirmationDataFromJson(
        Map<String, dynamic> json) =>
    ResendConfirmationData(
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ResendConfirmationDataToJson(
        ResendConfirmationData instance) =>
    <String, dynamic>{
      'message': instance.message,
    };
