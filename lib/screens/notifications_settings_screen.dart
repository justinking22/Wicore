import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool batteryLow = true;
  bool connectionDisabled = true;
  bool userMaleConfirmed = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lighterGray,
      appBar: CustomAppBar(
        backgroundColor: CustomColors.lighterGray,
        title: '알림 설정',
        showBackButton: true,
        onBackPressed: context.pop,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              color: CustomColors.lighterGray,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Text(
                '알림을 켜고\n중요 정보를 받으세요 ',
                style: TextStyles.kSemiBold,
              ),
            ),
            Container(
              width: double.infinity,
              color: CustomColors.lighterGray,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Text(
                '알림을 켜두 수신되지 않는다면,\n휴대폰 기기의 설정 > WICORE 앱 > 알림 설정\n[켜짐]을 확인해 주세요.',
                style: TextStyles.kMedium,
              ),
            ),
            const SizedBox(height: 30),
            // Device Section Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('기기', style: TextStyles.kSemiBold),
            ),
            // Device Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingItem('배터리 낮음', batteryLow, (value) {
                    setState(() => batteryLow = value);
                  }),
                  const Divider(height: 1, color: CustomColors.softGray),
                  _buildSettingItem('연결 해지', connectionDisabled, (value) {
                    setState(() => connectionDisabled = value);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // User Section Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('사용자', style: TextStyles.kSemiBold),
            ),
            // User Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingItem('사용자 낙상여부 확인', userMaleConfirmed, (value) {
                    setState(() => userMaleConfirmed = value);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 60, // Fixed height for consistent row sizes
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center content vertically
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2, // Allow text to wrap to 2 lines if needed
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16), // Add spacing between text and switch
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}
