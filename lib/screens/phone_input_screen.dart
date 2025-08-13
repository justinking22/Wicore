import 'package:Wicore/dialogs/settings_confirmation_dialog.dart';
import 'package:Wicore/widgets/onboarding_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  _PhoneInputScreenState createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isButtonEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    setState(() {
      _isButtonEnabled = _phoneController.text.isNotEmpty;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _saveAndContinue() async {
    if (!_isButtonEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('전화번호를 입력해주세요')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final phoneNumber = _phoneController.text;

      // Save phone number
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(UserUpdateRequest(number: phoneNumber));

      print('📱 PhoneInput - Phone number saved successfully');

      // ✅ IMPORTANT: Set onboarded to true
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(UserUpdateRequest(onboarded: true));

      print('✅ PhoneInput - User marked as onboarded in API');

      // ✅ Also mark as completed locally
      final onboardingManager = ref.read(onboardingManagerProvider);
      await onboardingManager.markOnboardingCompleted();

      print('✅ PhoneInput - User marked as onboarded locally');

      // Refresh user provider to ensure onboarded status is updated
      await ref.read(userProvider.notifier).getCurrentUserProfile();

      print('🔄 PhoneInput - User profile refreshed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('온보딩이 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/prep-done');
      }
    } catch (e) {
      print('❌ PhoneInput - Error during save: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _skipAndContinue() async {
    try {
      print('⏭️ PhoneInput - User clicked skip button');

      // Show confirmation dialog first
      final shouldSkip = await SkipPersonalInfoDialog.show(context);

      if (shouldSkip == true && mounted) {
        print('⏭️ PhoneInput - User confirmed to skip phone input');

        // ✅ Even when skipping, mark as onboarded so they don't see it again today
        await ref
            .read(userProvider.notifier)
            .updateCurrentUserProfile(UserUpdateRequest(onboarded: true));

        print('⏭️ PhoneInput - User marked as onboarded (skipped)');

        // Mark as completed locally
        final onboardingManager = ref.read(onboardingManagerProvider);
        await onboardingManager.markOnboardingCompleted();

        // Refresh profile
        await ref.read(userProvider.notifier).getCurrentUserProfile();

        // Navigate to home screen
        context.go('/navigation');
      } else {
        print(
          '⏭️ PhoneInput - User chose to stay and continue with phone input',
        );
      }
    } catch (e) {
      print('❌ PhoneInput - Error during skip: $e');
      if (mounted) {
        // Even if there's an error, let them continue to home if they confirmed
        context.go('/navigation');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isApiLoading = userState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final availableHeight = screenHeight - keyboardHeight;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        // Prevent the body from resizing when keyboard appears
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Container(
            color: Colors.white,
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar - Fixed at top
                CustomAppBar(
                  title: '보호자 연락처',
                  showTrailingButton: true,
                  trailingButtonText: '건너뛰기',
                  showBackButton: false,
                  onTrailingPressed: _skipAndContinue,
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    // Add physics for better scrolling experience
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            availableHeight -
                            (MediaQuery.of(context).padding.top +
                                kToolbarHeight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Header section with better padding
                          Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    child: Text(
                                      '보호자의 전화번호를\n입력해주세요',
                                      style: TextStyles.kBody,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    child: Text(
                                      '비상연락이 필요한 경우\n작성해주신 연락처로 연락이 갈 예정이에요.',
                                      style: TextStyles.kMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Input section with flexible height
                          Container(
                            color: CustomColors.lighterGray,
                            constraints: BoxConstraints(
                              minHeight:
                                  isKeyboardVisible
                                      ? availableHeight -
                                          200 // Adjust based on header height
                                      : 400,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 30),

                                  Text(
                                    '보호자 연락처',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      fontFamily: TextStyles.kFontFamily,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Phone input field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      child: TextField(
                                        controller: _phoneController,
                                        focusNode: _phoneFocusNode,
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _dismissKeyboard(),
                                        decoration: InputDecoration(
                                          hintText: '예) 010-0000-0000',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: TextStyles.kFontFamily,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Flexible spacing that adapts to keyboard
                                  SizedBox(height: isKeyboardVisible ? 20 : 80),

                                  // Button section
                                  if (_isSaving || isApiLoading)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else
                                    CustomButton(
                                      text: '다음',
                                      isEnabled: _isButtonEnabled,
                                      onPressed:
                                          _isButtonEnabled
                                              ? _saveAndContinue
                                              : null,
                                      disabledBackgroundColor: Colors.grey,
                                    ),

                                  // Bottom padding to ensure button is always visible
                                  SizedBox(
                                    height:
                                        isKeyboardVisible
                                            ? keyboardHeight + 20
                                            : 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
