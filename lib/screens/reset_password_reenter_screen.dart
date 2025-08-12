// password_reset_confirm_screen.dart - Step 3: Confirm password with right-aligned button
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordResetConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, String> resetData; // Contains email and password

  const PasswordResetConfirmScreen({Key? key, required this.resetData})
    : super(key: key);

  @override
  ConsumerState<PasswordResetConfirmScreen> createState() =>
      _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState
    extends ConsumerState<PasswordResetConfirmScreen>
    with TickerProviderStateMixin {
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isButtonEnabled = false;
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorText;
  String? _passwordMismatchError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_onPasswordChanged);

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
    _confirmPasswordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      final confirmPassword = _confirmPasswordController.text;
      _isButtonEnabled = confirmPassword.isNotEmpty;
      _passwordMismatchError = null;
    });
  }

  // Send forgot password email and navigate to OTP screen
  Future<void> _handleConfirm() async {
    if (!_isButtonEnabled || _isLoading) return;

    final confirmPassword = _confirmPasswordController.text.trim();
    final originalPassword = widget.resetData['password']!;
    final email = widget.resetData['email']!;

    if (confirmPassword != originalPassword) {
      setState(() {
        _passwordMismatchError = '비밀번호가 일치하지 않습니다. 다시 한 번 입력해주세요.';
      });
      return;
    }

    print('🔐 Passwords match - sending forgot password email to: $email');

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ NOW we call the forgot password API to send OTP
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final result = await authNotifier.forgotPassword(email: email);

      if (result.isSuccess) {
        print('✅ OTP sent successfully to: $email');
        if (mounted) {
          // Navigate to OTP screen with email and new password
          context.push(
            '/password-reset-otp',
            extra: {'email': email, 'newPassword': originalPassword},
          );
        }
      } else {
        print('❌ Failed to send OTP: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '인증번호 발송에 실패했습니다.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                      Text('비밀번호를', style: TextStyles.kBody),
                      const SizedBox(height: 8),
                      Text('다시 한 번 입력해주세요', style: TextStyles.kBody),
                      const SizedBox(height: 16),
                      Text(
                        '입력한 비밀번호가 맞는지 확인할게요.',
                        style: TextStyles.kThirdBody,
                      ),

                      if (_passwordMismatchError != null) ...[
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4F4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _passwordMismatchError!,
                            style: const TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                      ] else ...[
                        const SizedBox(height: 84),
                      ],

                      Text('비밀번호 확인', style: TextStyles.kHeader),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        enabled: !_isLoading,
                        obscureText: _obscureText,
                        obscuringCharacter: '●',
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력해주세요',
                          hintStyle: TextStyles.kMedium,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
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
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _isLoading ? Colors.grey : Colors.black,
                          letterSpacing: 1.5,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleConfirm(),
                      ),

                      const SizedBox(height: 24),

                      // ✅ FIXED: Right-aligned "비밀번호를 까먹었어요" button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    Navigator.pop(context);
                                  },
                          child: Text(
                            '비밀번호를 까먹었어요',
                            style: TextStyle(
                              color: _isLoading ? Colors.grey : Colors.black54,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                      CustomButton(
                        text: _isLoading ? '인증번호 발송 중...' : '확인',
                        isEnabled: _isButtonEnabled && !_isLoading,
                        onPressed:
                            (_isButtonEnabled && !_isLoading)
                                ? _handleConfirm
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
        ),
      ),
    );
  }
}
