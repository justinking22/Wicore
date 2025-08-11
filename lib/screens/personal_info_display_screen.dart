import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/dual_picker.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_info_field.dart';
import 'package:Wicore/widgets/reusable_picker.dart';

class PersonalInfoDisplayScreen extends ConsumerStatefulWidget {
  const PersonalInfoDisplayScreen({super.key});

  @override
  ConsumerState<PersonalInfoDisplayScreen> createState() =>
      _PersonalInfoDisplayScreenState();
}

class _PersonalInfoDisplayScreenState
    extends ConsumerState<PersonalInfoDisplayScreen> {
  String? selectedGender;
  String? selectedMainHeight;
  String? selectedDecimalHeight;
  String? selectedMainWeight;
  String? selectedDecimalWeight;
  bool _isLoading = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userProvider.notifier).getCurrentUserProfile();
      final userState = ref.read(userProvider);

      userState.when(
        data: (response) {
          if (response?.data != null) {
            final userData = response!.data;
            setState(() {
              selectedGender =
                  userData?.gender != null
                      ? _convertGenderToKorean(userData!.gender!)
                      : null;
              if (userData?.height != null) {
                final heightValue = userData?.height.toString();
                if (heightValue!.contains!('.')) {
                  final heightParts = heightValue.split('.');
                  selectedMainHeight = heightParts[0];
                  selectedDecimalHeight =
                      heightParts.length > 1
                          ? heightParts[1].padRight(1, '0')
                          : '0';
                } else {
                  selectedMainHeight = heightValue;
                  selectedDecimalHeight = '0';
                }
              } else {
                selectedMainHeight = null;
                selectedDecimalHeight = null;
              }
              if (userData?.weight != null) {
                final weightValue = userData?.weight.toString();
                if (weightValue!.contains!('.')) {
                  final weightParts = weightValue.split('.');
                  selectedMainWeight = weightParts[0];
                  selectedDecimalWeight =
                      weightParts.length > 1
                          ? weightParts[1].padRight(1, '0')
                          : '0';
                } else {
                  selectedMainWeight = weightValue;
                  selectedDecimalWeight = '0';
                }
              } else {
                selectedMainWeight = null;
                selectedDecimalWeight = null;
              }
            });
          } else {
            setState(() {
              selectedGender = null;
              selectedMainHeight = null;
              selectedDecimalHeight = null;
              selectedMainWeight = null;
              selectedDecimalWeight = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No user data available')),
            );
          }
        },
        loading: () {},
        error: (error, stack) {
          setState(() {
            selectedGender = null;
            selectedMainHeight = null;
            selectedDecimalHeight = null;
            selectedMainWeight = null;
            selectedDecimalWeight = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load user data: $error')),
          );
        },
      );
    } catch (e) {
      setState(() {
        selectedGender = null;
        selectedMainHeight = null;
        selectedDecimalHeight = null;
        selectedMainWeight = null;
        selectedDecimalWeight = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception loading user data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
            setState(() => selectedGender = selected);
            try {
              await ref
                  .read(userProvider.notifier)
                  .updateCurrentUserProfile(
                    UserUpdateRequest(
                      gender: _convertGenderToEnglish(selected),
                    ),
                  );
              _loadUserData();
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('성별 저장 오류: $e')));
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
          selectedMainItem:
              selectedMainHeight ?? mainHeights[116], // Default to 170
          selectedDecimalItem:
              selectedDecimalHeight ?? decimalHeights[0], // Default to 0
          onItemSelected: (String main, String decimal) async {
            setState(() {
              selectedMainHeight = main;
              selectedDecimalHeight = decimal;
            });
            try {
              final height = double.parse('$main.$decimal');
              await ref
                  .read(userProvider.notifier)
                  .updateCurrentUserProfile(UserUpdateRequest(height: height));
              _loadUserData();
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('키 저장 오류: $e')));
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
          selectedMainItem:
              selectedMainWeight ?? mainWeights[67], // Default to 69
          selectedDecimalItem:
              selectedDecimalWeight ?? decimalWeights[0], // Default to 0
          onItemSelected: (String main, String decimal) async {
            setState(() {
              selectedMainWeight = main;
              selectedDecimalWeight = decimal;
            });
            try {
              final weight = double.parse('$main.$decimal');
              await ref
                  .read(userProvider.notifier)
                  .updateCurrentUserProfile(UserUpdateRequest(weight: weight));
              _loadUserData();
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('체중 저장 오류: $e')));
            }
          },
        );
      },
    );
  }

  String _convertGenderToKorean(String gender) {
    return gender.toLowerCase() == 'male' ? '남성' : '여성';
  }

  String _convertGenderToEnglish(String gender) {
    return gender == '남성' ? 'male' : 'female';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '신체정보',
        showBackButton: true,
        onBackPressed: context.pop,
        backgroundColor: CustomColors.lighterGray,
      ),
      body: Container(
        color: CustomColors.lighterGray,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer(
              builder: (context, ref, child) {
                final userState = ref.watch(userProvider);
                final isApiLoading = userState.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );

                return Column(
                  children: [
                    if (_isLoading || isApiLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      ),
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
                          // Gender Field
                          InfoField(
                            hasUnit: false,
                            label: '성별',
                            value: selectedGender ?? '입력하기',
                            isPlaceholder: selectedGender == null,
                            onTap: _showGenderPicker,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(height: 1, color: Colors.grey[300]),
                          ),

                          // Height Field - Fixed display format like first design
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
                            onTap: _showHeightPicker,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(height: 1, color: Colors.grey[300]),
                          ),

                          // Weight Field - Fixed display format like first design
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
                            onTap: _showWeightPicker,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
