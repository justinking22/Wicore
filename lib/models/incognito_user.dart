import 'package:Wicore/models/notification_preferences_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'incognito_user.g.dart';

@JsonSerializable()
class IncognitoUser {
  final String? email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? birthdate;
  final int? weight;
  final int? height;
  final String? gender;
  final bool? onboarded;
  final NotificationPreferences? notificationPreferences;
  final int? deviceStrength;

  const IncognitoUser({
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.birthdate,
    this.weight,
    this.height,
    this.gender,
    this.onboarded,
    this.notificationPreferences,
    this.deviceStrength,
  });

  factory IncognitoUser.fromJson(Map<String, dynamic> json) =>
      _$IncognitoUserFromJson(json);

  Map<String, dynamic> toJson() => _$IncognitoUserToJson(this);

  IncognitoUser copyWith({
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? birthdate,
    int? weight,
    int? height,
    String? gender,
    bool? onboarded,
    NotificationPreferences? notificationPreferences,
    int? deviceStrength,
  }) {
    return IncognitoUser(
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthdate: birthdate ?? this.birthdate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      onboarded: onboarded ?? this.onboarded,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      deviceStrength: deviceStrength ?? this.deviceStrength,
    );
  }
}
