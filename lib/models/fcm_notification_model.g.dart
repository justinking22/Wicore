// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FcmTokenRequest _$FcmTokenRequestFromJson(Map<String, dynamic> json) =>
    FcmTokenRequest(
      deviceToken: json['deviceToken'] as String,
      platform: json['platform'] as String,
    );

Map<String, dynamic> _$FcmTokenRequestToJson(FcmTokenRequest instance) =>
    <String, dynamic>{
      'deviceToken': instance.deviceToken,
      'platform': instance.platform,
    };

EndpointArnData _$EndpointArnDataFromJson(Map<String, dynamic> json) =>
    EndpointArnData(
      uId: json['uId'] as String,
      platform: json['platform'] as String,
      endpointArn: json['endpointArn'] as String,
      offset: (json['offset'] as num).toInt(),
      created: json['created'] as String,
      updated: json['updated'] as String,
    );

Map<String, dynamic> _$EndpointArnDataToJson(EndpointArnData instance) =>
    <String, dynamic>{
      'uId': instance.uId,
      'platform': instance.platform,
      'endpointArn': instance.endpointArn,
      'offset': instance.offset,
      'created': instance.created,
      'updated': instance.updated,
    };

EndpointArnResponse _$EndpointArnResponseFromJson(Map<String, dynamic> json) =>
    EndpointArnResponse(
      data: EndpointArnData.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num).toInt(),
    );

Map<String, dynamic> _$EndpointArnResponseToJson(
        EndpointArnResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };

FcmTokenResponse _$FcmTokenResponseFromJson(Map<String, dynamic> json) =>
    FcmTokenResponse(
      endpointArn: EndpointArnResponse.fromJson(
          json['endpointArn'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FcmTokenResponseToJson(FcmTokenResponse instance) =>
    <String, dynamic>{
      'endpointArn': instance.endpointArn,
    };

FcmServerResponse _$FcmServerResponseFromJson(Map<String, dynamic> json) =>
    FcmServerResponse(
      data: FcmTokenResponse.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num).toInt(),
    );

Map<String, dynamic> _$FcmServerResponseToJson(FcmServerResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };
