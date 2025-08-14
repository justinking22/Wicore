// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_unpair_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceUnpairResponse _$DeviceUnpairResponseFromJson(
        Map<String, dynamic> json) =>
    DeviceUnpairResponse(
      data: json['data'] == null
          ? null
          : DeviceUnpairData.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num).toInt(),
      error: json['error'] as String?,
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$DeviceUnpairResponseToJson(
        DeviceUnpairResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
      'error': instance.error,
      'msg': instance.msg,
    };

DeviceUnpairData _$DeviceUnpairDataFromJson(Map<String, dynamic> json) =>
    DeviceUnpairData(
      deviceId: json['dId'] as String,
      userId: json['uId'] as String,
      status: json['status'] as String,
      created: json['created'] as String,
      updated: json['updated'] as String,
      expiryDate: json['expiryDate'] as String,
      deviceStrength: (json['deviceStrength'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$DeviceUnpairDataToJson(DeviceUnpairData instance) =>
    <String, dynamic>{
      'dId': instance.deviceId,
      'uId': instance.userId,
      'status': instance.status,
      'created': instance.created,
      'updated': instance.updated,
      'expiryDate': instance.expiryDate,
      'deviceStrength': instance.deviceStrength,
      'offset': instance.offset,
    };
