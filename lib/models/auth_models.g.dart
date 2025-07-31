// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUpRequest _$SignUpRequestFromJson(Map<String, dynamic> json) =>
    SignUpRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$SignUpRequestToJson(SignUpRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
    };

SignInRequest _$SignInRequestFromJson(Map<String, dynamic> json) =>
    SignInRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$SignInRequestToJson(SignInRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      data: json['data'] == null
          ? null
          : AuthData.fromJson(json['data'] as Map<String, dynamic>),
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      requiresConfirmation: json['requiresConfirmation'] as bool?,
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'data': instance.data,
      'errors': instance.errors,
      'requiresConfirmation': instance.requiresConfirmation,
      'userId': instance.userId,
    };

AuthData _$AuthDataFromJson(Map<String, dynamic> json) => AuthData(
      id: json['id'] as String?,
      username: json['username'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      confirmed: json['confirmed'] as bool?,
    );

Map<String, dynamic> _$AuthDataToJson(AuthData instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'confirmed': instance.confirmed,
    };

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(
        RefreshTokenRequest instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
    };

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ForgotPasswordRequest(
      email: json['email'] as String,
    );

Map<String, dynamic> _$ForgotPasswordRequestToJson(
        ForgotPasswordRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
    };

ChangePasswordRequest _$ChangePasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ChangePasswordRequest(
      email: json['email'] as String,
      newPassword: json['newPassword'] as String,
      confirmationCode: json['confirmationCode'] as String,
    );

Map<String, dynamic> _$ChangePasswordRequestToJson(
        ChangePasswordRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'newPassword': instance.newPassword,
      'confirmationCode': instance.confirmationCode,
    };
