import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/dialogs/settings_confirmation_dialog.dart';
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

  // Updated _handleNext method to show dialog before going to login
  Future<void> _handleNext() async {
    final shouldProceed = await EmailVerificationCompletionDialog.show(context);
    if (shouldProceed == true && mounted) {
      context.go('/login');
    }
  }

  // Remove the _handleResendEmail method entirely
  // Remove the _isResending variable from the class

  // Updated _buildEmailSentView method
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

        const Spacer(),

        // Next button - shows dialog then goes to login
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
