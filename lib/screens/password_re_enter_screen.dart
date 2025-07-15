// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:with_force/dialogs/confirmation_dialog.dart';
// import 'package:with_force/providers/sign_up_provider.dart';
// import 'package:with_force/styles/colors.dart';
// import 'package:with_force/styles/text_styles.dart';
// import 'package:with_force/widgets/reusable_app_bar.dart';
// import 'package:with_force/widgets/reusable_button.dart';

// class PasswordConfirmationScreen extends StatefulWidget {
//   const PasswordConfirmationScreen({Key? key}) : super(key: key);

//   @override
//   State<PasswordConfirmationScreen> createState() =>
//       _PasswordConfirmationScreenState();
// }

// class _PasswordConfirmationScreenState
//     extends State<PasswordConfirmationScreen> {
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();
//   bool _isButtonEnabled = false;
//   bool _isCreatingAccount = false;
//   bool _obscureText = true;
//   String? _errorText;
//   String? _passwordMismatchError;

//   @override
//   void initState() {
//     super.initState();
//     _confirmPasswordController.addListener(_onPasswordChanged);
//   }

//   @override
//   void dispose() {
//     _confirmPasswordController.removeListener(_onPasswordChanged);
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _onPasswordChanged() {
//     _validatePassword(_confirmPasswordController.text);
//     // Clear password mismatch error when user types
//     if (_passwordMismatchError != null) {
//       setState(() {
//         _passwordMismatchError = null;
//       });
//     }
//   }

//   void _validatePassword(String confirmPassword) {
//     setState(() {
//       if (confirmPassword.isEmpty) {
//         _isButtonEnabled = false;
//         _errorText = null;
//       } else {
//         _isButtonEnabled = true;
//         _errorText = null;
//       }
//     });
//   }

//   Future<void> _handleCreateAccount() async {
//     if (!_isButtonEnabled || _isCreatingAccount) return;

//     final confirmPassword = _confirmPasswordController.text.trim();
//     final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
//     final originalPassword = signUpProvider.password;

//     print('Confirming password: $confirmPassword');

//     // Check if passwords match
//     if (confirmPassword != originalPassword) {
//       _showPasswordMismatchError();
//       return;
//     }

//     setState(() {
//       _isCreatingAccount = true;
//     });

//     try {
//       // Submit all data at once using your existing AuthService
//       final result = await signUpProvider.submitSignUp();

//       if (result['success']) {
//         // Check if account needs confirmation
//         if (result['requiresConfirmation'] == true) {
//           // Navigate to confirmation screen
//           context.push('/email-verification');
//         }
//       } else {
//         // Show error message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result['message'] ?? '회원가입에 실패했습니다.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error creating account: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isCreatingAccount = false;
//       });
//     }
//   }

//   void _showPasswordMismatchError() {
//     setState(() {
//       _passwordMismatchError = '비밀번호가 일치하지 않습니다. 다시 한 번 입력해주세요.';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<SignUpProvider>(
//       builder: (context, signUpProvider, child) {
//         return Scaffold(
//           backgroundColor: Colors.white,
//           appBar: CustomAppBar(
//             title: '회원가입',
//             onBackPressed: () => Navigator.pop(context),
//             showTrailingButton: true,
//             onTrailingPressed: () {
//               ExitConfirmationDialogWithOptions.show(
//                 context,
//                 exitRoute: '/welcome',
//               );
//             },
//           ),
//           body: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 40),
//                 // Title text
//                 Text('비밀번호를', style: TextStyles.kBody),
//                 const SizedBox(height: 8),
//                 Text('다시 한 번 입력해주세요', style: TextStyles.kBody),
//                 // Conditional content: Either error message OR subtitle text
//                 if (_passwordMismatchError != null) ...[
//                   const SizedBox(height: 24),
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color:
//                           CustomColors
//                               .translucentRedOrange, // Light pink background
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       _passwordMismatchError!,
//                       style: TextStyles.kError,
//                     ),
//                   ),
//                   const SizedBox(height: 60),
//                 ] else ...[
//                   const SizedBox(height: 24),
//                   // Subtitle text
//                   Text('입력한 비밀번호가 맞는지 확인할게요.', style: TextStyles.kThirdBody),
//                   const SizedBox(height: 60),
//                 ],

//                 // Input field label
//                 Text('비밀번호 확인', style: TextStyles.kHeader),
//                 const SizedBox(height: 8),
//                 // Password confirmation input field
//                 TextField(
//                   controller: _confirmPasswordController,
//                   obscureText: _obscureText,
//                   obscuringCharacter: '\u2B24',
//                   decoration: InputDecoration(
//                     hintText: '비밀번호를 다시 입력해주세요',
//                     hintStyle: TextStyles.kHint,
//                     errorText: _errorText,
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureText ? Icons.visibility : Icons.visibility_off,
//                         color: Colors.grey,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscureText = !_obscureText;
//                         });
//                       },
//                     ),
//                     border: UnderlineInputBorder(
//                       borderSide: BorderSide(
//                         color: Colors.grey[300]!,
//                         width: 1,
//                       ),
//                     ),
//                     enabledBorder: UnderlineInputBorder(
//                       borderSide: BorderSide(
//                         color: Colors.grey[300]!,
//                         width: 1,
//                       ),
//                     ),
//                     focusedBorder: const UnderlineInputBorder(
//                       borderSide: BorderSide(color: Colors.black, width: 2),
//                     ),
//                     errorBorder: const UnderlineInputBorder(
//                       borderSide: BorderSide(color: Colors.red, width: 1),
//                     ),
//                     focusedErrorBorder: const UnderlineInputBorder(
//                       borderSide: BorderSide(color: Colors.red, width: 2),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 0,
//                     ),
//                   ),
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.black,
//                     letterSpacing: 1.5,
//                   ),
//                   textInputAction: TextInputAction.done,
//                   onSubmitted: (_) {
//                     if (_isButtonEnabled && !_isCreatingAccount) {
//                       _handleCreateAccount();
//                     }
//                   },
//                 ),
//                 if (signUpProvider.errorMessage != null) ...[
//                   const SizedBox(height: 16),
//                   Text(
//                     signUpProvider.errorMessage!,
//                     style: const TextStyle(color: Colors.red, fontSize: 14),
//                   ),
//                 ],
//                 const Spacer(),
//                 // Create account button
//                 CustomButton(
//                   text: _isCreatingAccount ? '계정 생성 중...' : '확인',
//                   isEnabled: _isButtonEnabled && !_isCreatingAccount,
//                   onPressed:
//                       (_isButtonEnabled && !_isCreatingAccount)
//                           ? _handleCreateAccount
//                           : null,
//                   disabledBackgroundColor: Colors.grey,
//                 ),
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/providers/sign_up_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PasswordConfirmationScreen extends StatefulWidget {
  const PasswordConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<PasswordConfirmationScreen> createState() =>
      _PasswordConfirmationScreenState();
}

class _PasswordConfirmationScreenState
    extends State<PasswordConfirmationScreen> {
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
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    final originalPassword = signUpProvider.password;

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
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, child) {
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
                    child: Text(
                      _passwordMismatchError!,
                      style: TextStyles.kError,
                    ),
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
                if (signUpProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    signUpProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
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
      },
    );
  }
}
