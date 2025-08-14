import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/utilities/sign_up_form_state.dart'; // Add this import
import 'package:Wicore/providers/user_provider.dart'; // Add this import
import 'package:Wicore/models/user_update_request_model.dart'; // Add this import
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isAutoLogin = true;
  bool _isObscurePassword = true;
  bool _hasEmailError = false;
  String _emailErrorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() {
        _hasEmailError = true;
        _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
      });
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      setState(() {
        _hasEmailError = true;
        _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
      });
    } else {
      setState(() {
        _hasEmailError = false;
        _emailErrorMessage = '';
      });
    }
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
      ),
    );
  }

  // NEW: Method to update user profile with stored name from signup
  Future<void> _updateUserProfileAfterLogin() async {
    try {
      final signUpForm = ref.read(signUpFormProvider);

      // Check if there's a name stored from recent signup
      if (signUpForm.name.isNotEmpty) {
        print(
          '🔄 Login successful, updating profile with stored name: ${signUpForm.name}',
        );

        // Small delay to ensure authentication is fully established
        await Future.delayed(const Duration(milliseconds: 300));

        // Update the user profile with the stored name
        await ref
            .read(userProvider.notifier)
            .updateCurrentUserProfile(
              UserUpdateRequest(firstName: signUpForm.name),
            );

        print('✅ User profile updated with name after login');

        // Clear the stored signup form data after successful update
        ref.read(signUpFormProvider.notifier).reset();

        // Show success message
        if (mounted) {
          _showMessage('프로필이 업데이트되었습니다!', backgroundColor: Colors.green);
        }
      }
    } catch (e) {
      print('⚠️ Failed to update profile after login: $e');
      // Don't show error to user since login was successful
      // They can update their name later in settings
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      final result = await authNotifier.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.isSuccess) {
          // Save auto-login preference if enabled
          if (_isAutoLogin) {
            // You can implement auto-login storage here
            print('Auto-login enabled for user');
          }

          // NEW: Update user profile with stored name if available
          await _updateUserProfileAfterLogin();

          _showMessage('로그인 성공!', backgroundColor: Colors.green);
          context.go('/navigation');
        } else if (result.data?.accessToken == null) {
          setState(() {
            _hasEmailError = true;
            _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
          });
        } else {
          // Handle specific error cases
          if (result.message?.contains('invalid') == true ||
              result.message?.contains('incorrect') == true ||
              result.message?.contains('wrong') == true) {
            setState(() {
              _hasEmailError = true;
              _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
            });
          } else {
            _showMessage(result.message ?? '로그인에 실패했습니다.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSocialLoginBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('로그인할 계정을\n선택해주세요', style: TextStyles.kBody),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _handleGoogleLogin();
                      },
                      child: Container(
                        height: 147,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://developers.google.com/identity/images/g-logo.png',
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('구글', style: TextStyles.kLogo),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _handleAppleLogin();
                      },
                      child: Container(
                        height: 147,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, size: 48, color: Colors.black),
                            SizedBox(height: 8),
                            Text('애플', style: TextStyles.kLogo),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _handleContinueWithoutLogin();
                },
                child: const Center(
                  child: Text(
                    '로그인 없이 계속하기',
                    style: TextStyles.kTrailingBottomButtonWithUnderline,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleLogin() async {
    try {
      _showMessage('Google 로그인 기능을 준비 중입니다.', backgroundColor: Colors.orange);

      // TODO: Implement Google OAuth login
      // When implementing, add the same profile update logic:
      // if (result.isSuccess) {
      //   await _updateUserProfileAfterLogin();
      //   context.go('/navigation');
      // }
    } catch (e) {
      if (mounted) {
        _showMessage('Google 로그인 오류: $e');
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    try {
      _showMessage('Apple 로그인 기능을 준비 중입니다.', backgroundColor: Colors.orange);

      // TODO: Implement Apple Sign In
      // When implementing, add the same profile update logic:
      // if (result.isSuccess) {
      //   await _updateUserProfileAfterLogin();
      //   context.go('/navigation');
      // }
    } catch (e) {
      if (mounted) {
        _showMessage('Apple 로그인 오류: $e');
      }
    }
  }

  void _handleContinueWithoutLogin() {
    _showMessage('게스트 모드 기능을 준비 중입니다.', backgroundColor: Colors.orange);

    // TODO: Navigate to guest mode or limited features
    // context.go('/guest-mode');
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for automatic navigation
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
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
        // Add this to prevent screen resize when keyboard appears
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: () {
                  context.push('/welcome');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.limeGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('회원가입', style: TextStyles.kRegular),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            // Add scroll behavior
            physics: const ClampingScrollPhysics(),
            child: Container(
              // Use container with minimum height
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).viewInsets.bottom -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top,
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('반갑습니다\n로그인을 해주세요', style: TextStyles.kBody),
                    const SizedBox(height: 8),
                    if (_hasEmailError)
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _emailErrorMessage,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    SizedBox(
                      height: _hasEmailError ? 24 : 80,
                    ), // Adjust spacing
                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('이메일', style: TextStyles.kSemiBold),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading, // ✅ Disable during loading
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: '이메일주소를 입력해주세요',
                            hintStyle: TextStyles.kMedium,
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: CustomColors.darkCharcoal,
                                width: 2,
                              ),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFD32F2F)),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            disabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return '유효한 이메일 주소를 입력해주세요';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (!_isLoading) {
                              _validateEmail(value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('비밀번호', style: TextStyles.kSemiBold),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading, // ✅ Disable during loading
                          obscureText: _isObscurePassword,
                          decoration: InputDecoration(
                            hintText: '비밀번호를 입력해주세요',
                            hintStyle: TextStyles.kMedium,
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: CustomColors.darkCharcoal,
                                width: 2,
                              ),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            disabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFFBDBDBD),
                              ),
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () {
                                        setState(() {
                                          _isObscurePassword =
                                              !_isObscurePassword;
                                        });
                                      },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Auto Login and Password Reset
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 32,
                              width: 32,
                              child: Checkbox(
                                value: _isAutoLogin,
                                onChanged:
                                    _isLoading
                                        ? null
                                        : (value) {
                                          setState(() {
                                            _isAutoLogin = value ?? false;
                                          });
                                        },
                                activeColor: CustomColors.darkCharcoal,
                                checkColor: CustomColors.limeGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                            const Text('자동로그인', style: TextStyles.kRegular),
                          ],
                        ),
                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    context.push('/password-reset');
                                  },
                          child: const Text(
                            '비밀번호 재설정',
                            style:
                                TextStyles.kTrailingBottomButtonWithUnderline,
                          ),
                        ),
                      ],
                    ),
                    // Use flexible spacing instead of Spacer
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    // Social Login Link
                    Center(
                      child: TextButton(
                        onPressed:
                            _isLoading ? null : _showSocialLoginBottomSheet,
                        child: const Text(
                          '구글 또는 애플아이디로 로그인하기',
                          style: TextStyles.kTrailingBottomButtonWithUnderline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Login Button
                    CustomButton(
                      text: _isLoading ? '로그인 중...' : '로그인',
                      onPressed: _isLoading ? null : _handleLogin,
                      isEnabled:
                          _emailController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty &&
                          !_isLoading,
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFFBDBDBD),
                      disabledTextColor: Colors.white,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
