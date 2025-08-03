import 'package:json_annotation/json_annotation.dart';

part 'user_request_model.g.dart';

@JsonSerializable()
class UserItem {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String birthdate;
  final int weight;
  final int height;
  final String gender;
  final bool onboarded;

  const UserItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.birthdate,
    required this.weight,
    required this.height,
    required this.gender,
    required this.onboarded,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) =>
      _$UserItemFromJson(json);

  Map<String, dynamic> toJson() => _$UserItemToJson(this);
}

@JsonSerializable()
class UserRequest {
  final UserItem item;

  const UserRequest({required this.item});

  factory UserRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserRequestToJson(this);
}
