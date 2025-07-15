import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({Key? key}) : super(key: key);

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen> {
  void _handleNext() {
    context.push('/personal-info-input');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: const Text('회원가입 완료', style: TextStyles.kTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // Party emoji
            const Text('🥳', style: TextStyle(fontSize: 30)),

            // Title text
            Text('회원가입 완료!', style: TextStyles.kBody),

            Text('이용준비를 해볼까요?', style: TextStyles.kBody),

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
