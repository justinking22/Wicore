// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserItem _$UserItemFromJson(Map<String, dynamic> json) => UserItem(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      birthdate: json['birthdate'] as String,
      weight: (json['weight'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      gender: json['gender'] as String,
      onboarded: json['onboarded'] as bool,
    );

Map<String, dynamic> _$UserItemToJson(UserItem instance) => <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'birthdate': instance.birthdate,
      'weight': instance.weight,
      'height': instance.height,
      'gender': instance.gender,
      'onboarded': instance.onboarded,
    };

UserRequest _$UserRequestFromJson(Map<String, dynamic> json) => UserRequest(
      item: UserItem.fromJson(json['item'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserRequestToJson(UserRequest instance) =>
    <String, dynamic>{
      'item': instance.item,
    };
