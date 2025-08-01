import 'package:json_annotation/json_annotation.dart';

part 'resend_confirmation_request_model.g.dart';

@JsonSerializable()
class ResendConfirmationRequest {
  final String email;

  ResendConfirmationRequest({required this.email});

  factory ResendConfirmationRequest.fromJson(Map<String, dynamic> json) =>
      _$ResendConfirmationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ResendConfirmationRequestToJson(this);
}