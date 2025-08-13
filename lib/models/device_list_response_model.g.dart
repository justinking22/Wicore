// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceListResponse _$DeviceListResponseFromJson(Map<String, dynamic> json) =>
    DeviceListResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => DeviceListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: (json['code'] as num).toInt(),
      error: json['error'] as String?,
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$DeviceListResponseToJson(DeviceListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
      'error': instance.error,
      'msg': instance.msg,
    };

DeviceListItem _$DeviceListItemFromJson(Map<String, dynamic> json) =>
    DeviceListItem(
      deviceId: json['dId'] as String,
      status: json['status'] as String,
      created: json['created'] as String,
      updated: json['updated'] as String,
      expiryDate: json['expiryDate'] as String,
      deviceStrength: (json['deviceStrength'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      userId: json['uId'] as String,
    );

Map<String, dynamic> _$DeviceListItemToJson(DeviceListItem instance) =>
    <String, dynamic>{
      'dId': instance.deviceId,
      'status': instance.status,
      'created': instance.created,
      'updated': instance.updated,
      'expiryDate': instance.expiryDate,
      'deviceStrength': instance.deviceStrength,
      'offset': instance.offset,
      'uId': instance.userId,
    };
