import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart';
import 'package:with_force/styles/colors.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_app_bar.dart';
import 'package:with_force/widgets/reusable_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: '회원가입',
        showBackButton: true, // No back button on welcome screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // Wave emoji
            const Text('👋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 24),
            // Welcome text
            Text('환영합니다!', style: TextStyles.kBody),

            // Description text
            Text('wicore의 회원가입을\n도와드리겠습니다', style: TextStyles.kBody),
            const Spacer(),
            // Next button
            CustomButton(
              text: '다음',
              onPressed: () {
                // Navigate to the first step of the registration process
                context.push('/name-input');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
