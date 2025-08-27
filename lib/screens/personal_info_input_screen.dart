import 'package:Wicore/dialogs/settings_confirmation_dialog.dart';
import 'package:Wicore/widgets/onboarding_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';

import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/dual_picker.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:Wicore/widgets/reusable_info_field.dart';
import 'package:Wicore/widgets/reusable_picker.dart';

class PersonalInfoInputScreen extends ConsumerStatefulWidget {
  const PersonalInfoInputScreen({super.key});

  @override
  _PersonalInfoInputScreenState createState() =>
      _PersonalInfoInputScreenState();
}

class _PersonalInfoInputScreenState
    extends ConsumerState<PersonalInfoInputScreen> {
  String? selectedGender;
  String? selectedMainHeight;
  String? selectedDecimalHeight;
  String? selectedMainWeight;
  String? selectedDecimalWeight;
  bool _isSaving = false;

  final List<String> genders = ['남성', '여성'];
  final List<String> mainHeights = List.generate(
    219,
    (index) => (54 + index).toString(),
  );
  final List<String> decimalHeights = List.generate(
    10,
    (index) => index.toString(),
  );
  final List<String> mainWeights = List.generate(
    634,
    (index) => (2 + index).toString(),
  );
  final List<String> decimalWeights = List.generate(
    10,
    (index) => index.toString(),
  );

  @override
  void initState() {
    super.initState();
    _initializeOnboardingStatus();
  }

  // ✅ SIMPLIFIED: Check API status without daily limits
  void _initializeOnboardingStatus() async {
    final userState = ref.read(userProvider);
    final onboardingManager = ref.read(onboardingManagerProvider);

    // 🔧 IMPORTANT: Treat null as false for onboarding status
    final apiOnboarded = userState.maybeWhen(
      data:
          (response) =>
              response?.data?.onboarded ?? false, // null becomes false
      orElse: () => false, // Any other state becomes false
    );

    final shouldShow = await onboardingManager.shouldShowOnboarding(
      isUserOnboarded: apiOnboarded,
    );

    print('🔍 PersonalInfo - API onboarded (null=false): $apiOnboarded');
    print(
      '🔍 PersonalInfo - Raw onboarded value: ${userState.maybeWhen(data: (response) => response?.data?.onboarded, orElse: () => 'not_loaded')}',
    );
    print('🔍 PersonalInfo - Should show onboarding: $shouldShow');

    // 🔧 SIMPLIFIED: If user is onboarded according to API, redirect to main app
    if (!shouldShow && apiOnboarded) {
      print(
        '🔄 PersonalInfo - User already onboarded, redirecting to main app',
      );
      if (mounted) {
        context.go('/navigation');
      }
    } else {
      print(
        '🔄 PersonalInfo - User not onboarded, staying on onboarding screen',
      );
      // Stay on current screen - this is correct behavior
    }
  }

  // ✅ FIXED: Skip method that properly marks as onboarded when skipping
  void _skipAndContinue() async {
    try {
      print('⏭️ PersonalInfo - User clicked skip button');

      // Show confirmation dialog first
      final shouldSkip = await SkipPersonalInfoDialog.show(context);

      if (shouldSkip == true && mounted) {
        print('⏭️ PersonalInfo - User confirmed to skip personal info');

        // 🔧 FIXED: Mark as onboarded in API when skipping so they don't see onboarding again
        try {
          await ref
              .read(userProvider.notifier)
              .updateCurrentUserProfile(UserUpdateRequest(onboarded: true));
          print('✅ PersonalInfo - User marked as onboarded in API (skipped)');
        } catch (e) {
          print('⚠️ PersonalInfo - Failed to update API but continuing: $e');
          // Don't block navigation if API fails
        }

        // Mark as completed locally (for compatibility)
        final onboardingManager = ref.read(onboardingManagerProvider);
        await onboardingManager.markOnboardingCompleted();
        print('✅ PersonalInfo - User marked as onboarded locally (skipped)');

        // Refresh profile to update the router
        try {
          await ref.read(userProvider.notifier).getCurrentUserProfile();
          print('🔄 PersonalInfo - User profile refreshed');
        } catch (e) {
          print(
            '⚠️ PersonalInfo - Failed to refresh profile but continuing: $e',
          );
        }

        // Navigate to main navigation
        print('🔄 PersonalInfo - Navigating to main navigation');
        context.go('/navigation');
      } else {
        print(
          '⏭️ PersonalInfo - User chose to stay and continue with personal info',
        );
      }
    } catch (e) {
      print('❌ PersonalInfo - Error during skip: $e');
      if (mounted) {
        // Even if there's an error, let them continue to home if they confirmed
        context.go('/navigation');
      }
    }
  }

  String _convertGenderToKorean(String englishGender) {
    return englishGender.toLowerCase() == 'male' ? '남성' : '여성';
  }

  String _convertGenderToEnglish(String koreanGender) {
    return koreanGender == '남성' ? 'male' : 'female';
  }

  bool get _isFormComplete {
    return selectedGender != null &&
        selectedMainHeight != null &&
        selectedDecimalHeight != null &&
        selectedMainWeight != null &&
        selectedDecimalWeight != null;
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isApiLoading = userState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomAppBar(
            title: '신체정보',
            showTrailingButton: false,
            trailingButtonText: '건너뛰기',
            showBackButton: false,
            onTrailingPressed: _skipAndContinue,
          ),

          // Header section - Fixed height
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    '정보를 입력주시면\n더 잘 도울 수 있어요',
                    style: TextStyles.kBody,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    '성별, 키, 몸무게 등을 입력주시면\n로봇이 더 잘 도울 수 있어요.',
                    style: TextStyles.kMedium,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Input section - Expanded to fill remaining space
          Expanded(
            child: Container(
              width: double.infinity,
              color: CustomColors.lighterGray,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
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
                      child: Column(
                        children: [
                          InfoField(
                            hasUnit: false,
                            label: '성별',
                            value: selectedGender ?? '입력하기',
                            isPlaceholder: selectedGender == null,
                            onTap: () => _showGenderPicker(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(height: 1, color: Colors.grey[300]),
                          ),
                          InfoField(
                            hasUnit: true,
                            label: '키',
                            value:
                                (selectedMainHeight != null &&
                                        selectedDecimalHeight != null)
                                    ? '$selectedMainHeight.$selectedDecimalHeight cm'
                                    : '입력하기',
                            isPlaceholder:
                                selectedMainHeight == null ||
                                selectedDecimalHeight == null,
                            onTap: () => _showHeightPicker(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(height: 1, color: Colors.grey[300]),
                          ),
                          InfoField(
                            hasUnit: true,
                            label: '체중',
                            value:
                                (selectedMainWeight != null &&
                                        selectedDecimalWeight != null)
                                    ? '$selectedMainWeight.$selectedDecimalWeight kg'
                                    : '입력하기',
                            isPlaceholder:
                                selectedMainWeight == null ||
                                selectedDecimalWeight == null,
                            onTap: () => _showWeightPicker(),
                          ),
                        ],
                      ),
                    ),

                    // Spacer to push button to bottom
                    const Spacer(),

                    // Button section - Always at bottom
                    if (_isSaving || isApiLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      CustomButton(
                        text: '다음',
                        isEnabled: _isFormComplete,
                        onPressed: _isFormComplete ? _saveAndContinue : null,
                        disabledBackgroundColor: Colors.grey,
                      ),

                    // Bottom padding for safe area
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Improved save function with proper onboarding completion tracking
  void _saveAndContinue() async {
    if (!_isFormComplete) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 정보를 입력해주세요')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      print('🔄 PersonalInfo - Starting to save user data');

      // Validate all values before parsing
      if (selectedMainHeight == null ||
          selectedDecimalHeight == null ||
          selectedMainWeight == null ||
          selectedDecimalWeight == null ||
          selectedGender == null) {
        throw Exception('Required values are missing');
      }

      // Create a single update request with all data
      final heightValue = double.tryParse(
        '$selectedMainHeight.$selectedDecimalHeight',
      );
      final weightValue = double.tryParse(
        '$selectedMainWeight.$selectedDecimalWeight',
      );
      final genderValue = _convertGenderToEnglish(selectedGender!);

      if (heightValue == null || weightValue == null) {
        throw Exception('Invalid height or weight values');
      }

      print('🔄 PersonalInfo - Updating all personal info at once');
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(
            UserUpdateRequest(
              gender: genderValue,
              height: heightValue,
              weight: weightValue,
            ),
          );

      print('✅ PersonalInfo - All personal info saved successfully');

      // ✅ Mark this step as completed in onboarding flow
      final onboardingManager = ref.read(onboardingManagerProvider);
      await onboardingManager.markPersonalInfoCompleted();
      print('✅ PersonalInfo - Marked personal info step as completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정보가 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/phone-input');
      }
    } catch (e) {
      print('❌ PersonalInfo - Error saving data: $e');
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

  // ✅ Simplified picker methods - remove individual API calls to avoid conflicts
  void _showGenderPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ReusablePicker(
          title: '성별',
          items: genders,
          selectedItem: selectedGender ?? genders[0],
          showDot: false,
          showIndex: false,
          onItemSelected: (String selected) {
            if (mounted) {
              setState(() => selectedGender = selected);
            }
            print('🔄 PersonalInfo - Gender selected: $selected');
          },
        );
      },
    );
  }

  void _showHeightPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DualPicker(
          title: '키 (cm)',
          mainItems: mainHeights,
          decimalItems: decimalHeights,
          selectedMainItem: selectedMainHeight ?? mainHeights[116],
          selectedDecimalItem: selectedDecimalHeight ?? decimalHeights[0],
          onItemSelected: (String main, String decimal) {
            if (mounted) {
              setState(() {
                selectedMainHeight = main;
                selectedDecimalHeight = decimal;
              });
            }
            print('🔄 PersonalInfo - Height selected: $main.$decimal cm');
          },
        );
      },
    );
  }

  void _showWeightPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DualPicker(
          title: '체중 (kg)',
          mainItems: mainWeights,
          decimalItems: decimalWeights,
          selectedMainItem: selectedMainWeight ?? mainWeights[67],
          selectedDecimalItem: selectedDecimalWeight ?? decimalWeights[0],
          onItemSelected: (String main, String decimal) {
            if (mounted) {
              setState(() {
                selectedMainWeight = main;
                selectedDecimalWeight = decimal;
              });
            }
            print('🔄 PersonalInfo - Weight selected: $main.$decimal kg');
          },
        );
      },
    );
  }
}
