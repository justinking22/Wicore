import 'package:Wicore/models/fcm_notification_model.dart';

class FcmTokenState {
  final String? token;
  final FcmServerResponse? registrationResponse;
  final bool isLoading;
  final String? error;
  final DateTime? lastRegistered;
  final int refreshCount;

  const FcmTokenState({
    this.token,
    this.registrationResponse,
    this.isLoading = false,
    this.error,
    this.lastRegistered,
    this.refreshCount = 0,
  });

  FcmTokenState copyWith({
    String? token,
    FcmServerResponse? registrationResponse,
    bool? isLoading,
    String? error,
    DateTime? lastRegistered,
    int? refreshCount,
  }) {
    return FcmTokenState(
      token: token ?? this.token,
      registrationResponse: registrationResponse ?? this.registrationResponse,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRegistered: lastRegistered ?? this.lastRegistered,
      refreshCount: refreshCount ?? this.refreshCount,
    );
  }
}
