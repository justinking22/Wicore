// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_device_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveDeviceListResponse _$ActiveDeviceListResponseFromJson(
        Map<String, dynamic> json) =>
    ActiveDeviceListResponse(
      data: json['data'],
      error: json['error'] as String?,
      code: (json['code'] as num).toInt(),
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$ActiveDeviceListResponseToJson(
        ActiveDeviceListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'error': instance.error,
      'code': instance.code,
      'msg': instance.msg,
    };

ActiveDeviceListItem _$ActiveDeviceListItemFromJson(
        Map<String, dynamic> json) =>
    ActiveDeviceListItem(
      deviceId: json['dId'] as String,
      status: json['status'] as String? ?? 'unknown',
      deviceStrength: (json['deviceStrength'] as num?)?.toInt() ?? 0,
      created: json['created'] as String? ?? '',
      updated: json['updated'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      battery: (json['battery'] as num?)?.toInt() ?? 0,
      userId: json['uId'] as String?,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      location: json['location'] as Map<String, dynamic>?,
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
      'uId': instance.userId,
      'offset': instance.offset,
      'location': instance.location,
    };
