// password_reset_otp_screen.dart - Two-step animated OTP screen
import 'package:Wicore/dialogs/settings_confirmation_dialog.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordResetOTPScreen extends ConsumerStatefulWidget {
  final Map<String, String> resetData; // Contains email and newPassword

  const PasswordResetOTPScreen({Key? key, required this.resetData})
    : super(key: key);

  @override
  ConsumerState<PasswordResetOTPScreen> createState() =>
      _PasswordResetOTPScreenState();
}

class _PasswordResetOTPScreenState extends ConsumerState<PasswordResetOTPScreen>
    with TickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  bool _isButtonEnabled = true; // Initially enabled for "다음" button
  bool _isLoading = false;
  bool _showOtpField = false; // Controls whether to show OTP input
  String? _errorText;

  // Animation controllers
  late AnimationController _pageAnimationController;
  late AnimationController _otpSlideController;

  // Page entrance animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // OTP field slide animation
  late Animation<Offset> _otpSlideAnimation;
  late Animation<double> _otpFadeAnimation;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);

    // Page entrance animation
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // OTP field slide-in animation
    _otpSlideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // OTP field animations - slide from right
    _otpSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0), // Start from right
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _otpSlideController, curve: Curves.easeOutCubic),
    );

    _otpFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _otpSlideController, curve: Curves.easeOutCubic),
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _pageAnimationController.dispose();
    _otpSlideController.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    setState(() {
      final otp = _otpController.text.trim();
      _isButtonEnabled = otp.length >= 4;
      _errorText = null;
    });
  }

  // Handle "다음" button click - show OTP field
  Future<void> _handleShowOtpField() async {
    if (_isLoading) return;

    setState(() {
      _showOtpField = true;
      _isButtonEnabled = false; // Disable until OTP is entered
    });

    // Animate OTP field sliding in from right
    await _otpSlideController.forward();
  }

  // Call changePassword API with email, newPassword, and OTP
  Future<void> _handleOtpSubmit() async {
    if (!_isButtonEnabled || _isLoading) return;

    final otp = _otpController.text.trim();
    final email = widget.resetData['email']!;
    final newPassword = widget.resetData['newPassword']!;

    print('🔐 Submitting password reset:');
    print('   Email: $email');
    print('   OTP: $otp');
    print('   New Password: [HIDDEN]');

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Call changePassword API with email, newPassword, and confirmationCode (OTP)
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final result = await authNotifier.changePassword(
        email: email,
        newPassword: newPassword,
        confirmationCode: otp,
      );

      if (result.isSuccess) {
        print('✅ Password reset successful!');
        if (mounted) {
          // ✅ Navigate to password reset success screen
        }
      } else {
        print('❌ Password reset failed: ${result.message}');
        if (mounted) {
          setState(() {
            _errorText = result.message ?? '인증번호가 올바르지 않습니다.';
          });
        }
      }
    } catch (e) {
      print('❌ Error during password reset: $e');
      if (mounted) {
        setState(() {
          _errorText = '비밀번호 재설정 중 오류가 발생했습니다.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    try {
      print('🔐 User clicked resend OTP');

      // First show confirmation dialog
      final shouldResend = await OTPResendConfirmationDialog.show(context);

      if (shouldResend == true && mounted) {
        print('🔐 User confirmed to resend OTP');

        final email = widget.resetData['email']!;
        print('🔐 Resending OTP to: $email');

        final authNotifier = ref.read(authNotifierProvider.notifier);
        final result = await authNotifier.forgotPassword(email: email);

        if (mounted) {
          if (result.isSuccess) {
            // Show success dialog instead of snackbar
            await OTPSentCompletionDialog.show(context);
            print('✅ OTP resent successfully');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message ?? '인증번호 재전송에 실패했습니다.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        print('🔐 User chose not to resend OTP');
      }
    } catch (e) {
      print('❌ Error resending OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호 재전송에 실패했습니다.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
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

                      // Title - changes based on step
                      Text(
                        _showOtpField ? '이메일로 받은' : '아래의 이메일 주소로',
                        style: TextStyles.kBody,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showOtpField ? '인증번호를 입력해주세요' : '인증번호를 보냈어요',
                        style: TextStyles.kBody,
                      ),

                      const SizedBox(height: 24),

                      // Email container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.resetData['email']!,
                          style: TextStyles.kMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      // OTP field - slides in from right when needed
                      if (_showOtpField) ...[
                        const SizedBox(height: 40),

                        SlideTransition(
                          position: _otpSlideAnimation,
                          child: FadeTransition(
                            opacity: _otpFadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('인증번호', style: TextStyles.kHeader),
                                const SizedBox(height: 8),

                                TextField(
                                  controller: _otpController,
                                  enabled: !_isLoading,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '이메일을 열어보시고, 숫자를 입력해주세요.',
                                    hintStyle: TextStyles.kMedium,
                                    errorText: _errorText,
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder:
                                        const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.red,
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
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleOtpSubmit(),
                                ),

                                const SizedBox(height: 24),

                                // Right-aligned helper button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _resendOtp,
                                    child: Text(
                                      '인증번호가 도착하지 않았어요',
                                      style: TextStyle(
                                        color:
                                            _isLoading
                                                ? Colors.grey
                                                : Colors.black54,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Button - changes function based on step
                      CustomButton(
                        text:
                            _showOtpField
                                ? (_isLoading ? '비밀번호 재설정 중...' : '확인')
                                : '다음',
                        isEnabled: _isButtonEnabled && !_isLoading,
                        onPressed:
                            (_isButtonEnabled && !_isLoading)
                                ? (_showOtpField
                                    ? () {
                                      _handleOtpSubmit;
                                      context.push('/password-reset-success');
                                    }
                                    : _handleShowOtpField)
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
