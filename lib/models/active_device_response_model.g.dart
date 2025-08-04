// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_device_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveDeviceListResponse _$ActiveDeviceListResponseFromJson(
        Map<String, dynamic> json) =>
    ActiveDeviceListResponse(
      devices: (json['data'] as List<dynamic>?)
          ?.map((e) => ActiveDeviceListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$ActiveDeviceListResponseToJson(
        ActiveDeviceListResponse instance) =>
    <String, dynamic>{
      'data': instance.devices,
      'error': instance.error,
      'code': instance.code,
      'msg': instance.msg,
    };

ActiveDeviceListItem _$ActiveDeviceListItemFromJson(
        Map<String, dynamic> json) =>
    ActiveDeviceListItem(
      deviceId: json['dId'] as String,
      status: json['status'] as String,
      deviceStrength: (json['deviceStrength'] as num).toInt(),
      created: json['created'] as String,
      updated: json['updated'] as String,
      expiryDate: json['expiryDate'] as String,
      battery: (json['battery'] as num).toInt(),
    );

Map<String, dynamic> _$ActiveDeviceListItemToJson(
        ActiveDeviceListItem instance) =>
    <String, dynamic>{
      'dId': instance.deviceId,
      'status': instance.status,
      'deviceStrength': instance.deviceStrength,
      'created': instance.created,
      'updated': instance.updated,
      'expiryDate': instance.expiryDate,
      'battery': instance.battery,
    };
