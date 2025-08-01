import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PasswordResetConfirmationScreen extends StatefulWidget {
  @override
  _PasswordResetConfirmationScreenState createState() =>
      _PasswordResetConfirmationScreenState();
}

class _PasswordResetConfirmationScreenState
    extends State<PasswordResetConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: CustomColors.lighterGray,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: '비밀번호 재설정',
              showTrailingButton: false,
              showBackButton: true,
              onBackPressed: () {
                context.pop();
              },
              backgroundColor: CustomColors.lighterGray,
            ),
            SizedBox(height: 20),

            // Header Text Section
            Container(
              color: CustomColors.lighterGray,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      color: CustomColors.lighterGray,
                      width: double.infinity,
                      child: Text('비밀번호 재설정을\n진행할까요?', style: TextStyles.kBody),
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      color: CustomColors.lighterGray,
                      width: double.infinity,
                      child: Text(
                        '인증번호가 이메일로 발송될 예정이니\n먼저 기입하신 이메일을 확인해주세요.',
                        style: TextStyles.kMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // Form Container with Grey Background
            Expanded(
              child: Container(
                color: CustomColors.lighterGray,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Empty space to maintain the same layout
                      Spacer(),

                      // Next Button
                      CustomButton(
                        text: '다음',
                        isEnabled: true,
                        onPressed: () {
                          // Handle next button press
                          print('Password reset confirmed');
                          // You can add navigation or reset logic here
                        },
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
