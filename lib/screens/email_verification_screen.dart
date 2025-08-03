import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/utilities/sign_up_form_state.dart';
import 'package:Wicore/services/api_service.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isResending = false;
  bool _showVerificationCode = false;
  bool _isVerifying = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _codeController = TextEditingController();
  bool _isCodeComplete = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final code = _codeController.text;
    setState(() {
      _isCodeComplete = code.length == 6;
    });
  }

  Future<void> _handleNext() async {
    setState(() {
      _showVerificationCode = true;
    });
    _animationController.forward();
  }

  Future<void> _handleResendEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final signUpForm = ref.read(signUpFormProvider);
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // ✅ Use the resend confirmation code method from your auth system
      final result = await authNotifier.resendConfirmationCode(
        email: signUpForm.email,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증번호가 다시 전송되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '인증번호 재전송에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error resending email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호 재전송에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // ✅ Method to handle email verification using your auth system
  Future<void> _handleVerifyCode() async {
    if (!_isCodeComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final code = _codeController.text;
      final signUpForm = ref.read(signUpFormProvider);
      final authNotifier = ref.read(authNotifierProvider.notifier);

      print('Verifying code: $code for email: ${signUpForm.email}');

      // Option 1: If you have a dedicated email verification endpoint
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/auth/verify-email',
        data: {'email': signUpForm.email, 'verificationCode': code},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // Navigate to success screen
          context.push('/success-verification');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data?['message'] ?? '인증번호가 올바르지 않습니다. 다시 시도해주세요.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error verifying code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호가 올바르지 않습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ✅ Alternative method using the signup flow with verification
  Future<void> _handleVerifyCodeWithSignup() async {
    if (!_isCodeComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final code = _codeController.text;
      final signUpForm = ref.read(signUpFormProvider);
      final authNotifier = ref.read(authNotifierProvider.notifier);

      print('Verifying and completing signup...');

      // Complete the signup process with all collected data
      final result = await authNotifier.signUp(
        email: signUpForm.email,
        password: signUpForm.password,
      );

      if (result.isSuccess) {
        if (mounted) {
          // Navigate to success screen
          context.push('/success-verification');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '회원가입에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error completing signup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Widget _buildEmailSentView() {
    final signUpForm = ref.watch(signUpFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // Title text
        Text('아래의 이메일 주소로', style: TextStyles.kBody),
        const SizedBox(height: 8),
        Text('인증번호를 보냈어요', style: TextStyles.kBody),
        const SizedBox(height: 40),

        // Email display container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: CustomColors.lighterGray, // Light grey background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            signUpForm.email.isNotEmpty ? signUpForm.email : 'user@email.com',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Resend email option
        Row(
          children: [
            const Text(
              '이메일을 받지 못하셨나요? ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
            GestureDetector(
              onTap: _isResending ? null : _handleResendEmail,
              child: Text(
                _isResending ? '전송 중...' : '다시 보내기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isResending ? Colors.grey : Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        // Next button
        CustomButton(
          text: '다음',
          isEnabled: true,
          onPressed: _handleNext,
          disabledBackgroundColor: Colors.grey,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildVerificationCodeView() {
    final signUpForm = ref.watch(signUpFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // Title text
        Text('이메일로 받은', style: TextStyles.kBody),
        Text('인증번호를 입력해주세요', style: TextStyles.kBody),
        const SizedBox(height: 20),

        // Email display container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), // Light grey background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            signUpForm.email.isNotEmpty ? signUpForm.email : 'user@email.com',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ),

        const SizedBox(height: 60),

        // Input field label
        Text('인증번호', style: TextStyles.kHeader),
        const SizedBox(height: 8),

        // Verification code input field
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            hintText: '이메일을 열어보시고, 숫자를 입력해주세요.',
            hintStyle: TextStyles.kMedium,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 0,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_isCodeComplete && !_isVerifying) {
              _handleVerifyCode();
            }
          },
        ),

        const SizedBox(height: 24),

        // Resend code option
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _isResending ? null : _handleResendEmail,
              child: Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CustomColors.darkCharcoal,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  _isResending ? '전송 중...' : '인증번호가 도착하지 않았어요',
                  style: TextStyles.kRegular,
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        // Verify button
        CustomButton(
          text: _isVerifying ? '인증 중...' : '확인',
          isEnabled: _isCodeComplete && !_isVerifying,
          onPressed:
              (_isCodeComplete && !_isVerifying) ? _handleVerifyCode : null,
          disabledBackgroundColor: Colors.grey,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated) {
        // If authenticated after verification, navigate to home
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '회원가입',
        onBackPressed: () {
          if (_showVerificationCode) {
            // If showing verification code, go back to email sent view
            setState(() {
              _showVerificationCode = false;
            });
            _animationController.reverse();
          } else {
            Navigator.pop(context);
          }
        },
        showTrailingButton: true,
        onTrailingPressed: () {
          ExitConfirmationDialogWithOptions.show(
            context,
            exitRoute: '/welcome',
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          children: [
            // Email sent view (always present)
            if (!_showVerificationCode) _buildEmailSentView(),

            // Verification code view (slides in from right)
            if (_showVerificationCode)
              SlideTransition(
                position: _slideAnimation,
                child: _buildVerificationCodeView(),
              ),
          ],
        ),
      ),
    );
  }
}
