import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/models/sign_up_response_model.dart';
import 'package:Wicore/services/api_error_code_service.dart' show ApiErrorCode;
import 'package:Wicore/utilities/sign_up_form_state.dart';
import 'package:Wicore/providers/authentication_provider.dart';

import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordConfirmationScreen extends ConsumerStatefulWidget {
  const PasswordConfirmationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasswordConfirmationScreen> createState() =>
      _PasswordConfirmationScreenState();
}

class _PasswordConfirmationScreenState
    extends ConsumerState<PasswordConfirmationScreen> {
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isButtonEnabled = false;
  bool _obscureText = true;
  bool _isSigningUp = false;
  String? _errorText;
  String? _passwordMismatchError;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _confirmPasswordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    _validatePassword(_confirmPasswordController.text);
    // Clear password mismatch error when user types
    if (_passwordMismatchError != null) {
      setState(() {
        _passwordMismatchError = null;
      });
    }
  }

  bool _isPasswordValid(String password) {
    if (password.length < 7) return false;

    bool hasLetter = false;
    bool hasNumber = false;

    for (int i = 0; i < password.length; i++) {
      String char = password[i];
      if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        hasLetter = true;
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        hasNumber = true;
      }

      if (hasLetter && hasNumber) break;
    }

    return hasLetter && hasNumber;
  }

  // Update your _validatePassword method
  void _validatePassword(String confirmPassword) {
    setState(() {
      if (confirmPassword.isEmpty) {
        _isButtonEnabled = false;
        _errorText = null;
      } else {
        _isButtonEnabled = true;
        _errorText = null;
      }
    });
  }

  // Enhanced _handleNext method with better error handling
  Future<void> _handleNext() async {
    if (!_isButtonEnabled || _isSigningUp) return;

    final confirmPassword = _confirmPasswordController.text.trim();
    final signUpForm = ref.read(signUpFormProvider);
    final originalPassword = signUpForm.password;

    print('Confirming password: $confirmPassword');

    // Check if passwords match
    if (confirmPassword != originalPassword) {
      _showPasswordMismatchError();
      return;
    }

    // Validate that we have all required data
    if (signUpForm.name.isEmpty ||
        signUpForm.email.isEmpty ||
        signUpForm.password.isEmpty) {
      _showErrorSnackBar('필수 정보가 누락되었습니다. 처음부터 다시 시도해주세요.');
      context.push('/welcome');
      return;
    }

    setState(() {
      _isSigningUp = true;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      print('Creating account with:');
      print('Name: ${signUpForm.name}');
      print('Email: ${signUpForm.email}');
      print('Password: [HIDDEN]');

      final result = await authNotifier.signUp(
        email: signUpForm.email,
        password: signUpForm.password,
      );

      if (result.isSuccess) {
        if (result.requiresConfirmation) {
          if (mounted) {
            print('✅ Account created, email verification required');
            context.push('/email-verification');
          }
        } else {
          if (mounted) {
            print('✅ Account created and activated');
            context.push('/sign-up-complete');
          }
        }
      } else {
        if (mounted) {
          print(
            '❌ Signup failed: Code ${result.code}, Message: ${result.errorMessage}',
          );
          _handleSignUpError(result);
        }
      }
    } catch (e) {
      print('❌ Error during signup: $e');
      if (mounted) {
        _showErrorSnackBar('회원가입 중 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningUp = false;
        });
      }
    }
  }

  // Simplified error handling
  void _handleSignUpError(SignUpServerResponse result) {
    final errorCode = result.code ?? -1;
    String userFriendlyMessage;

    // Handle specific error codes with localized messages
    switch (errorCode) {
      case ApiErrorCode.userNameAlreadyExist:
        userFriendlyMessage = '이미 사용 중인 이메일입니다. 다른 이메일을 사용해주세요.';
        break;

      case ApiErrorCode.invalidPassword:
        userFriendlyMessage = '비밀번호가 정책에 맞지 않습니다. 영문과 숫자를 포함하여 7자 이상 입력해주세요.';
        break;

      case ApiErrorCode.dataIsInvalid:
        userFriendlyMessage = '입력한 정보가 올바르지 않습니다. 다시 확인해주세요.';
        break;

      case ApiErrorCode.dataHaveNoRequiredAtt:
        userFriendlyMessage = '필수 정보가 누락되었습니다. 모든 항목을 입력해주세요.';
        break;

      case ApiErrorCode.invalidParameter:
        userFriendlyMessage = '입력한 정보가 요구사항을 만족하지 않습니다.';
        break;

      case ApiErrorCode.internalServerError:
        userFriendlyMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
        break;

      default:
        // For unknown errors, use the server message or fallback
        userFriendlyMessage =
            result.errorMessage.isNotEmpty
                ? result.errorMessage
                : '회원가입에 실패했습니다. 다시 시도해주세요.';
    }

    _showErrorSnackBar(userFriendlyMessage);
  }

  // Simple error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPasswordMismatchError() {
    setState(() {
      _passwordMismatchError = '비밀번호가 일치하지 않습니다. 다시 한 번 입력해주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final signUpForm = ref.watch(signUpFormProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.needsConfirmation) {
        context.push('/email-verification');
      } else if (next.isAuthenticated) {
        context.go('/navigation');
      }
    });

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBar(
          title: '회원가입',
          onBackPressed: () => Navigator.pop(context),
          showTrailingButton: true,
          onTrailingPressed: () {
            ExitConfirmationDialogWithOptions.show(
              context,
              exitRoute: '/welcome',
            );
          },
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Title text
                  Text('안전한 비밀번호를', style: TextStyles.kBody),
                  const SizedBox(height: 8),
                  Text('만들어주세요', style: TextStyles.kBody),

                  // Show password criteria or error message
                  if (_passwordMismatchError != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: CustomColors.translucentRedOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _passwordMismatchError!,
                        style: TextStyles.kError,
                      ),
                    ),
                    const SizedBox(height: 60),
                  ] else if (!_isPasswordValid(
                        _confirmPasswordController.text,
                      ) &&
                      _confirmPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    // Password criteria container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4), // Light pink background
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '영문과 숫자를 포함하여 7자 이상 입력해주세요.',
                        style: TextStyles.kError,
                      ),
                    ),
                    const SizedBox(height: 60),
                  ] else ...[
                    const SizedBox(
                      height: 24 + 60,
                    ), // Add spacing when criteria is met
                  ],
                  // Input field label
                  Text('비밀번호', style: TextStyles.kHeader),
                  const SizedBox(height: 8),
                  // Password confirmation input field
                  TextField(
                    controller: _confirmPasswordController,
                    enabled: !_isSigningUp,
                    obscureText: _obscureText,
                    obscuringCharacter: '\u2B24',
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해주세요',
                      hintStyle: TextStyles.kMedium,
                      errorText: _errorText,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed:
                            _isSigningUp
                                ? null
                                : () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 0,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: _isSigningUp ? Colors.grey : Colors.black,
                      letterSpacing: 1.5,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_isButtonEnabled && !_isSigningUp) {
                        _handleNext();
                      }
                    },
                  ),

                  const Spacer(),
                  // Next button
                  CustomButton(
                    text: _isSigningUp ? '회원가입 중...' : '다음',
                    isEnabled: _isButtonEnabled && !_isSigningUp,
                    onPressed:
                        (_isButtonEnabled && !_isSigningUp)
                            ? _handleNext
                            : null,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
