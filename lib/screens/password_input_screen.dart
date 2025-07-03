import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:with_force/dialogs/confirmation_dialog.dart';
import 'package:with_force/providers/sign_up_provider.dart';
import 'package:with_force/styles/colors.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_app_bar.dart';
import 'package:with_force/widgets/reusable_button.dart';

class PasswordInputScreen extends StatefulWidget {
  const PasswordInputScreen({Key? key}) : super(key: key);

  @override
  State<PasswordInputScreen> createState() => _PasswordInputScreenState();
}

class _PasswordInputScreenState extends State<PasswordInputScreen> {
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
      final signUpProvider = Provider.of<SignUpProvider>(
        context,
        listen: false,
      );
      if (signUpProvider.password.isNotEmpty) {
        _passwordController.text = signUpProvider.password;
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
    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    signUpProvider.setPassword(password);

    // Navigate to password confirmation screen
    context.push('/password-re-enter');
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
                    hintStyle: TextStyles.kHint,
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
                    fontSize: 16, // Slightly smaller than 16px for smaller dots
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
                if (signUpProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(signUpProvider.errorMessage!, style: TextStyles.kError),
                ],
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
      },
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:with_force/dialogs/confirmation_dialog.dart';
// import 'package:with_force/providers/sign_up_provider.dart';
// import 'package:with_force/styles/colors.dart';
// import 'package:with_force/styles/text_styles.dart';
// import 'package:with_force/widgets/reusable_app_bar.dart';
// import 'package:with_force/widgets/reusable_button.dart';

// class PasswordInputScreen extends StatefulWidget {
//   const PasswordInputScreen({Key? key}) : super(key: key);

//   @override
//   State<PasswordInputScreen> createState() => _PasswordInputScreenState();
// }

// class _PasswordInputScreenState extends State<PasswordInputScreen> {
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isButtonEnabled = false;
//   bool _isCreatingAccount = false;
//   bool _obscureText = true;
//   String? _errorText;
//   String? _passwordError;

//   @override
//   void initState() {
//     super.initState();
//     _passwordController.addListener(_onPasswordChanged);

//     // Load existing password if user goes back
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final signUpProvider = Provider.of<SignUpProvider>(
//         context,
//         listen: false,
//       );
//       if (signUpProvider.password.isNotEmpty) {
//         _passwordController.text = signUpProvider.password;
//         _validatePassword(_passwordController.text);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _passwordController.removeListener(_onPasswordChanged);
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _onPasswordChanged() {
//     _validatePassword(_passwordController.text);
//     // Clear password error when user types
//     if (_passwordError != null) {
//       setState(() {
//         _passwordError = null;
//       });
//     }
//   }

//   void _validatePassword(String password) {
//     setState(() {
//       if (password.isEmpty) {
//         _isButtonEnabled = false;
//         _errorText = null;
//       } else if (password.length < 8) {
//         _isButtonEnabled = false;
//         _errorText = '비밀번호는 8자 이상이어야 합니다';
//       } else {
//         _isButtonEnabled = true;
//         _errorText = null;
//       }
//     });
//   }

//   Future<void> _handleCreateAccount() async {
//     if (!_isButtonEnabled || _isCreatingAccount) return;

//     final password = _passwordController.text.trim();
//     print('User entered password: $password');

//     // For testing - show password error
//     _showPasswordError();

//     // Comment out actual signup for testing
//     /*
//     setState(() {
//       _isCreatingAccount = true;
//     });

//     try {
//       final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
      
//       // Save password
//       signUpProvider.setPassword(password);
      
//       // Submit all data at once using your existing AuthService
//       final result = await signUpProvider.submitSignUp();
      
//       if (result['success']) {
//         // Check if account needs confirmation
//         if (result['requiresConfirmation'] == true) {
//           // Navigate to confirmation screen
//           Navigator.pushNamed(context, '/confirmation');
//         } else {
//           // Account created successfully, navigate to login or main app
//           Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
          
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('계정이 성공적으로 생성되었습니다. 로그인해주세요.'),
//               backgroundColor: Colors.green,
//             ),
//           );
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
//     */
//   }

//   void _showPasswordError() {
//     setState(() {
//       _passwordError = '비밀번호는 7자 이상, 영문과 숫자를 포함해 만들어야 합니다.';
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
//                 const Text(
//                   '안전한 비밀번호를',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   '만들어주세요',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 // Conditional content: Either error message OR subtitle text
//                 if (_passwordError != null) ...[
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
//                     child: Text(_passwordError!, style: TextStyles.kError),
//                   ),
//                   const SizedBox(height: 60),
//                 ] else ...[
//                   const SizedBox(height: 24),
//                   // Subtitle text
//                   const Text(
//                     '비밀번호는 7자 이상,',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w400,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   const Text(
//                     '영문과 숫자를 포함해 만들어주세요.',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w400,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 60),
//                 ],

//                 // Input field label
//                 Text('비밀번호', style: TextStyles.kHeader),
//                 const SizedBox(height: 8),
//                 // Password input field
//                 TextField(
//                   controller: _passwordController,
//                   obscureText: _obscureText,
//                   obscuringCharacter: '●', // Medium circle (smaller than ⚫)
//                   decoration: InputDecoration(
//                     hintText: '비밀번호를 입력해주세요',
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
//                     fontSize: 14, // Slightly smaller than 16px for smaller dots
//                     fontWeight: FontWeight.w400,
//                     color: Colors.black,
//                     letterSpacing: 1.5, // Adjust spacing between dots
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
//                   text: '다음',
//                   isEnabled: _isButtonEnabled,
//                   onPressed: _isButtonEnabled ? _handleCreateAccount : null,
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
