// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incognito_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncognitoUser _$IncognitoUserFromJson(Map<String, dynamic> json) =>
    IncognitoUser(
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      birthdate: json['birthdate'] as String?,
      weight: (json['weight'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      onboarded: json['onboarded'] as bool?,
      notificationPreferences: json['notificationPreferences'] == null
          ? null
          : NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>),
      deviceStrength: (json['deviceStrength'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IncognitoUserToJson(IncognitoUser instance) =>
    <String, dynamic>{
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthdate': instance.birthdate,
      'weight': instance.weight,
      'height': instance.height,
      'gender': instance.gender,
      'onboarded': instance.onboarded,
      'notificationPreferences': instance.notificationPreferences,
      'deviceStrength': instance.deviceStrength,
    };
