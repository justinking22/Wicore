// lib/models/user_update_request_model.dart
import 'package:Wicore/models/notification_preferences_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_update_request_model.g.dart';

@JsonSerializable()
class UserUpdateRequest {
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? firstName;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? lastName;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final int? age;
  @JsonKey(name: 'deviceStrength', defaultValue: null, includeIfNull: false)
  final int? deviceStrength;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final double? weight;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final double? height;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? gender;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? number;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final bool? onboarded;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? email;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? id;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? updated;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? created;

  // NEW: Add notification preferences
  @JsonKey(defaultValue: null, includeIfNull: false)
  final NotificationPreferences? notificationPreferences;

  const UserUpdateRequest({
    this.firstName,
    this.lastName,
    this.age,
    this.deviceStrength,
    this.weight,
    this.height,
    this.gender,
    this.number,
    this.onboarded,
    this.email,
    this.id,
    this.updated,
    this.created,
    this.notificationPreferences,
  });

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserUpdateRequestToJson(this);

  Map<String, dynamic> toJsonNonNull() {
    final json = toJson();
    return json..removeWhere((key, value) => value == null);
  }

  bool get isEmpty =>
      firstName == null &&
      lastName == null &&
      age == null &&
      deviceStrength == null &&
      weight == null &&
      height == null &&
      gender == null &&
      number == null &&
      onboarded == null &&
      email == null &&
      id == null &&
      updated == null &&
      created == null &&
      notificationPreferences == null;

  // Helper constructor for notification updates only
  UserUpdateRequest.notificationsOnly({
    required NotificationPreferences preferences,
  }) : this(notificationPreferences: preferences);

  @override
  String toString() {
    return 'UserUpdateRequest(notificationPreferences: $notificationPreferences, onboarded: $onboarded)';
  }
}
