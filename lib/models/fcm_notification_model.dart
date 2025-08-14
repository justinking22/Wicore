import 'package:json_annotation/json_annotation.dart';

part 'fcm_notification_model.g.dart';

@JsonSerializable()
class FcmTokenRequest {
  final String deviceToken;
  final String platform;

  const FcmTokenRequest({required this.deviceToken, required this.platform});

  factory FcmTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$FcmTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FcmTokenRequestToJson(this);
}

@JsonSerializable()
class EndpointArnData {
  final String uId;
  final String platform;
  final String endpointArn;
  final int offset;
  final String created;
  final String updated;

  const EndpointArnData({
    required this.uId,
    required this.platform,
    required this.endpointArn,
    required this.offset,
    required this.created,
    required this.updated,
  });

  factory EndpointArnData.fromJson(Map<String, dynamic> json) =>
      _$EndpointArnDataFromJson(json);

  Map<String, dynamic> toJson() => _$EndpointArnDataToJson(this);
}

@JsonSerializable()
class EndpointArnResponse {
  final EndpointArnData data;
  final int code;

  const EndpointArnResponse({required this.data, required this.code});

  factory EndpointArnResponse.fromJson(Map<String, dynamic> json) =>
      _$EndpointArnResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EndpointArnResponseToJson(this);
}

@JsonSerializable()
class FcmTokenResponse {
  final EndpointArnResponse endpointArn;

  const FcmTokenResponse({required this.endpointArn});

  factory FcmTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$FcmTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FcmTokenResponseToJson(this);
}

@JsonSerializable()
class FcmServerResponse {
  final FcmTokenResponse data;
  final int code;

  const FcmServerResponse({required this.data, required this.code});

  factory FcmServerResponse.fromJson(Map<String, dynamic> json) =>
      _$FcmServerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FcmServerResponseToJson(this);
}
