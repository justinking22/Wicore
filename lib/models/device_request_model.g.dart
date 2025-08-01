// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRequest _$DeviceRequestFromJson(Map<String, dynamic> json) =>
    DeviceRequest(
      deviceId: json['dId'] as String,
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$DeviceRequestToJson(DeviceRequest instance) =>
    <String, dynamic>{
      'dId': instance.deviceId,
      'offset': instance.offset,
    };
