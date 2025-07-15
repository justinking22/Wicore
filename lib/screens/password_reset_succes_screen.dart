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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // Lock icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 24,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 32),
            // Success message
            Text('비밀번호 재설정 완료!\n새 비밀번호로\n로그인 해주세요', style: TextStyles.kBody),
            const Spacer(),
            // Confirm button
            CustomButton(
              text: '확인',
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
