// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_device_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveDeviceResponse _$ActiveDeviceResponseFromJson(
        Map<String, dynamic> json) =>
    ActiveDeviceResponse(
      data: json['data'] == null
          ? null
          : ActiveDeviceData.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
      code: (json['code'] as num?)?.toInt(),
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$ActiveDeviceResponseToJson(
        ActiveDeviceResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'error': instance.error,
      'code': instance.code,
      'msg': instance.msg,
    };

ActiveDeviceData _$ActiveDeviceDataFromJson(Map<String, dynamic> json) =>
    ActiveDeviceData(
      updated: json['updated'] as String?,
      expiryDate: json['expiryDate'] as String?,
      status: json['status'] as String?,
      created: json['created'] as String?,
      offset: (json['offset'] as num?)?.toInt(),
      userId: json['uId'] as String?,
      deviceStrength: (json['deviceStrength'] as num?)?.toInt(),
      deviceId: json['dId'] as String?,
      battery: (json['battery'] as num?)?.toInt(),
      location: json['location'] == null
          ? null
          : DeviceLocation.fromJson(json['location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ActiveDeviceDataToJson(ActiveDeviceData instance) =>
    <String, dynamic>{
      'updated': instance.updated,
      'expiryDate': instance.expiryDate,
      'status': instance.status,
      'created': instance.created,
      'offset': instance.offset,
      'uId': instance.userId,
      'deviceStrength': instance.deviceStrength,
      'dId': instance.deviceId,
      'battery': instance.battery,
      'location': instance.location,
    };

DeviceLocation _$DeviceLocationFromJson(Map<String, dynamic> json) =>
    DeviceLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$DeviceLocationToJson(DeviceLocation instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
