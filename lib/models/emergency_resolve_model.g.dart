// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_resolve_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyItem _$EmergencyItemFromJson(Map<String, dynamic> json) =>
    EmergencyItem(
      updated: json['updated'] as String,
      resolved: (json['resolved'] as num).toInt(),
      userName: json['userName'] as String,
      created: json['created'] as String,
      uId: json['uId'] as String,
      userPhoneNumber: json['userPhoneNumber'] as String,
      dId: json['dId'] as String,
    );

Map<String, dynamic> _$EmergencyItemToJson(EmergencyItem instance) =>
    <String, dynamic>{
      'updated': instance.updated,
      'resolved': instance.resolved,
      'userName': instance.userName,
      'created': instance.created,
      'uId': instance.uId,
      'userPhoneNumber': instance.userPhoneNumber,
      'dId': instance.dId,
    };

EmergencyData _$EmergencyDataFromJson(Map<String, dynamic> json) =>
    EmergencyData(
      data: (json['data'] as List<dynamic>)
          .map((e) => EmergencyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: (json['code'] as num).toInt(),
    );

Map<String, dynamic> _$EmergencyDataToJson(EmergencyData instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };

EmergencyResolveResponse _$EmergencyResolveResponseFromJson(
        Map<String, dynamic> json) =>
    EmergencyResolveResponse(
      data: EmergencyData.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num).toInt(),
    );

Map<String, dynamic> _$EmergencyResolveResponseToJson(
        EmergencyResolveResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };
