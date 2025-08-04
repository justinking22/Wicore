import 'package:Wicore/dialogs/confirmation_dialog.dart';

import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/utilities/sign_up_form_state.dart';
import 'package:Wicore/services/api_service.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmailInputScreen extends ConsumerStatefulWidget {
  const EmailInputScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends ConsumerState<EmailInputScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isCheckingEmail = false;
  String? _errorText;
  String? _emailExistsError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);

    // Load existing email if user goes back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signUpForm = ref.read(signUpFormProvider);
      if (signUpForm.email.isNotEmpty) {
        _emailController.text = signUpForm.email;
        _validateEmail(_emailController.text);
      }
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _validateEmail(_emailController.text);
    // Clear email exists error when user types
    if (_emailExistsError != null) {
      setState(() {
        _emailExistsError = null;
      });
    }
  }

  void _validateEmail(String email) {
    setState(() {
      if (email.trim().isEmpty) {
        _isButtonEnabled = false;
        _errorText = null;
      } else if (!_isValidEmail(email.trim())) {
        _isButtonEnabled = false;
        _errorText = '올바른 이메일 형식을 입력해주세요';
      } else {
        _isButtonEnabled = true;
        _errorText = null;
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ✅ Simple approach: Just validate and store email, proceed to next step
  Future<void> _handleNext() async {
    if (!_isButtonEnabled || _isCheckingEmail) return;

    final email = _emailController.text.trim();
    print('User entered email: $email');

    // Just save the email and proceed - no API call needed here
    ref.read(signUpFormProvider.notifier).setEmail(email);

    if (mounted) {
      context.push('/password-input');
    }
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
          onBackPressed: () => Navigator.pop(context),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Title text
                  Text('회원님이 사용중인', style: TextStyles.kBody),
                  const SizedBox(height: 8),
                  Text('이메일을 입력해주세요', style: TextStyles.kBody),
                  const SizedBox(height: 24),
                  // Subtitle text
                  Text('인증번호가 발송될 예정이니', style: TextStyles.kSecondBody),
                  const SizedBox(height: 4),
                  Text('정확한 이메일 주소를 확인해주세요.', style: TextStyles.kSecondBody),
                  const SizedBox(height: 60),

                  // Email exists error message
                  if (_emailExistsError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F2), // Light pink background
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFCDD2), // Pink border
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _emailExistsError!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFD32F2F), // Red text
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Input field label
                  Text('이메일', style: TextStyles.kHeader),
                  const SizedBox(height: 8),
                  // Email input field
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: '예) withforce@naver.com',
                      hintStyle: TextStyles.kMedium,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 0,
                      ),
                    ),
                    style: TextStyles.kInputText,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_isButtonEnabled) {
                        _handleNext(); // ✅ Use the simple approach by default
                      }
                    },
                  ),
                  const Spacer(),
                  // Next button
                  CustomButton(
                    text: _isCheckingEmail ? '확인 중...' : '다음',
                    isEnabled: _isButtonEnabled && !_isCheckingEmail,
                    onPressed:
                        (_isButtonEnabled && !_isCheckingEmail)
                            ? _handleNext // ✅ Use simple approach by default
                            : null,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
