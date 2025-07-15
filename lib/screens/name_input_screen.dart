import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/providers/sign_up_provider.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({Key? key}) : super(key: key);

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);

    // Load existing name if user goes back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signUpProvider = Provider.of<SignUpProvider>(
        context,
        listen: false,
      );
      if (signUpProvider.name.isNotEmpty) {
        _nameController.text = signUpProvider.name;
        _isButtonEnabled = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty;
    });
  }

  void _handleNext() {
    if (_nameController.text.trim().isNotEmpty) {
      // Handle the next action
      final name = _nameController.text.trim();
      print('User entered name: $name');

      Provider.of<SignUpProvider>(context, listen: false).setName(name);

      context.push('/email-input');
    }
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
            // Title text
            const Text(
              '먼저',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '이름을 알려주세요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 60),
            // Input field label
            Text('이름', style: TextStyles.kHeader),
            const SizedBox(height: 8),
            // Name input field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예) 홍길동',
                hintStyle: TextStyles.kMedium,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 0,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_isButtonEnabled) {
                  _handleNext();
                }
              },
            ),
            const Spacer(),
            // Next button
            CustomButton(
              text: '다음',
              isEnabled: _isButtonEnabled,
              onPressed: _isButtonEnabled ? _handleNext : null,
              disabledBackgroundColor: Colors.grey,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
