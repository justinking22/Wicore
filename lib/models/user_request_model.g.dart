// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserItem _$UserItemFromJson(Map<String, dynamic> json) => UserItem(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      birthdate: json['birthdate'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      onboarded: json['onboarded'] as bool?,
      age: (json['age'] as num?)?.toInt(),
      number: json['number'] as String?,
      deviceStrength: (json['devicestrength'] as num?)?.toInt(),
      created: json['created'] as String?,
      updated: json['updated'] as String?,
    );

Map<String, dynamic> _$UserItemToJson(UserItem instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('firstName', instance.firstName);
  writeNotNull('lastName', instance.lastName);
  writeNotNull('email', instance.email);
  writeNotNull('birthdate', instance.birthdate);
  writeNotNull('weight', instance.weight);
  writeNotNull('height', instance.height);
  writeNotNull('gender', instance.gender);
  writeNotNull('onboarded', instance.onboarded);
  writeNotNull('age', instance.age);
  writeNotNull('number', instance.number);
  writeNotNull('devicestrength', instance.deviceStrength);
  writeNotNull('created', instance.created);
  writeNotNull('updated', instance.updated);
  return val;
}

UserRequest _$UserRequestFromJson(Map<String, dynamic> json) => UserRequest(
      item: json['item'] == null
          ? null
          : UserItem.fromJson(json['item'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserRequestToJson(UserRequest instance) =>
    <String, dynamic>{
      'item': instance.item,
    };
