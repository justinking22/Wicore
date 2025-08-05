// lib/models/user_update_request_model.dart
import 'package:Wicore/models/user_request_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_update_request_model.g.dart';

@JsonSerializable()
class UserUpdateRequest {
  final String? firstName;
  final String? lastName;
  final int? age;
  final int? deviceStrength;
  final String? weight;
  final String? height;
  final String? gender; // Optional field to update device strength

  const UserUpdateRequest({
    this.firstName,
    this.lastName,
    this.age,
    this.deviceStrength,
    this.weight,
    this.height,
    this.gender,
  });

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserUpdateRequestToJson(this);

  // Helper method to create from UserItem
  factory UserUpdateRequest.fromUserItem(
    UserItem userItem, {
    int? deviceStrength,
  }) {
    // Calculate age from birthdate if needed
    int? calculatedAge;
    try {
      final birthDate = DateTime.parse(userItem.birthdate);
      final now = DateTime.now();
      calculatedAge = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        calculatedAge--;
      }
    } catch (e) {
      calculatedAge = null;
    }

    return UserUpdateRequest(
      firstName: userItem.firstName,
      lastName: userItem.lastName,
      age: calculatedAge,
      deviceStrength: deviceStrength,
    );
  }

  // Helper method to create with only changed fields
  UserUpdateRequest copyWith({
    String? firstName,
    String? lastName,
    int? age,
    int? deviceStrength,
  }) {
    return UserUpdateRequest(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      deviceStrength: deviceStrength ?? this.deviceStrength,
    );
  }

  // Helper method to check if request is empty
  bool get isEmpty =>
      firstName == null &&
      lastName == null &&
      age == null &&
      deviceStrength == null;

  // Helper method to get non-null fields only
  Map<String, dynamic> toJsonNonNull() {
    final Map<String, dynamic> json = {};
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (age != null) json['age'] = age;
    if (deviceStrength != null) json['deviceStrength'] = deviceStrength;
    return json;
  }
}
