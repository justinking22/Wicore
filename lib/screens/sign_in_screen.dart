import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:with_force/styles/colors.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAutoLogin = false;
  bool _isObscurePassword = true;
  bool _hasEmailError = false;
  String _emailErrorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _hasEmailError = true;
        _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
      });
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
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

  void _handleLogin() {
    _validateEmail();
    if (!_hasEmailError && _passwordController.text.isNotEmpty) {
      // Handle login logic here
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 처리 중...')));
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
              // Google and Apple buttons row
              Row(
                children: [
                  // Google button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        // Handle Google sign in
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google 로그인 처리 중...')),
                        );
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
                  // Apple button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        // Handle Apple sign in
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Apple 로그인 처리 중...')),
                        );
                      },
                      child: Container(
                        height: 147,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
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
              // Continue without login button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Handle continue without login
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('로그인 없이 계속하기')));
                },
                child: const Center(
                  child: Text(
                    '안전으로 둘아가기',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('회원가입', style: TextStyles.kTrailingBottomButton),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
            const SizedBox(height: 80),
            // Email Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이메일', style: TextStyles.kSecondTitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '이메일주소를 입력해주세요',
                    hintStyle: TextStyles.kHint,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: CustomColors.darkGray,
                        width: 2,
                      ),
                    ),
                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD32F2F)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (value) {
                    if (_hasEmailError) {
                      setState(() {
                        _hasEmailError = false;
                        _emailErrorMessage = '';
                      });
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
                const Text('비밀번호', style: TextStyles.kSecondTitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscurePassword,
                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력해주세요',
                    hintStyle: TextStyles.kHint,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: CustomColors.darkGray,
                        width: 2,
                      ),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFFBDBDBD),
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscurePassword = !_isObscurePassword;
                        });
                      },
                    ),
                  ),
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
                        onChanged: (value) {
                          setState(() {
                            _isAutoLogin = value ?? false;
                          });
                        },
                        activeColor: CustomColors.darkGray,
                        checkColor: CustomColors.limeGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                    const Text(
                      '자동로그인',
                      style: TextStyles.kTrailingBottomButton,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.push('/password-reset');
                  },
                  child: const Text(
                    '비밀번호 재설정',
                    style: TextStyles.kTrailingBottomButtonWithUnderline,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Social Login Link
            Center(
              child: TextButton(
                onPressed: () {
                  _showSocialLoginBottomSheet();
                  // Handle social login
                },
                child: const Text(
                  '구글 또는 애플아이디로 로그인하기',
                  style: TextStyles.kTrailingBottomButtonWithUnderline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Login Button
            CustomButton(
              text: '로그인',
              onPressed: _handleLogin,
              isEnabled:
                  _emailController.text.isNotEmpty &&
                  _passwordController.text.isNotEmpty,
              backgroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFFBDBDBD),

              disabledTextColor: Colors.white,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
