import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '비밀번호 재설정',
        onBackPressed: () {
          // Navigate to login instead of going back
          context.go('/login');
        },
        showTrailingButton: false, // No exit button needed here
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Success icon with celebration
            Row(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
              ],
            ),

            // Success message
            Text('비밀번호 재설정 완료!', style: TextStyles.kBody),
            const SizedBox(height: 8),
            Text('새 비밀번호로\n로그인 해주세요', style: TextStyles.kBody),

            const SizedBox(height: 24),

            const Spacer(),

            // Login button
            CustomButton(
              text: '로그인하러 가기',
              onPressed: () {
                // Navigate to login screen
                context.go('/login');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
