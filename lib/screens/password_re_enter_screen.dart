import 'package:Wicore/dialogs/confirmation_dialog.dart';
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
  bool _isSigningUp = false; // ✅ Added signup loading state
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

  // ✅ Updated to trigger signup API call
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 정보가 누락되었습니다. 처음부터 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
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

      // ✅ Make the signup API call with all collected data
      final result = await authNotifier.signUp(
        email: signUpForm.email,
        password: signUpForm.password,
      );

      if (result.isSuccess) {
        if (result.requiresConfirmation) {
          // Account created but needs email verification
          if (mounted) {
            print('✅ Account created, email verification required');
            context.push('/email-verification');
          }
        } else {
          // Account created and activated immediately
          if (mounted) {
            print('✅ Account created and activated');
            context.push('/sign-up-complete');
          }
        }
      } else {
        // Handle signup error
        if (mounted) {
          print('❌ Signup failed: ${result.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '회원가입에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error during signup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입 중 오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningUp = false;
        });
      }
    }
  }

  void _showPasswordMismatchError() {
    setState(() {
      _passwordMismatchError = '비밀번호가 일치하지 않습니다. 다시 한 번 입력해주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final signUpForm = ref.watch(signUpFormProvider);

    // ✅ Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.needsConfirmation) {
        // User needs email confirmation
        context.push('/email-verification');
      } else if (next.isAuthenticated) {
        // User is authenticated, go to main app
        context.go('/navigation');
      }
    });

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
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
                  Text('비밀번호를', style: TextStyles.kBody),
                  const SizedBox(height: 8),
                  Text('다시 한 번 입력해주세요', style: TextStyles.kBody),
                  // Conditional content: Either error message OR subtitle text
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
                  ] else ...[
                    const SizedBox(height: 24),
                    // Subtitle text
                    Text('입력한 비밀번호가 맞는지 확인할게요.', style: TextStyles.kThirdBody),
                    const SizedBox(height: 60),
                  ],

                  // Input field label
                  Text('비밀번호 확인', style: TextStyles.kHeader),
                  const SizedBox(height: 8),
                  // Password confirmation input field
                  TextField(
                    controller: _confirmPasswordController,
                    enabled: !_isSigningUp, // ✅ Disable during signup
                    obscureText: _obscureText,
                    obscuringCharacter: '\u2B24',
                    decoration: InputDecoration(
                      hintText: '비밀번호를 다시 입력해주세요',
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

                  // ✅ Show signup progress info
                  if (_isSigningUp) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '계정을 생성하고 있습니다...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ✅ Show collected data for debugging (remove in production)
                  if (!_isSigningUp) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '수집된 정보:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '이름: ${signUpForm.name}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '이메일: ${signUpForm.email}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '비밀번호: ${signUpForm.password.isNotEmpty ? '입력됨' : '입력 안됨'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),
                  // Next/Signup button
                  CustomButton(
                    text: _isSigningUp ? '회원가입 중...' : '회원가입',
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
