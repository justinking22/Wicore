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
  @JsonKey(name: 'devicestrength', defaultValue: null, includeIfNull: false)
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
  final bool? onboarded; // Changed to bool? to match UserItem
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? email;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? id;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? updated;
  @JsonKey(defaultValue: null, includeIfNull: false)
  final String? created;

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
      created == null;
}
