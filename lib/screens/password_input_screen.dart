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
// Import your signUpFormProvider

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
  String? _passwordError;

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
    // Clear password error when user types
    if (_passwordError != null) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  void _validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        _isButtonEnabled = false;
        _errorText = null;
      } else if (password.length < 8) {
        _isButtonEnabled = false;
        _errorText = '비밀번호는 7자 이상, 영문과 숫자를 포함해 만들어야 합니다.';
      } else {
        _isButtonEnabled = true;
        _errorText = null;
      }
    });
  }

  Future<void> _handleNext() async {
    if (!_isButtonEnabled) return;

    final password = _passwordController.text.trim();
    print('User entered password: $password');

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
                  // Conditional content: Either error message OR subtitle text
                  if (_passwordError != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            CustomColors
                                .translucentRedOrange, // Light pink background
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_passwordError!, style: TextStyles.kError),
                    ),
                    const SizedBox(height: 60),
                  ] else ...[
                    const SizedBox(height: 24),
                    // Subtitle text
                    Text(
                      '비밀번호는 7자 이상,',
                      style:
                          TextStyles.kThirdBody, // Use kSecondBody for subtitle
                    ),
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
                    obscuringCharacter: '●', // Medium circle (smaller than ⚫)
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
                      fontSize:
                          16, // Slightly smaller than 16px for smaller dots
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      letterSpacing: 1.5, // Adjust spacing between dots
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
