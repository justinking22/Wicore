import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationSuccessScreen extends StatefulWidget {
  const EmailVerificationSuccessScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationSuccessScreen> createState() =>
      _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState
    extends State<EmailVerificationSuccessScreen> {
  void _handleNext() {
    // Navigate to main app or home screen
    context.push('/terms-and-conditions');
    // You can also use context.go('/home') if you want to replace the current route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '회원가입',
        onBackPressed: () => Navigator.pop(context),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Celebration emoji
            const Text('🎉', style: TextStyle(fontSize: 48)),

            // Title text
            Text('이메일 인증 성공!', style: TextStyles.kBody),
            const SizedBox(height: 8),
            Text('이제 마지막 단계예요', style: TextStyles.kBody),

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
        ),
      ),
    );
  }
}
