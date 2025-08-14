import 'package:Wicore/models/notification_preferences_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_request_model.g.dart';

@JsonSerializable()
class UserItem {
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? id;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? firstName;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? lastName;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? email;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? birthdate;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final double? weight; // Changed to double? to match API
  @JsonKey(defaultValue: null, includeIfNull: false)
  final double? height; // Changed to double? to match API
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? gender;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final bool? onboarded;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final int? age;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? phoneNumber;
  @JsonKey(name: 'deviceStrength', defaultValue: null, includeIfNull: false)
  final int? deviceStrength;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? created;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? updated;
  // NEW: Add notification preferences field
  @JsonKey(defaultValue: null, includeIfNull: false)
  final NotificationPreferences? notificationPreferences;

  const UserItem({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.birthdate,
    this.weight,
    this.height,
    this.gender,
    this.onboarded,
    this.age,
    this.phoneNumber,
    this.deviceStrength,
    this.created,
    this.updated,
    this.notificationPreferences, // Add this to constructor
  });

  factory UserItem.fromJson(Map<String, dynamic> json) =>
      _$UserItemFromJson(json);

  Map<String, dynamic> toJson() => _$UserItemToJson(this);
}

@JsonSerializable()
class UserRequest {
  @JsonKey(defaultValue: null)
  final UserItem? item; // Made nullable to handle potential null cases

  const UserRequest({this.item});

  factory UserRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserRequestToJson(this);
}
