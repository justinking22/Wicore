import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_button.dart';

class PrepDoneScreen extends StatefulWidget {
  const PrepDoneScreen({Key? key}) : super(key: key);

  @override
  State<PrepDoneScreen> createState() => _PrepDoneScreenState();
}

class _PrepDoneScreenState extends State<PrepDoneScreen> {
  void _handleNext() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: const Text('준비 완료', style: TextStyles.kTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // Party emoji
            const Text('🎉', style: TextStyle(fontSize: 30)),

            const SizedBox(height: 8),

            // Title text
            Text('모두 마무리 되었어요', style: TextStyles.kBody),
            Text('이제 이용을', style: TextStyles.kBody),
            Text('시작해 주세요', style: TextStyles.kBody),

            const Spacer(),

            // Next button
            CustomButton(
              text: '시작하기',
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
