import 'package:Wicore/providers/auth_provider.dart';
import 'package:flutter/material.dart';

class SignUpProvider extends ChangeNotifier {
  final AuthService _authService;

  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  SignUpProvider(this._authService);

  // Getters
  String get name => _name;
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthService get authService => _authService;

  // Check if all required data is collected
  bool get isDataComplete =>
      _name.isNotEmpty && _email.isNotEmpty && _password.isNotEmpty;

  // Setters
  void setName(String name) {
    _name = name;
    _clearError();
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    _clearError();
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Submit all data at once using your existing AuthService
  Future<Map<String, dynamic>> submitSignUp() async {
    if (!isDataComplete) {
      _setError('모든 정보를 입력해주세요.');
      return {'success': false, 'message': '모든 정보를 입력해주세요.'};
    }

    _setLoading(true);
    _clearError();

    try {
      // Use your existing AuthService signUp method
      final result = await _authService.signUp(
        email: _email,
        password: _password,
        name: _name,
      );

      if (!result['success']) {
        _setError(result['message'] ?? '회원가입에 실패했습니다.');
      }

      return result;
    } catch (e) {
      final errorMessage = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
      _setError(errorMessage);
      return {'success': false, 'message': errorMessage};
    } finally {
      _setLoading(false);
    }
  }

  // Clear data when needed (e.g., when user cancels signup)
  void clear() {
    _name = '';
    _email = '';
    _password = '';
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
