// password_reset_new_password_screen.dart - Step 2: New password input
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordResetNewPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const PasswordResetNewPasswordScreen({Key? key, required this.email})
    : super(key: key);

  @override
  ConsumerState<PasswordResetNewPasswordScreen> createState() =>
      _PasswordResetNewPasswordScreenState();
}

class _PasswordResetNewPasswordScreenState
    extends ConsumerState<PasswordResetNewPasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _obscureText = true;
  String? _errorText;
  bool _showPasswordCriteria = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);

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
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    _validatePassword(_passwordController.text);
  }

  bool _isPasswordValid(String password) {
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool isLongEnough = password.length >= 7;
    return hasLetter && hasNumber && isLongEnough;
  }

  void _validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        _isButtonEnabled = false;
        _errorText = null;
        _showPasswordCriteria = false;
      } else {
        _isButtonEnabled = true;
        _errorText = null;
        _showPasswordCriteria = !_isPasswordValid(password);
      }
    });
  }

  Future<void> _handleNext() async {
    if (!_isButtonEnabled) return;

    final password = _passwordController.text.trim();

    if (!_isPasswordValid(password)) {
      setState(() {
        _showPasswordCriteria = true;
      });
      return;
    }

    print('✅ Password validated - moving to confirmation screen');

    // Navigate to confirmation screen with email and password
    context.push(
      '/password-reset-confirm',
      extra: {'email': widget.email, 'password': password},
    );
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
          showTrailingButton: true,
          onTrailingPressed: () => context.go('/login'),
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
                      Text('안전한 비밀번호를', style: TextStyles.kBody),
                      const SizedBox(height: 8),
                      Text('만들어주세요', style: TextStyles.kBody),

                      if (_showPasswordCriteria) ...[
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4F4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '영문과 숫자를 포함하여 7자 이상 인지 다시 확인해주세요.',
                            style: TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                      ] else ...[
                        const SizedBox(height: 24),
                        Text('비밀번호는 7자 이상,', style: TextStyles.kThirdBody),
                        const SizedBox(height: 4),
                        Text(
                          '영문과 숫자를 포함해 만들어주세요.',
                          style: TextStyles.kThirdBody,
                        ),
                        const SizedBox(height: 60),
                      ],

                      Text('비밀번호', style: TextStyles.kHeader),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        obscuringCharacter: '●',
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력해주세요',
                          hintStyle: TextStyles.kMedium,
                          errorText: _errorText,
                          suffixIcon: TextButton(
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero, // Remove default min size
                              padding:
                                  EdgeInsets.zero, // Remove default padding
                              tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap, // Reduce hit area if needed
                            ),
                            child: Text(
                              _obscureText ? '보기' : '숨기기',
                              style: TextStyles.kMedium.copyWith(
                                color: CustomColors.darkCharcoal,
                              ),
                            ),
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          letterSpacing: 1.5,
                        ),
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
