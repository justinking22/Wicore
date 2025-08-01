import 'package:json_annotation/json_annotation.dart';

part 'resend_confirmation_response_model.g.dart';

@JsonSerializable()
class ResendConfirmationResponse {
  final ResendConfirmationData? data;
  final int? code;

  ResendConfirmationResponse({this.data, this.code});

  factory ResendConfirmationResponse.fromJson(Map<String, dynamic> json) =>
      _$ResendConfirmationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ResendConfirmationResponseToJson(this);

  bool get isSuccess => data?.message != null;
  String get message => data?.message ?? 'Confirmation code sent';
}

@JsonSerializable()
class ResendConfirmationData {
  final String? message;

  ResendConfirmationData({this.message});

  factory ResendConfirmationData.fromJson(Map<String, dynamic> json) =>
      _$ResendConfirmationDataFromJson(json);
  Map<String, dynamic> toJson() => _$ResendConfirmationDataToJson(this);
}