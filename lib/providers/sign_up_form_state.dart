import 'package:flutter_riverpod/flutter_riverpod.dart';

final signUpFormProvider =
    StateNotifierProvider<SignUpFormNotifier, SignUpFormState>((ref) {
      return SignUpFormNotifier();
    });

class SignUpFormState {
  final String email;
  final String password;
  final String name;

  const SignUpFormState({this.email = '', this.password = '', this.name = ''});

  SignUpFormState copyWith({String? email, String? password, String? name}) {
    return SignUpFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
    );
  }
}

class SignUpFormNotifier extends StateNotifier<SignUpFormState> {
  SignUpFormNotifier() : super(const SignUpFormState());

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void reset() {
    state = const SignUpFormState();
  }
}
