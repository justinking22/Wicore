// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:with_force/dialogs/confirmation_dialog.dart';
// import 'package:with_force/providers/sign_up_provider.dart';
// import 'package:with_force/styles/colors.dart';
// import 'package:with_force/styles/text_styles.dart';
// import 'package:with_force/widgets/reusable_app_bar.dart';
// import 'package:with_force/widgets/reusable_button.dart';

// class EmailVerificationScreen extends StatefulWidget {
//   const EmailVerificationScreen({Key? key}) : super(key: key);

//   @override
//   State<EmailVerificationScreen> createState() =>
//       _EmailVerificationScreenState();
// }

// class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
//   bool _isResending = false;

//   Future<void> _handleNext() async {
//     // Navigate to email verification code input screen
//     Navigator.pushNamed(context, '/verification-code');
//   }

//   Future<void> _handleResendEmail() async {
//     setState(() {
//       _isResending = true;
//     });

//     try {
//       final signUpProvider = Provider.of<SignUpProvider>(
//         context,
//         listen: false,
//       );
//       // You can add resend email logic here if your AuthService has that method

//       // Simulate resend process
//       await Future.delayed(Duration(seconds: 2));

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('인증번호가 다시 전송되었습니다.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('인증번호 재전송에 실패했습니다. 다시 시도해주세요.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isResending = false;
//       });
//     }
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
//                 Text('아래의 이메일 주소로', style: TextStyles.kBody),

//                 Text('인증번호를 보냈어요', style: TextStyles.kBody),
//                 const SizedBox(height: 20),

//                 // Email display container
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
//                   decoration: BoxDecoration(
//                     color:
//                         CustomColors
//                             .translucentLightGray, // Light grey background
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     signUpProvider.email.isNotEmpty
//                         ? signUpProvider.email
//                         : 'user@email.com',
//                     style: TextStyles.kThirdBody,
//                   ),
//                 ),

//                 const Spacer(),

//                 // Next button
//                 CustomButton(
//                   text: '다음',
//                   isEnabled: true,
//                   onPressed: _handleNext,
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:with_force/dialogs/confirmation_dialog.dart';
import 'package:with_force/providers/sign_up_provider.dart';
import 'package:with_force/styles/colors.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_app_bar.dart';
import 'package:with_force/widgets/reusable_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isResending = false;
  bool _showVerificationCode = false;
  bool _isVerifying = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _codeController = TextEditingController();
  bool _isCodeComplete = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final code = _codeController.text;
    setState(() {
      _isCodeComplete = code.length == 6;
    });
  }

  Future<void> _handleNext() async {
    setState(() {
      _showVerificationCode = true;
    });
    _animationController.forward();
  }

  Future<void> _handleResendEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final signUpProvider = Provider.of<SignUpProvider>(
        context,
        listen: false,
      );
      // You can add resend email logic here if your AuthService has that method

      // Simulate resend process
      await Future.delayed(Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호가 다시 전송되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호 재전송에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_isCodeComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final code = _codeController.text;
      print('Verifying code: $code');

      // Simulate verification process
      await Future.delayed(Duration(seconds: 2));

      context.push('/success-verification');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 인증이 완료되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호가 올바르지 않습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Widget _buildEmailSentView() {
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // Title text
            const Text(
              '아래의 이메일 주소로',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '인증번호를 보냈어요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),

            // Email display container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // Light grey background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                signUpProvider.email.isNotEmpty
                    ? signUpProvider.email
                    : 'user@email.com',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 24),

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
        );
      },
    );
  }

  Widget _buildVerificationCodeView() {
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // Title text
            Text('이메일로 받은', style: TextStyles.kBody),
            Text('인증번호를 입력해주세요', style: TextStyles.kBody),
            const SizedBox(height: 20),

            // Email display container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // Light grey background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                signUpProvider.email.isNotEmpty
                    ? signUpProvider.email
                    : 'user@email.com',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Input field label
            Text('인증번호', style: TextStyles.kHeader),
            const SizedBox(height: 8),

            // Verification code input field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: '이메일을 열어보시고, 숫자를 입력해주세요.',
                hintStyle: TextStyles.kHint,
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
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_isCodeComplete && !_isVerifying) {
                  _handleVerifyCode();
                }
              },
            ),

            const SizedBox(height: 24),

            // Resend code option
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _isResending ? null : _handleResendEmail,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 2),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: CustomColors.darkGray,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      _isResending ? '전송 중...' : '인증번호가 도착하지 않았어요',
                      style: TextStyles.kTrailingBottomButton,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Verify button
            CustomButton(
              text: _isVerifying ? '인증 중...' : '확인',
              isEnabled: _isCodeComplete && !_isVerifying,
              onPressed:
                  (_isCodeComplete && !_isVerifying) ? _handleVerifyCode : null,
              disabledBackgroundColor: Colors.grey,
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '회원가입',
        onBackPressed: () {
          if (_showVerificationCode) {
            // If showing verification code, go back to email sent view
            setState(() {
              _showVerificationCode = false;
            });
            _animationController.reverse();
          } else {
            Navigator.pop(context);
          }
        },
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
        child: Stack(
          children: [
            // Email sent view (always present)
            if (!_showVerificationCode) _buildEmailSentView(),

            // Verification code view (slides in from right)
            if (_showVerificationCode)
              SlideTransition(
                position: _slideAnimation,
                child: _buildVerificationCodeView(),
              ),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:with_force/dialogs/confirmation_dialog.dart';
// import 'package:with_force/providers/sign_up_provider.dart';
// import 'package:with_force/styles/colors.dart';
// import 'package:with_force/styles/text_styles.dart';
// import 'package:with_force/widgets/reusable_app_bar.dart';
// import 'package:with_force/widgets/reusable_button.dart';

// class EmailVerificationScreen extends StatefulWidget {
//   const EmailVerificationScreen({Key? key}) : super(key: key);

//   @override
//   State<EmailVerificationScreen> createState() =>
//       _EmailVerificationScreenState();
// }

// class _EmailVerificationScreenState extends State<EmailVerificationScreen>
//     with SingleTickerProviderStateMixin {
//   bool _isResending = false;
//   bool _showVerificationCode = false;
//   bool _isVerifying = false;

//   late AnimationController _animationController;
//   late Animation<Offset> _slideAnimation;

//   final TextEditingController _codeController = TextEditingController();
//   bool _isCodeComplete = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(1.0, 0.0), // Start from right
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _codeController.addListener(_onCodeChanged);
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _codeController.removeListener(_onCodeChanged);
//     _codeController.dispose();
//     super.dispose();
//   }

//   void _onCodeChanged() {
//     final code = _codeController.text;
//     setState(() {
//       _isCodeComplete = code.length == 6;
//     });
//   }

//   Future<void> _handleNext() async {
//     setState(() {
//       _showVerificationCode = true;
//     });
//     _animationController.forward();
//   }

//   Future<void> _handleResendEmail() async {
//     setState(() {
//       _isResending = true;
//     });

//     try {
//       final signUpProvider = Provider.of<SignUpProvider>(
//         context,
//         listen: false,
//       );
//       // You can add resend email logic here if your AuthService has that method

//       // Simulate resend process
//       await Future.delayed(Duration(seconds: 2));

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('인증번호가 다시 전송되었습니다.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('인증번호 재전송에 실패했습니다. 다시 시도해주세요.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isResending = false;
//       });
//     }
//   }

//   Future<void> _handleVerifyCode() async {
//     if (!_isCodeComplete || _isVerifying) return;

//     setState(() {
//       _isVerifying = true;
//     });

//     try {
//       final code = _codeController.text;
//       print('Verifying code: $code');

//       // Simulate verification process
//       await Future.delayed(Duration(seconds: 2));

//       context.push('/success-verification');

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('이메일 인증이 완료되었습니다!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('인증번호가 올바르지 않습니다. 다시 시도해주세요.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isVerifying = false;
//       });
//     }
//   }

//   Widget _buildEmailSentView() {
//     return Consumer<SignUpProvider>(
//       builder: (context, signUpProvider, child) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             // Title text
//             const Text(
//               '아래의 이메일 주소로',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               '인증번호를 보냈어요',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 40),

//             // Email display container
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF5F5F5), // Light grey background
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 signUpProvider.email.isNotEmpty
//                     ? signUpProvider.email
//                     : 'user@email.com',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.black54,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Resend email option
//             Row(
//               children: [
//                 const Text(
//                   '이메일을 받지 못하셨나요? ',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: _isResending ? null : _handleResendEmail,
//                   child: Text(
//                     _isResending ? '전송 중...' : '다시 보내기',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: _isResending ? Colors.grey : Colors.blue,
//                       decoration: TextDecoration.underline,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const Spacer(),

//             // Next button
//             CustomButton(
//               text: '다음',
//               isEnabled: true,
//               onPressed: _handleNext,
//               disabledBackgroundColor: Colors.grey,
//             ),
//             const SizedBox(height: 32),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildVerificationCodeView() {
//     return Consumer<SignUpProvider>(
//       builder: (context, signUpProvider, child) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             // Title text
//             const Text(
//               '이메일로 받은',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               '인증번호를 입력해주세요',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 40),

//             // Email display container
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF5F5F5), // Light grey background
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 signUpProvider.email.isNotEmpty
//                     ? signUpProvider.email
//                     : 'user@email.com',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.black54,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 60),

//             // Input field label
//             Text('인증번호', style: TextStyles.kHeader),
//             const SizedBox(height: 8),

//             // Verification code input field
//             TextField(
//               controller: _codeController,
//               decoration: InputDecoration(
//                 hintText: '이메일을 열어보시고, 숫자를 입력해주세요.',
//                 hintStyle: TextStyles.kHint,
//                 border: UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
//                 ),
//                 enabledBorder: UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
//                 ),
//                 focusedBorder: const UnderlineInputBorder(
//                   borderSide: BorderSide(color: Colors.black, width: 2),
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
//               keyboardType: TextInputType.number,
//               maxLength: 6,
//               inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//               textInputAction: TextInputAction.done,
//               onSubmitted: (_) {
//                 if (_isCodeComplete) {
//                   _handleVerifyCode();
//                 }
//               },
//             ),

//             const SizedBox(height: 24),

//             // Resend code option
//             Center(
//               child: GestureDetector(
//                 onTap: _isResending ? null : _handleResendEmail,
//                 child: Container(
//                   padding: const EdgeInsets.only(bottom: 2),
//                   decoration: const BoxDecoration(
//                     border: Border(
//                       bottom: BorderSide(color: Colors.blue, width: 1),
//                     ),
//                   ),
//                   child: Text(
//                     _isResending ? '전송 중...' : '인증번호가 도착하지 않았어요',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: _isResending ? Colors.grey : Colors.blue,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             const Spacer(),

//             // Verify button
//             CustomButton(
//               text: _isVerifying ? '인증 중...' : '확인',
//               isEnabled: _isCodeComplete && !_isVerifying,
//               onPressed:
//                   (_isCodeComplete && !_isVerifying) ? _handleVerifyCode : null,
//               disabledBackgroundColor: Colors.grey,
//             ),
//             const SizedBox(height: 32),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CustomAppBar(
//         title: '회원가입',
//         onBackPressed: () {
//           if (_showVerificationCode) {
//             // If showing verification code, go back to email sent view
//             setState(() {
//               _showVerificationCode = false;
//             });
//             _animationController.reverse();
//           } else {
//             Navigator.pop(context);
//           }
//         },
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
//         child: Stack(
//           children: [
//             // Email sent view (always present)
//             if (!_showVerificationCode) _buildEmailSentView(),

//             // Verification code view (slides in from right)
//             if (_showVerificationCode)
//               SlideTransition(
//                 position: _slideAnimation,
//                 child: _buildVerificationCodeView(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
