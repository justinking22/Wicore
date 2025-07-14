import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:with_force/styles/colors.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_app_bar.dart';
import 'package:with_force/widgets/reusable_button.dart';

class PhoneInputScreen extends StatefulWidget {
  @override
  _PhoneInputScreenState createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: '보호자 연락처',
              showTrailingButton: true,
              trailingButtonText: '건너뛰기',
              showBackButton: false,
              onTrailingPressed: () {
                context.push('/prep-done');
              },
            ),
            SizedBox(height: 20),

            // Header Text Section
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
                        '보호자의 전화번호를\n입력해주세요',
                        style: TextStyles.kBody,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: Text(
                        '비상연락이 필요한 경우\n작성해주신 연락처로 연락이 갈 예정이에요.',
                        style: TextStyles.kHint,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30),
                      Text(
                        '보호자 연락처',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: TextStyles.kFontFamily,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Phone Input Field
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
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
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),

                      Spacer(),

                      // Next Button
                      CustomButton(
                        text: '다음',
                        isEnabled: _isButtonEnabled,
                        onPressed:
                            _isButtonEnabled
                                ? () {
                                  // Handle next button press
                                  print(
                                    'Phone number: ${_phoneController.text}',
                                  );
                                }
                                : null,
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
}
