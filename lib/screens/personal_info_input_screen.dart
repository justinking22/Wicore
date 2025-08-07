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
    _checkOnboardingStatus(); // Add this for debugging
  }

  // ✅ Add this method to check onboarding status for debugging
  void _checkOnboardingStatus() async {
    final userState = ref.read(userProvider);
    final onboardingManager = ref.read(onboardingManagerProvider);

    final apiOnboarded = userState.maybeWhen(
      data: (response) => response?.data?.onboarded ?? false,
      orElse: () => false,
    );

    final localOnboarded =
        await onboardingManager.hasCompletedOnboardingLocally();
    final daysSincePrompt = await onboardingManager.daysSinceLastPrompt();

    print('🔍 PersonalInfo - API onboarded: $apiOnboarded');
    print('🔍 PersonalInfo - Local onboarded: $localOnboarded');
    print('🔍 PersonalInfo - Days since last prompt: $daysSincePrompt');
  }

  // ✅ Updated skip function with proper onboarding logic
  void _skipAndContinue() async {
    try {
      print('⏭️ PersonalInfo - User chose to skip personal info');

      // Mark that we've shown the onboarding today (so they don't see it again today)
      final onboardingManager = ref.read(onboardingManagerProvider);
      await onboardingManager.markOnboardingPromptShown();

      print('📅 PersonalInfo - Marked onboarding as shown today');

      if (mounted) {
        context.push('/phone-input');
      }
    } catch (e) {
      print('❌ PersonalInfo - Error during skip: $e');
      if (mounted) {
        // Even if there's an error, let them continue
        context.push('/phone-input');
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
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: '신체정보',
              showTrailingButton: true,
              trailingButtonText: '건너뛰기',
              showBackButton: false,
              onTrailingPressed: _skipAndContinue,
            ),
            const SizedBox(height: 20),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: Text(
                        '정보를 입력주시면\n더 잘 도울 수 있어요',
                        style: TextStyles.kBody,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: Text(
                        '성별, 키, 몸무게 등을 입력주시면\n로봇이 더 잘 도울 수 있어요.',
                        style: TextStyles.kMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Divider(
                                height: 1,
                                color: Colors.grey[300],
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Divider(
                                height: 1,
                                color: Colors.grey[300],
                              ),
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
                      const Spacer(),
                      if (_isSaving || isApiLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        )
                      else
                        CustomButton(
                          text: '다음',
                          isEnabled: _isFormComplete,
                          onPressed: _isFormComplete ? _saveAndContinue : null,
                          disabledBackgroundColor: Colors.grey,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

      // Update gender first
      final genderValue = _convertGenderToEnglish(selectedGender!);
      print('🔄 PersonalInfo - Updating gender: $genderValue');
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(UserUpdateRequest(gender: genderValue));

      // Update height
      final heightValue = double.tryParse(
        '$selectedMainHeight.$selectedDecimalHeight',
      );
      if (heightValue != null) {
        print('🔄 PersonalInfo - Updating height: $heightValue');
        await ref
            .read(userProvider.notifier)
            .updateCurrentUserProfile(UserUpdateRequest(height: heightValue));
      }

      // Update weight
      final weightValue = double.tryParse(
        '$selectedMainWeight.$selectedDecimalWeight',
      );
      if (weightValue != null) {
        print('🔄 PersonalInfo - Updating weight: $weightValue');
        await ref
            .read(userProvider.notifier)
            .updateCurrentUserProfile(UserUpdateRequest(weight: weightValue));
      }

      print('✅ PersonalInfo - All data saved successfully');

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

  // Update individual save methods with better error handling
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
          onItemSelected: (String selected) async {
            if (mounted) {
              setState(() => selectedGender = selected);
            }

            try {
              final gender = _convertGenderToEnglish(selected);
              if (gender.isNotEmpty) {
                print('🔄 PersonalInfo - Updating gender from picker: $gender');
                await ref
                    .read(userProvider.notifier)
                    .updateCurrentUserProfile(
                      UserUpdateRequest(gender: gender),
                    );
                print('✅ PersonalInfo - Gender updated from picker');
              }
            } catch (e) {
              print('❌ PersonalInfo - Error updating gender from picker: $e');
              // Don't show error snackbar for individual field updates
              // as they're not critical and might confuse the user
            }
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
          onItemSelected: (String main, String decimal) async {
            if (mounted) {
              setState(() {
                selectedMainHeight = main;
                selectedDecimalHeight = decimal;
              });
            }

            try {
              final height = double.tryParse('$main.$decimal');
              if (height != null) {
                print('🔄 PersonalInfo - Updating height from picker: $height');
                await ref
                    .read(userProvider.notifier)
                    .updateCurrentUserProfile(
                      UserUpdateRequest(height: height),
                    );
                print('✅ PersonalInfo - Height updated from picker');
              }
            } catch (e) {
              print('❌ PersonalInfo - Error updating height from picker: $e');
            }
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
          onItemSelected: (String main, String decimal) async {
            if (mounted) {
              setState(() {
                selectedMainWeight = main;
                selectedDecimalWeight = decimal;
              });
            }
            try {
              final weight = double.tryParse('$main.$decimal');
              if (weight != null) {
                print('🔄 PersonalInfo - Updating weight from picker: $weight');
                await ref
                    .read(userProvider.notifier)
                    .updateCurrentUserProfile(
                      UserUpdateRequest(weight: weight),
                    );
                print('✅ PersonalInfo - Weight updated from picker');
              }
            } catch (e) {
              print('❌ PersonalInfo - Error updating weight from picker: $e');
            }
          },
        );
      },
    );
  }
}
