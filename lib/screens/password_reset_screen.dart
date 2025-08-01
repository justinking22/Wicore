import 'package:Wicore/providers/authentication_provider.dart';
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

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isSendingReset = false;
  String? _errorText;
  String? _emailNotFoundError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _validateEmail(_emailController.text);
    // Clear email not found error when user types
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

  // ✅ Integrated with your authentication system
  Future<void> _handlePasswordReset() async {
    if (!_isButtonEnabled || _isSendingReset) return;

    final email = _emailController.text.trim();
    print('User requested password reset for: $email');

    setState(() {
      _isSendingReset = true;
      _emailNotFoundError = null;
    });

    try {
      // ✅ Use your auth system's forgot password method
      final authNotifier = ref.read(authNotifierProvider.notifier);

      final result = await authNotifier.forgotPassword(email: email);

      if (result.isSuccess) {
        print('✅ Password reset successful, navigating to success screen');
        if (mounted) {
          // Navigate to success screen and pass email for reference
          context.push(
            '/password-reset-success?email=${Uri.encodeComponent(email)}',
          );
        }
      } else {
        // Handle different error cases
        if (mounted) {
          // Check if email doesn't exist (adjust based on your API response)
          if (result.message?.contains('not found') == true ||
              result.message?.contains('존재하지 않는') == true ||
              result.message?.contains('User does not exist') == true ||
              result.code == 'USER_NOT_FOUND') {
            _showEmailNotFoundError();
          } else {
            // Other error - show generic message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message ?? '오류가 발생했습니다. 다시 시도해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error during password reset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReset = false;
        });
      }
    }
  }

  void _showEmailNotFoundError() {
    setState(() {
      _emailNotFoundError = '등록되지 않은 이메일입니다. 회원가입시 사용한 이메일을 입력해주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '비밀번호 재설정',
        onBackPressed: () => Navigator.pop(context),
        showTrailingButton: false,
        showExitDialog: true,
        exitRoute: '/login',
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // Title text
            Text('회원가입시 사용한', style: TextStyles.kBody),
            const SizedBox(height: 8),
            Text('이메일을 입력해주세요', style: TextStyles.kBody),

            // Conditional content: Either error message OR subtitle text
            if (_emailNotFoundError != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F2), // Light pink background
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFCDD2), // Pink border
                    width: 1,
                  ),
                ),
                child: Text(
                  _emailNotFoundError!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFD32F2F), // Red text
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ] else ...[
              const SizedBox(height: 24),
              // Subtitle text explaining what will happen
              Text('비밀번호 재설정 링크를 이메일로 보내드릴게요.', style: TextStyles.kThirdBody),
              const SizedBox(height: 60),
            ],

            // Input field label
            Text('이메일', style: TextStyles.kHeader),
            const SizedBox(height: 8),
            // Email input field
            TextField(
              controller: _emailController,
              enabled: !_isSendingReset, // ✅ Disable during sending
              decoration: InputDecoration(
                hintText: '예) withforce@naver.com',
                hintStyle: TextStyles.kMedium,
                errorText: _errorText,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
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
                color: _isSendingReset ? Colors.grey : Colors.black,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_isButtonEnabled && !_isSendingReset) {
                  _handlePasswordReset();
                }
              },
            ),

            // ✅ Show sending progress
            if (_isSendingReset) ...[
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '비밀번호 재설정 이메일을 발송하고 있습니다...',
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

            const Spacer(),
            // Reset button
            CustomButton(
              text: _isSendingReset ? '발송 중...' : '재설정 이메일 발송',
              isEnabled: _isButtonEnabled && !_isSendingReset,
              onPressed:
                  (_isButtonEnabled && !_isSendingReset)
                      ? _handlePasswordReset
                      : null,
              disabledBackgroundColor: Colors.grey,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
