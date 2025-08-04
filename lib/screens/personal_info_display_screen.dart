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

class PersonalInfoDisplayScreen extends ConsumerStatefulWidget {
  @override
  _PersonalInfoDisplayScreenState createState() =>
      _PersonalInfoDisplayScreenState();
}

class _PersonalInfoDisplayScreenState
    extends ConsumerState<PersonalInfoDisplayScreen> {
  String? selectedGender = '여성'; // Set with data
  String? selectedMainHeight = '172'; // Set with data
  String? selectedDecimalHeight = '3'; // Set with data
  String? selectedMainWeight = '69'; // Set with data
  String? selectedDecimalWeight = '8'; // Set with data

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load user data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  // Load user data from API
  void _loadUserData() async {
    setState(() => _isLoading = true);

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

              // Parse height (e.g., "172" -> "172" and "0")
              final heightParts = userData.height.toString().split('.');
              selectedMainHeight = heightParts[0];
              selectedDecimalHeight =
                  heightParts.length > 1 ? heightParts[1] : '0';

              // Parse weight (e.g., "69" -> "69" and "0")
              final weightParts = userData.weight.toString().split('.');
              selectedMainWeight = weightParts[0];
              selectedDecimalWeight =
                  weightParts.length > 1 ? weightParts[1] : '0';
            });
          }
        },
      );
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Save user data to API
  void _saveUserData() async {
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

    setState(() => _isLoading = true);

    try {
      // Get current user data to preserve other fields
      final currentUserData = ref.read(currentUserDataProvider);

      if (currentUserData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      // Create updated user data
      final userRequest = UserRequest(
        item: UserItem(
          id: currentUserData.id,
          firstName: currentUserData.firstName,
          lastName: currentUserData.lastName,
          email: currentUserData.email,
          birthdate: currentUserData.birthdate,
          weight: int.parse(
            '$selectedMainWeight$selectedDecimalWeight',
          ), // Convert back to API format
          height: int.parse(
            '$selectedMainHeight$selectedDecimalHeight',
          ), // Convert back to API format
          gender: _convertGenderToEnglish(selectedGender!),
          onboarded:
              true, // Mark as onboarded since they completed personal info
        ),
      );

      await ref.read(userProvider.notifier).createUser(userRequest);

      final userState = ref.read(userProvider);
      userState.whenOrNull(
        data: (response) {
          if (response != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('신체정보가 저장되었습니다')));
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $error')));
        },
      );
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다')));
    } finally {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    // Watch for loading state from user provider
    final userState = ref.watch(userProvider);
    final isApiLoading = userState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: '신체정보',
        showBackButton: true,
        onBackPressed: context.pop,
        backgroundColor: CustomColors.lighterGray,
        // Add save action
        // actions: [
        //   if (_isLoading || isApiLoading)
        //     Padding(
        //       padding: const EdgeInsets.all(16.0),
        //       child: SizedBox(
        //         width: 20,
        //         height: 20,
        //         child: CircularProgressIndicator(strokeWidth: 2),
        //       ),
        //     )
        //   else
        //     TextButton(
        //       onPressed: _saveUserData,
        //       child: Text(
        //         '저장',
        //         style: TextStyle(
        //           color: CustomColors.primary,
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //     ),
        //],
      ),
      body: Container(
        color: CustomColors.lighterGray,
        child: SafeArea(
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1, color: Colors.grey[300]),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1, color: Colors.grey[300]),
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
                // Optional: Add a save button at the bottom
                // SizedBox(height: 20),
                // if (!_isLoading && !isApiLoading)
                //   SizedBox(
                //     width: double.infinity,
                //     child: ElevatedButton(
                //       onPressed: _saveUserData,
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: CustomColors.primary,
                //         padding: EdgeInsets.symmetric(vertical: 16),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12),
                //         ),
                //       ),
                //       child: Text(
                //         '신체정보 저장',
                //         style: TextStyle(
                //           color: Colors.white,
                //           fontSize: 16,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
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
