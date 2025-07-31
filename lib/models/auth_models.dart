import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class SignUpRequest {
  final String email;
  final String password;
  final String? name;

  SignUpRequest({required this.email, required this.password, this.name});

  factory SignUpRequest.fromJson(Map<String, dynamic> json) =>
      _$SignUpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SignUpRequestToJson(this);
}

@JsonSerializable()
class SignInRequest {
  final String email;
  final String password;

  SignInRequest({required this.email, required this.password});

  factory SignInRequest.fromJson(Map<String, dynamic> json) =>
      _$SignInRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SignInRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String? message;
  final String? code;
  final AuthData? data;
  final List<String>? errors;
  final bool? requiresConfirmation;
  final String? userId;

  AuthResponse({
    required this.success,
    this.message,
    this.code,
    this.data,
    this.errors,
    this.requiresConfirmation,
    this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class AuthData {
  final String? id;
  final String? username;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final bool? confirmed;

  AuthData({
    this.id,
    this.username,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.confirmed,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) =>
      _$AuthDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

@JsonSerializable()
class ChangePasswordRequest {
  final String email;
  final String newPassword;
  final String confirmationCode;

  ChangePasswordRequest({
    required this.email,
    required this.newPassword,
    required this.confirmationCode,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

enum AuthStatus { unknown, unauthenticated, authenticated, needsConfirmation }

class AuthState {
  final AuthStatus status;
  final AuthData? userData;
  final String? token;
  final String? confirmationEmail;

  const AuthState({
    required this.status,
    this.userData,
    this.token,
    this.confirmationEmail,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthData? userData,
    String? token,
    String? confirmationEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      userData: userData ?? this.userData,
      token: token ?? this.token,
      confirmationEmail: confirmationEmail ?? this.confirmationEmail,
    );
  }
}
