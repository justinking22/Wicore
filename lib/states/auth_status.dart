import 'package:Wicore/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, needsConfirmation }

class AuthState {
  final AuthStatus status;
  final UserData? userData;
  final String? token;
  final String? confirmationEmail;

  const AuthState({
    required this.status,
    this.userData,
    this.token,
    this.confirmationEmail,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsConfirmation => status == AuthStatus.needsConfirmation;

  AuthState copyWith({
    AuthStatus? status,
    UserData? userData,
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
