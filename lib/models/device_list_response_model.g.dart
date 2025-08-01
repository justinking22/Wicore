// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceListResponse _$DeviceListResponseFromJson(Map<String, dynamic> json) =>
    DeviceListResponse(
      devices: (json['data'] as List<dynamic>?)
          ?.map((e) => DeviceListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$DeviceListResponseToJson(DeviceListResponse instance) =>
    <String, dynamic>{
      'data': instance.devices,
      'error': instance.error,
      'code': instance.code,
      'msg': instance.msg,
    };

DeviceListItem _$DeviceListItemFromJson(Map<String, dynamic> json) =>
    DeviceListItem(
      deviceId: json['dId'] as String,
      status: json['status'] as String,
      deviceStrength: (json['deviceStrength'] as num).toInt(),
      created: json['created'] as String,
      updated: json['updated'] as String,
      expiryDate: json['expiryDate'] as String,
    );

Map<String, dynamic> _$DeviceListItemToJson(DeviceListItem instance) =>
    <String, dynamic>{
      'dId': instance.deviceId,
      'status': instance.status,
      'deviceStrength': instance.deviceStrength,
      'created': instance.created,
      'updated': instance.updated,
      'expiryDate': instance.expiryDate,
    };
