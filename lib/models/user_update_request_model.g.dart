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
      deviceStrength: (json['devicestrength'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      number: json['number'] as String?,
      onboarded: json['onboarded'] as bool?,
      email: json['email'] as String?,
      id: json['id'] as String?,
      updated: json['updated'] as String?,
      created: json['created'] as String?,
    );

Map<String, dynamic> _$UserUpdateRequestToJson(UserUpdateRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('firstName', instance.firstName);
  writeNotNull('lastName', instance.lastName);
  writeNotNull('age', instance.age);
  writeNotNull('devicestrength', instance.deviceStrength);
  writeNotNull('weight', instance.weight);
  writeNotNull('height', instance.height);
  writeNotNull('gender', instance.gender);
  writeNotNull('number', instance.number);
  writeNotNull('onboarded', instance.onboarded);
  writeNotNull('email', instance.email);
  writeNotNull('id', instance.id);
  writeNotNull('updated', instance.updated);
  writeNotNull('created', instance.created);
  return val;
}
