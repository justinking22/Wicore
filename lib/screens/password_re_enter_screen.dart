import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/providers/sign_up_form_state.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Import your signUpFormProvider

class PasswordConfirmationScreen extends ConsumerStatefulWidget {
  const PasswordConfirmationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasswordConfirmationScreen> createState() =>
      _PasswordConfirmationScreenState();
}

class _PasswordConfirmationScreenState
    extends ConsumerState<PasswordConfirmationScreen> {
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isButtonEnabled = false;
  bool _obscureText = true;
  String? _errorText;
  String? _passwordMismatchError;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _confirmPasswordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    _validatePassword(_confirmPasswordController.text);
    // Clear password mismatch error when user types
    if (_passwordMismatchError != null) {
      setState(() {
        _passwordMismatchError = null;
      });
    }
  }

  void _validatePassword(String confirmPassword) {
    setState(() {
      if (confirmPassword.isEmpty) {
        _isButtonEnabled = false;
        _errorText = null;
      } else {
        _isButtonEnabled = true;
        _errorText = null;
      }
    });
  }

  Future<void> _handleNext() async {
    if (!_isButtonEnabled) return;

    final confirmPassword = _confirmPasswordController.text.trim();
    final signUpForm = ref.read(signUpFormProvider);
    final originalPassword = signUpForm.password;

    print('Confirming password: $confirmPassword');

    // Check if passwords match
    if (confirmPassword != originalPassword) {
      _showPasswordMismatchError();
      return;
    }

    // Navigate to email verification screen
    context.push('/email-verification');
  }

  void _showPasswordMismatchError() {
    setState(() {
      _passwordMismatchError = '비밀번호가 일치하지 않습니다. 다시 한 번 입력해주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final signUpForm = ref.watch(signUpFormProvider);

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
            Text('비밀번호를', style: TextStyles.kBody),
            const SizedBox(height: 8),
            Text('다시 한 번 입력해주세요', style: TextStyles.kBody),
            // Conditional content: Either error message OR subtitle text
            if (_passwordMismatchError != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color:
                      CustomColors
                          .translucentRedOrange, // Light pink background
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_passwordMismatchError!, style: TextStyles.kError),
              ),
              const SizedBox(height: 60),
            ] else ...[
              const SizedBox(height: 24),
              // Subtitle text
              Text('입력한 비밀번호가 맞는지 확인할게요.', style: TextStyles.kThirdBody),
              const SizedBox(height: 60),
            ],

            // Input field label
            Text('비밀번호 확인', style: TextStyles.kHeader),
            const SizedBox(height: 8),
            // Password confirmation input field
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureText,
              obscuringCharacter: '\u2B24',
              decoration: InputDecoration(
                hintText: '비밀번호를 다시 입력해주세요',
                hintStyle: TextStyles.kMedium,
                errorText: _errorText,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                errorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
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
                letterSpacing: 1.5,
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
              text: '확인',
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
