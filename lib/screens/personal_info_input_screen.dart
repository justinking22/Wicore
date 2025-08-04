import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/dual_picker.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:Wicore/widgets/reusable_info_field.dart';
import 'package:Wicore/widgets/reusable_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wicore/models/user_request_model.dart';

class PersonalInfoInputScreen extends ConsumerStatefulWidget {
  @override
  _PersonalInfoInputScreenState createState() =>
      _PersonalInfoInputScreenState();
}

class _PersonalInfoInputScreenState
    extends ConsumerState<PersonalInfoInputScreen> {
  String? selectedGender; // Changed: nullable, starts null
  String? selectedMainHeight; // Changed: nullable, starts null
  String? selectedDecimalHeight; // Changed: nullable, starts null
  String? selectedMainWeight; // Changed: nullable, starts null
  String? selectedDecimalWeight; // Changed: nullable, starts null

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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load existing user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingUserData();
    });
  }

  // Load existing user data to pre-populate fields
  void _loadExistingUserData() async {
    try {
      await ref.read(userProvider.notifier).getCurrentUserProfile();
      final userState = ref.read(userProvider);

      userState.whenOrNull(
        data: (response) {
          if (response?.data != null) {
            final userData = response!.data;
            setState(() {
              // Convert API gender to Korean
              selectedGender = _convertGenderToKorean(userData.gender);

              // Parse height (e.g., 1720 -> "172" and "0")
              final heightStr = userData.height.toString();
              if (heightStr.length >= 3) {
                selectedMainHeight = heightStr.substring(
                  0,
                  heightStr.length - 1,
                );
                selectedDecimalHeight = heightStr.substring(
                  heightStr.length - 1,
                );
              }

              // Parse weight (e.g., 690 -> "69" and "0")
              final weightStr = userData.weight.toString();
              if (weightStr.length >= 2) {
                selectedMainWeight = weightStr.substring(
                  0,
                  weightStr.length - 1,
                );
                selectedDecimalWeight = weightStr.substring(
                  weightStr.length - 1,
                );
              }
            });
          }
        },
      );
    } catch (e) {
      print('Error loading existing user data: $e');
      // Continue with empty form - this is fine for input screen
    }
  }

  // Save personal info and proceed to next step
  void _saveAndContinue() async {
    if (selectedGender == null ||
        selectedMainHeight == null ||
        selectedDecimalHeight == null ||
        selectedMainWeight == null ||
        selectedDecimalWeight == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('모든 정보를 입력해주세요')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get current user data to preserve other fields
      final currentUserData = ref.read(currentUserDataProvider);

      if (currentUserData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      // Convert UI values to API format
      final heightValue = int.parse(
        '$selectedMainHeight$selectedDecimalHeight',
      );
      final weightValue = int.parse(
        '$selectedMainWeight$selectedDecimalWeight',
      );

      // Create updated user data
      final userRequest = UserRequest(
        item: UserItem(
          id: currentUserData.id,
          firstName: currentUserData.firstName,
          lastName: currentUserData.lastName,
          email: currentUserData.email,
          birthdate: currentUserData.birthdate,
          weight: weightValue,
          height: heightValue,
          gender: _convertGenderToEnglish(selectedGender!),
          onboarded:
              true, // Mark as onboarded since they completed personal info
        ),
      );

      await ref.read(userProvider.notifier).createUser(userRequest);

      final userState = ref.read(userProvider);
      await userState.when(
        data: (response) async {
          if (response != null) {
            // Success - navigate to next screen
            context.push('/phone-input');
          }
        },
        loading: () async {
          // Wait a bit more for loading to complete
          await Future.delayed(Duration(milliseconds: 500));
        },
        error: (error, stack) async {
          throw error;
        },
      );
    } catch (e) {
      print('Error saving personal info: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Skip personal info and proceed to next step
  void _skipAndContinue() async {
    // Just proceed to next screen without saving
    context.push('/phone-input');
  }

  // Helper methods to convert between Korean and English gender values
  String _convertGenderToKorean(String englishGender) {
    switch (englishGender.toLowerCase()) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      default:
        return '여성'; // Default fallback
    }
  }

  String _convertGenderToEnglish(String koreanGender) {
    switch (koreanGender) {
      case '남성':
        return 'male';
      case '여성':
        return 'female';
      default:
        return 'female'; // Default fallback
    }
  }

  // Check if form is complete
  bool get _isFormComplete {
    return selectedGender != null &&
        selectedMainHeight != null &&
        selectedDecimalHeight != null &&
        selectedMainWeight != null &&
        selectedDecimalWeight != null;
  }

  @override
  Widget build(BuildContext context) {
    // Watch for loading state from user provider
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
            SizedBox(height: 20),

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
                  SizedBox(height: 8),
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

            SizedBox(height: 40),

            // Form Container with Grey Background
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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Gender Field
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

                            // Height Field - Fixed display
                            InfoField(
                              hasUnit: true,
                              label: '키',
                              value:
                                  (selectedMainHeight != null &&
                                          selectedDecimalHeight != null)
                                      ? '${selectedMainHeight}.${selectedDecimalHeight}cm'
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

                            // Weight Field - Fixed display
                            InfoField(
                              hasUnit: true,
                              label: '체중',
                              value:
                                  (selectedMainWeight != null &&
                                          selectedDecimalWeight != null)
                                      ? '${selectedMainWeight}.${selectedDecimalWeight}kg'
                                      : '입력하기',
                              isPlaceholder:
                                  selectedMainWeight == null ||
                                  selectedDecimalWeight == null,
                              onTap: () => _showWeightPicker(),
                            ),
                          ],
                        ),
                      ),

                      Spacer(),

                      // Show loading indicator or button based on state
                      if (_isSaving || isApiLoading)
                        Container(
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

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ReusablePicker(
          title: '성별',
          items: genders,
          selectedItem:
              selectedGender ?? genders[0], // Default to first item if null
          showDot: false,
          showIndex: false,
          onItemSelected: (String selected) {
            setState(() {
              selectedGender = selected;
            });
          },
        );
      },
    );
  }

  void _showHeightPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DualPicker(
          title: '키 (cm)',
          mainItems: mainHeights,
          decimalItems: decimalHeights,
          selectedMainItem:
              selectedMainHeight ?? mainHeights[20], // Default to 170
          selectedDecimalItem:
              selectedDecimalHeight ?? decimalHeights[0], // Default to 0
          onItemSelected: (String main, String decimal) {
            setState(() {
              selectedMainHeight = main;
              selectedDecimalHeight = decimal;
            });
          },
        );
      },
    );
  }

  void _showWeightPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DualPicker(
          title: '체중 (kg)',
          mainItems: mainWeights,
          decimalItems: decimalWeights,
          selectedMainItem:
              selectedMainWeight ?? mainWeights[39], // Default to 69
          selectedDecimalItem:
              selectedDecimalWeight ?? decimalWeights[0], // Default to 0
          onItemSelected: (String main, String decimal) {
            setState(() {
              selectedMainWeight = main;
              selectedDecimalWeight = decimal;
            });
          },
        );
      },
    );
  }
}
