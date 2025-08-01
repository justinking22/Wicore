import 'package:json_annotation/json_annotation.dart';

part 'refresh_token_response_model.g.dart';

@JsonSerializable()
class RefreshTokenResponse {
  final RefreshTokenData? data;
  final int? code;

  RefreshTokenResponse({this.data, this.code});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenResponseToJson(this);

  bool get isSuccess => data?.accessToken != null;
  String get message => isSuccess ? 'Token refreshed successfully' : 'Token refresh failed';

  

}
@JsonSerializable()
class RefreshTokenData {
  final String? expiryDate;
  final String? accessToken;
  final String? refreshToken;
  final String? username;

 RefreshTokenData({
    this.expiryDate,
    this.accessToken,
    this.refreshToken,
    this.username,
  });

  factory RefreshTokenData.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenDataFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenDataToJson(this);

}
