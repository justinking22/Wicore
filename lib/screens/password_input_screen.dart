import 'package:Wicore/dialogs/confirmation_dialog.dart'
    show ExitConfirmationDialogWithOptions;
import 'package:Wicore/utilities/sign_up_form_state.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordInputScreen extends ConsumerStatefulWidget {
  const PasswordInputScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasswordInputScreen> createState() =>
      _PasswordInputScreenState();
}

class _PasswordInputScreenState extends ConsumerState<PasswordInputScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _obscureText = true;
  String? _errorText;
  bool _showPasswordCriteria = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);

    // Load existing password if user goes back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signUpForm = ref.read(signUpFormProvider);
      if (signUpForm.password.isNotEmpty) {
        _passwordController.text = signUpForm.password;
        _validatePassword(_passwordController.text);
      }
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    _validatePassword(_passwordController.text);
  }

  bool _isPasswordValid(String password) {
    // Check if password contains both letters and numbers and is at least 7 characters
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool isLongEnough = password.length >= 7;

    return hasLetter && hasNumber && isLongEnough;
  }

  void _validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        _isButtonEnabled = false;
        _errorText = null;
        _showPasswordCriteria = false;
      } else {
        // Enable button after typing at least one character
        _isButtonEnabled = true;
        _errorText = null;

        // Show criteria error if password doesn't meet requirements
        _showPasswordCriteria = !_isPasswordValid(password);
      }
    });
  }

  Future<void> _handleNext() async {
    if (!_isButtonEnabled) return;

    final password = _passwordController.text.trim();

    // Check if password meets criteria before proceeding
    if (!_isPasswordValid(password)) {
      // Don't navigate, just ensure the error is shown
      setState(() {
        _showPasswordCriteria = true;
      });
      return;
    }

    print('User entered valid password: $password');

    // Save password to provider
    ref.read(signUpFormProvider.notifier).setPassword(password);

    // Navigate to password confirmation screen
    context.push('/password-re-enter');
  }

  @override
  Widget build(BuildContext context) {
    final signUpForm = ref.watch(signUpFormProvider);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                  Text('안전한 비밀번호를', style: TextStyles.kBody),
                  const SizedBox(height: 8),
                  Text('만들어주세요', style: TextStyles.kBody),

                  // Show password criteria error or normal subtitle
                  if (_showPasswordCriteria) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: CustomColors.translucentRedOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '영문과 숫자를 포함하여 7자 이상 인지 다시 확인해주세요.',
                        style: TextStyles.kError,
                      ),
                    ),
                    const SizedBox(height: 60),
                  ] else ...[
                    const SizedBox(height: 24),
                    // Subtitle text (only shown when no errors)
                    Text('비밀번호는 7자 이상,', style: TextStyles.kThirdBody),
                    const SizedBox(height: 4),
                    Text('영문과 숫자를 포함해 만들어주세요.', style: TextStyles.kThirdBody),
                    const SizedBox(height: 60),
                  ],

                  // Input field label
                  Text('비밀번호', style: TextStyles.kHeader),
                  const SizedBox(height: 8),
                  // Password input field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    obscuringCharacter: '●',
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해주세요',
                      hintStyle: TextStyles.kMedium,
                      errorText: _errorText,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
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
                    text: '다음',
                    isEnabled: _isButtonEnabled,
                    onPressed: _isButtonEnabled ? _handleNext : null,
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
