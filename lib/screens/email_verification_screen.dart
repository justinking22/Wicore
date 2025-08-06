import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/utilities/sign_up_form_state.dart';

import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;

  Future<void> _handleNext() async {
    context.go('/login');
  }

  Future<void> _handleResendEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final signUpForm = ref.read(signUpFormProvider);
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Use the resend confirmation code method from your auth system
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

        const SizedBox(height: 32),

        // Information text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '이메일 확인 안내',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '이메일의 인증 링크를 클릭하여 계정을 활성화한 후\n로그인 화면에서 로그인해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Next button - goes to login
        CustomButton(text: '로그인 화면으로', isEnabled: true, onPressed: _handleNext),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          onBackPressed: () {
            Navigator.pop(context);
          },
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
              child: _buildEmailSentView(),
            ),
          ),
        ),
      ),
    );
  }
}
