import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/utilities/sign_up_form_state.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/models/user_update_request_model.dart';
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
  final ScrollController _scrollController =
      ScrollController(); // ✅ ADD: Scroll controller
  bool _isAutoLogin = true;
  bool _isObscureText = true;
  bool _hasEmailError = false;
  String _emailErrorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose(); // ✅ ADD: Dispose scroll controller
    super.dispose();
  }

  // ✅ ADD: Method to scroll to focused field when keyboard appears
  void _scrollToField(GlobalKey fieldKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (fieldKey.currentContext != null) {
        final RenderBox renderBox =
            fieldKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final screenHeight = MediaQuery.of(context).size.height;
        final fieldBottom = position.dy + renderBox.size.height;
        final visibleHeight = screenHeight - keyboardHeight;

        if (fieldBottom > visibleHeight - 100) {
          // 100px buffer
          final scrollOffset =
              fieldBottom - visibleHeight + 150; // Extra buffer
          _scrollController.animateTo(
            _scrollController.offset + scrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  // ✅ ADD: Global keys for form fields
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();

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

  Future<void> _updateUserProfileAfterLogin() async {
    try {
      final signUpForm = ref.read(signUpFormProvider);

      if (signUpForm.name.isNotEmpty) {
        print(
          '🔄 Login successful, updating profile with stored name: ${signUpForm.name}',
        );

        await Future.delayed(const Duration(milliseconds: 300));

        await ref
            .read(userProvider.notifier)
            .updateCurrentUserProfile(
              UserUpdateRequest(firstName: signUpForm.name),
            );

        print('✅ User profile updated with name after login');

        ref.read(signUpFormProvider.notifier).reset();

        if (mounted) {
          _showMessage('프로필이 업데이트되었습니다!', backgroundColor: Colors.green);
        }
      }
    } catch (e) {
      print('⚠️ Failed to update profile after login: $e');
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
          if (_isAutoLogin) {
            print('Auto-login enabled for user');
          }

          await _updateUserProfileAfterLogin();

          _showMessage('로그인 성공!', backgroundColor: Colors.green);
          context.go('/navigation');
        } else if (result.data?.accessToken == null) {
          setState(() {
            _hasEmailError = true;
            _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
          });
        } else {
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
    } catch (e) {
      if (mounted) {
        _showMessage('Google 로그인 오류: $e');
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    try {
      _showMessage('Apple 로그인 기능을 준비 중입니다.', backgroundColor: Colors.orange);
    } catch (e) {
      if (mounted) {
        _showMessage('Apple 로그인 오류: $e');
      }
    }
  }

  void _handleContinueWithoutLogin() {
    _showMessage('게스트 모드 기능을 준비 중입니다.', backgroundColor: Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/navigation');
      }
    });

    // ✅ APPLY: Same pattern as NameInputScreen
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final availableHeight = screenHeight - keyboardHeight;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        // ✅ KEEP: Overflow protection like NameInputScreen
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
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              // ✅ APPLY: Same height calculation pattern
              constraints: BoxConstraints(
                minHeight:
                    availableHeight -
                    (MediaQuery.of(context).padding.top + kToolbarHeight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ APPLY: Keyboard-aware top spacing
                      SizedBox(height: isKeyboardVisible ? 20 : 40),

                      Text('반갑습니다\n로그인을 해주세요', style: TextStyles.kBody),

                      // ✅ APPLY: Dynamic spacing after title
                      SizedBox(height: isKeyboardVisible ? 16 : 32),

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

                      // ✅ APPLY: Smart spacing adjustment
                      SizedBox(
                        height:
                            _hasEmailError
                                ? (isKeyboardVisible ? 16 : 24)
                                : (isKeyboardVisible ? 32 : 80),
                      ),

                      // Email Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('이메일', style: TextStyles.kSemiBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: '이메일주소를 입력해주세요',
                              hintStyle: TextStyles.kMedium,
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: CustomColors.darkCharcoal,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              disabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD),
                                ),
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

                      // ✅ APPLY: Keyboard-aware spacing between fields
                      SizedBox(height: isKeyboardVisible ? 24 : 32),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('비밀번호', style: TextStyles.kSemiBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _isObscureText,
                            decoration: InputDecoration(
                              hintText: '비밀번호를 입력해주세요',
                              hintStyle: TextStyles.kMedium,
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: CustomColors.darkCharcoal,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              disabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              suffixIcon: TextButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () {
                                          setState(() {
                                            _isObscureText = !_isObscureText;
                                          });
                                        },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isObscureText ? '보기' : '숨기기',
                                  style: TextStyles.kMedium.copyWith(
                                    color:
                                        _isLoading
                                            ? Colors.grey
                                            : CustomColors.darkCharcoal,
                                  ),
                                ),
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

                      // ✅ APPLY: Condensed spacing when keyboard visible
                      SizedBox(height: isKeyboardVisible ? 16 : 24),

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

                      // ✅ APPLY: Flexible spacing like NameInputScreen
                      SizedBox(
                        height:
                            isKeyboardVisible
                                ? 20 // Minimal spacing when keyboard up
                                : availableHeight -
                                    600, // Flexible when keyboard down
                      ),

                      // Social Login Link
                      Center(
                        child: TextButton(
                          onPressed:
                              _isLoading ? null : _showSocialLoginBottomSheet,
                          child: const Text(
                            '구글 또는 애플아이디로 로그인하기',
                            style:
                                TextStyles.kTrailingBottomButtonWithUnderline,
                          ),
                        ),
                      ),

                      // ✅ APPLY: Reduced spacing when keyboard visible
                      SizedBox(height: isKeyboardVisible ? 8 : 16),

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

                      // ✅ APPLY: Same bottom padding pattern as NameInputScreen
                      SizedBox(
                        height: isKeyboardVisible ? keyboardHeight + 20 : 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
