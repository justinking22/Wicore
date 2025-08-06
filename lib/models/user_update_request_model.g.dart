// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_update_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserUpdateRequest _$UserUpdateRequestFromJson(Map<String, dynamic> json) =>
    UserUpdateRequest(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      age: (json['age'] as num?)?.toInt(),
      deviceStrength: (json['deviceStrength'] as num?)?.toInt(),
      weight: json['weight'] as String?,
      height: json['height'] as String?,
      gender: json['gender'] as String?,
      number: json['number'] as String?,
    );

Map<String, dynamic> _$UserUpdateRequestToJson(UserUpdateRequest instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'age': instance.age,
      'deviceStrength': instance.deviceStrength,
      'weight': instance.weight,
      'height': instance.height,
      'gender': instance.gender,
      'number': instance.number,
    };
