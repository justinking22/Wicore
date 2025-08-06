import 'package:Wicore/services/api_error_code_service.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sign_up_response_model.g.dart';

@JsonSerializable()
class SignUpServerResponse {
  final SignUpData? data;
  final int? code;
  final String? msg; // Server uses "msg" field
  final String? error; // Error field for failure responses

  SignUpServerResponse({this.data, this.code, this.msg, this.error});

  factory SignUpServerResponse.fromJson(Map<String, dynamic> json) =>
      _$SignUpServerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SignUpServerResponseToJson(this);

  // Success is determined by code 0 (ApiErrorCode.apiSuccess)
  bool get isSuccess => code == 0;

  // Get the appropriate message based on response type
  String get errorMessage {
    // If there's an error field, it's a failure response - return the error
    if (error?.isNotEmpty == true) return error!;

    // If there's a msg field, return it (works for both success and error)
    if (msg?.isNotEmpty == true) return msg!;

    // If we have a code, try to get the standard error message for that code
    if (code != null) {
      return ApiErrorCode.getErrorMessage(code!);
    }

    // Final fallback
    return isSuccess ? 'Signup successful' : 'Signup failed';
  }

  bool get requiresConfirmation => data?.confirmed == false;
}

@JsonSerializable()
class SignUpData {
  final String? id;
  final bool? confirmed;

  SignUpData({this.id, this.confirmed});

  factory SignUpData.fromJson(Map<String, dynamic> json) =>
      _$SignUpDataFromJson(json);

  Map<String, dynamic> toJson() => _$SignUpDataToJson(this);
}
