import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/models/auth_models.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/sign_up_form_state.dart';
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

  Future<void> _handleNext() async {
    if (!_isButtonEnabled || _isCheckingEmail) return;

    final email = _emailController.text.trim();
    print('User entered email: $email');

    setState(() {
      _isCheckingEmail = true;
      _emailExistsError = null;
    });

    try {
      // Use the new auth system to check if email exists
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Attempt a signup with temporary data to check if email exists
      final result = await authNotifier.signUp(
        email: email,
        password:
            'temp_password_for_check', // Temporary password just for checking
        name: 'temp_name', // Temporary name just for checking
      );

      if (!result.success) {
        // Check if the error is about email already existing
        if (result.message?.contains('already exists') == true ||
            result.message?.contains('이미 가입된') == true ||
            result.code == 'EMAIL_ALREADY_EXISTS') {
          // Adjust based on your API response
          _showEmailExistsError();
          return;
        }

        // If it's a different error, show it
        if (result.message != null) {
          setState(() {
            _emailExistsError = result.message;
          });
          return;
        }
      }

      // If we get here, either the signup succeeded (unlikely with temp data)
      // or the error wasn't about email existing, so proceed
      ref.read(signUpFormProvider.notifier).setEmail(email);

      if (mounted) {
        context.push('/password-input');
      }
    } catch (e) {
      print('Error checking email: $e');
      // On error, save email and proceed (you might want to handle this differently)
      ref.read(signUpFormProvider.notifier).setEmail(email);

      if (mounted) {
        context.push('/password-input');
      }

      // Optionally show a generic error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  // Alternative approach: Create a dedicated email check endpoint
  Future<void> _handleNextWithDedicatedEndpoint() async {
    if (!_isButtonEnabled || _isCheckingEmail) return;

    final email = _emailController.text.trim();
    print('User entered email: $email');

    setState(() {
      _isCheckingEmail = true;
      _emailExistsError = null;
    });

    try {
      // Use the authenticated API service to check email
      final apiService = ref.read(apiServiceProvider);

      // Make a GET request to check if email exists
      // You'll need to create this endpoint in your backend: GET /auth/check-email?email=...
      final response = await apiService.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['exists'] == true) {
          _showEmailExistsError();
          return;
        }

        // Email is available, proceed
        ref.read(signUpFormProvider.notifier).setEmail(email);

        if (mounted) {
          context.push('/password-input');
        }
      } else {
        // Handle error response
        setState(() {
          _emailExistsError = '이메일 확인 중 오류가 발생했습니다.';
        });
      }
    } catch (e) {
      print('Error checking email: $e');
      // On error, save email and proceed
      ref.read(signUpFormProvider.notifier).setEmail(email);

      if (mounted) {
        context.push('/password-input');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  void _showEmailExistsError() {
    setState(() {
      _emailExistsError = '이미 가입된 이메일입니다. 다른 이메일을 입력해주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for any changes
    final authState = ref.watch(authNotifierProvider);

    // Handle auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.needsConfirmation) {
        // If signup requires confirmation, navigate to confirmation screen
        context.push('/email-confirmation');
      } else if (next.isAuthenticated) {
        // If somehow authenticated, go to home
        context.go('/home');
      }
    });

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
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
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
                  _handleNext();
                }
              },
            ),
            const Spacer(),
            // Next button
            CustomButton(
              text: _isCheckingEmail ? '확인 중...' : '다음',
              isEnabled: _isButtonEnabled && !_isCheckingEmail,
              onPressed:
                  (_isButtonEnabled && !_isCheckingEmail) ? _handleNext : null,
              disabledBackgroundColor: Colors.grey,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
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

// class EmailInputScreen extends StatefulWidget {
//   const EmailInputScreen({Key? key}) : super(key: key);

//   @override
//   State<EmailInputScreen> createState() => _EmailInputScreenState();
// }

// class _EmailInputScreenState extends State<EmailInputScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   bool _isButtonEnabled = false;
//   String? _errorText;
//   String? _emailExistsError;

//   @override
//   void initState() {
//     super.initState();
//     _emailController.addListener(_onEmailChanged);

//     // Load existing email if user goes back
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final signUpProvider = Provider.of<SignUpProvider>(
//         context,
//         listen: false,
//       );
//       if (signUpProvider.email.isNotEmpty) {
//         _emailController.text = signUpProvider.email;
//         _validateEmail(_emailController.text);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _emailController.removeListener(_onEmailChanged);
//     _emailController.dispose();
//     super.dispose();
//   }

//   void _onEmailChanged() {
//     _validateEmail(_emailController.text);
//     // Clear email exists error when user types
//     if (_emailExistsError != null) {
//       setState(() {
//         _emailExistsError = null;
//       });
//     }
//   }

//   void _validateEmail(String email) {
//     setState(() {
//       if (email.trim().isEmpty) {
//         _isButtonEnabled = false;
//         _errorText = null;
//       } else if (!_isValidEmail(email.trim())) {
//         _isButtonEnabled = false;
//         _errorText = '올바른 이메일 형식을 입력해주세요';
//       } else {
//         _isButtonEnabled = true;
//         _errorText = null;
//       }
//     });
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }

//   void _handleNext() {
//     if (_isButtonEnabled) {
//       final email = _emailController.text.trim();
//       print('User entered email: $email');

//       // For testing - always show the error message when clicking next
//       _showEmailExistsError();

//       // Comment out navigation for now to test the error display
//       // Provider.of<SignUpProvider>(context, listen: false).setEmail(email);
//       // Navigator.pushNamed(context, '/password-input');
//     }
//   }

//   void _showEmailExistsError() {
//     setState(() {
//       _emailExistsError = '이미 가입된 이메일입니다. 다른 이메일을 입력해주세요.';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CustomAppBar(
//         title: '회원가입',
//         onBackPressed: () => Navigator.pop(context),
//         showTrailingButton: true,
//         onTrailingPressed: () {
//           ExitConfirmationDialogWithOptions.show(
//             context,
//             exitRoute: '/welcome',
//           );
//         },
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             // Title text
//             const Text(
//               '회원님이 사용중인',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               '이메일을 입력해주세요',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             // Conditional content: Either error message OR subtitle text
//             if (_emailExistsError != null) ...[
//               const SizedBox(height: 24),
//               Container(
//                 width: double.infinity,
//                 height: 80,
//                 padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
//                 decoration: BoxDecoration(
//                   color:
//                       CustomColors
//                           .translucentRedOrange, // Light pink background
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Text(_emailExistsError!, style: TextStyles.kError),
//               ),
//               const SizedBox(height: 60),
//             ] else ...[
//               const SizedBox(height: 24),
//               // Subtitle text
//               Text('인증번호가 발송될 예정이니', style: TextStyles.kSecondBody),
//               const SizedBox(height: 4),
//               Text('정확한 이메일 주소를 확인해주세요.', style: TextStyles.kSecondBody),
//               const SizedBox(height: 60),
//             ],

//             // Input field label
//             Text('이메일', style: TextStyles.kHeader),
//             const SizedBox(height: 8),
//             // Email input field
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(
//                 hintText: '예) withforce@naver.com',
//                 hintStyle: TextStyles.kHint,
//                 errorText: _errorText,
//                 border: UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
//                 ),
//                 enabledBorder: UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
//                 ),
//                 focusedBorder: const UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.black, width: 2),
//                 ),
//                 errorBorder: const UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.red, width: 1),
//                 ),
//                 focusedErrorBorder: const UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.red, width: 2),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   vertical: 12,
//                   horizontal: 0,
//                 ),
//               ),
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w400,
//                 color: Colors.black,
//               ),
//               keyboardType: TextInputType.emailAddress,
//               textInputAction: TextInputAction.done,
//               onSubmitted: (_) {
//                 if (_isButtonEnabled) {
//                   _handleNext();
//                 }
//               },
//             ),
//             const Spacer(),
//             // Next button
//             CustomButton(
//               text: '다음',
//               isEnabled: _isButtonEnabled,
//               onPressed: _isButtonEnabled ? _handleNext : null,
//               disabledBackgroundColor: Colors.grey,
//             ),
//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }
// }
