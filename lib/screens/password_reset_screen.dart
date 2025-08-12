import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;
  String? _errorText;
  String? _emailNotFoundError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _validateEmail(_emailController.text);
    if (_emailNotFoundError != null) {
      setState(() {
        _emailNotFoundError = null;
      });
    }
  }

  void _validateEmail(String email) {
    setState(() {
      if (email.trim().isEmpty) {
        _isButtonEnabled = false;
        _errorText = null;
      } else if (!_isValidEmail(email.trim())) {
        _isButtonEnabled = false;
        _errorText = '올바른 이메일 형식을 입력해주세요';
      } else {
        _isButtonEnabled = true;
        _errorText = null;
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Just validate email and move to password screen - NO API call yet
  Future<void> _handleNext() async {
    if (!_isButtonEnabled) return;

    final email = _emailController.text.trim();
    print('📧 Email validated: $email - moving to password screen');

    if (mounted) {
      // Navigate directly to new password screen with email
      context.push('/password-reset-new', extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: '비밀번호 재설정',
          onBackPressed: () => Navigator.pop(context),
          showTrailingButton: false,
          showExitDialog: true,
          exitRoute: '/login',
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
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
                      Text('회원가입시 사용한', style: TextStyles.kBody),
                      const SizedBox(height: 8),
                      Text('이메일을 입력해주세요', style: TextStyles.kBody),

                      const SizedBox(height: 24),
                      Text(
                        '새로운 비밀번호를 설정한 후 인증번호를 받게 됩니다.',
                        style: TextStyles.kThirdBody,
                      ),
                      const SizedBox(height: 60),

                      Text('이메일', style: TextStyles.kHeader),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: '예) withforce@naver.com',
                          hintStyle: TextStyles.kMedium,
                          errorText: _errorText,
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
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2,
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
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleNext(),
                      ),

                      const Spacer(),
                      CustomButton(
                        text: '다음',
                        isEnabled: _isButtonEnabled,
                        onPressed: _isButtonEnabled ? _handleNext : null,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      const SizedBox(height: 32),
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
