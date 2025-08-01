// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceResponse _$DeviceResponseFromJson(Map<String, dynamic> json) =>
    DeviceResponse(
      data: json['data'] == null
          ? null
          : DeviceResponseData.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
      msg: json['msg'] as String?,
      code: (json['code'] as num).toInt(),
    );

Map<String, dynamic> _$DeviceResponseToJson(DeviceResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'error': instance.error,
      'msg': instance.msg,
      'code': instance.code,
    };

DeviceResponseData _$DeviceResponseDataFromJson(Map<String, dynamic> json) =>
    DeviceResponseData(
      deviceId: json['dId'] as String,
      offset: (json['offset'] as num).toInt(),
      userId: json['uId'] as String,
      expiryDate: json['expiryDate'] as String,
      status: json['status'] as String,
      deviceStrength: (json['deviceStrength'] as num).toInt(),
      created: json['created'] as String,
      updated: json['updated'] as String,
    );

Map<String, dynamic> _$DeviceResponseDataToJson(DeviceResponseData instance) =>
    <String, dynamic>{
      'dId': instance.deviceId,
      'offset': instance.offset,
      'uId': instance.userId,
      'expiryDate': instance.expiryDate,
      'status': instance.status,
      'deviceStrength': instance.deviceStrength,
      'created': instance.created,
      'updated': instance.updated,
    };
