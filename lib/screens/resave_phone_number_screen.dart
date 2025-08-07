import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';

class ResavePhoneNumberScreen extends ConsumerStatefulWidget {
  const ResavePhoneNumberScreen({super.key});

  @override
  _ResavePhoneNumberScreenState createState() =>
      _ResavePhoneNumberScreenState();
}

class _ResavePhoneNumberScreenState
    extends ConsumerState<ResavePhoneNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhoneNumber();
    });
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    setState(() {
      _isButtonEnabled = _phoneController.text.isNotEmpty;
    });
  }

  void _loadPhoneNumber() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(userProvider.notifier).getCurrentUserProfile();
      final userState = ref.read(userProvider);
      userState.when(
        data: (response) {
          if (response?.data?.number != null) {
            setState(() {
              _phoneController.text = response!.data!.number!;
              _isButtonEnabled = true;
            });
          }
        },
        loading: () {},
        error: (error, stack) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('전화번호 로드 실패: $error')));
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('전화번호 로드 중 오류: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _savePhoneNumber() async {
    if (!_isButtonEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('전화번호를 입력해주세요')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final phoneNumber = _phoneController.text;
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(UserUpdateRequest(number: phoneNumber));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('전화번호가 성공적으로 저장되었습니다')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isApiLoading = userState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Container(
          color: CustomColors.lighterGray,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(
                title: '보호자 연락처',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                backgroundColor: CustomColors.lighterGray,
              ),
              const SizedBox(height: 20),
              Container(
                color: CustomColors.lighterGray,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Container(
                        color: CustomColors.lighterGray,
                        width: double.infinity,
                        child: Text(
                          '보호자의 전화번호를\n입력해주세요',
                          style: TextStyles.kBody,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Container(
                        color: CustomColors.lighterGray,
                        width: double.infinity,
                        child: Text(
                          '비상연락이 필요한 경우\n작성해주신 연락처로 연락이 갈 예정이에요.',
                          style: TextStyles.kMedium.copyWith(
                            color: CustomColors.lightGray,
                          ),
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
                              vertical: 16,
                            ),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
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
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontFamily: TextStyles.kFontFamily,
                              ),
                            ),
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
                            text: '저장',
                            isEnabled: _isButtonEnabled,
                            onPressed:
                                _isButtonEnabled ? _savePhoneNumber : null,
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
      ),
    );
  }
}
