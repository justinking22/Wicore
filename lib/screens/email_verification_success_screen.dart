import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wicore/providers/authentication_provider.dart';

class EmailVerificationSuccessScreen extends ConsumerStatefulWidget {
  const EmailVerificationSuccessScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailVerificationSuccessScreen> createState() =>
      _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState
    extends ConsumerState<EmailVerificationSuccessScreen> {
  @override
  void initState() {
    super.initState();

    // Listen for auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);

      // If user is already authenticated after verification, navigate accordingly
      if (authState.isAuthenticated) {
        // User is fully registered and authenticated, go to main app
        context.go('/navigation');
      }
    });
  }

  void _handleNext() {
    final authState = ref.read(authNotifierProvider);

    if (authState.isAuthenticated) {
      // User is authenticated, go to main app
      context.go('/navigation');
    } else {
      // Continue with signup flow (terms and conditions, etc.)
      context.push('/terms-and-conditions');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated) {
        // If user becomes authenticated, navigate to main app
        context.go('/navigation');
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

            // Celebration emoji and icon
            Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title text
            Text('이메일 인증 성공!', style: TextStyles.kBody),
            const SizedBox(height: 8),
            Text('이제 마지막 단계예요', style: TextStyles.kBody),

            const SizedBox(height: 24),

            // Success message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '인증 완료!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '이메일 인증이 성공적으로 완료되었습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),

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
        ),
      ),
    );
  }
}
