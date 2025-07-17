import 'dart:ffi';

import 'package:Wicore/providers/auth_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      backgroundColor: CustomColors.lighterGray,
      body: SafeArea(
        child: SingleChildScrollView(
          // Add this wrapper
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAppBar(
                  backgroundColor: CustomColors.lighterGray,
                  title: '설정',
                  trailingButtonIcon: Icons.info_outline,
                  showTrailingButton: true,
                  onTrailingPressed: () {
                    // Handle info button press
                  },
                  showBackButton: false,
                ),
                // Email header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(10, 16, 10, 16),
                  decoration: BoxDecoration(
                    color: CustomColors.grayWithOpacity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'user@email.com',
                    textAlign: TextAlign.center,
                    style: TextStyles.kMedium.copyWith(
                      color: CustomColors.lightGray,
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // 사용자 section
                Text(
                  '사용자',
                  style: TextStyles.kSemiBold.copyWith(
                    color: CustomColors.mediumGray,
                  ),
                ),

                SizedBox(height: 12),

                // User section container
                Container(
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMenuItem('기기 사용 기록', () {
                        context.push('/device-history-screen');
                      }, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('신체정보', () {
                        context.push('/personal-info-display-screen');
                      }, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('보호자 연락처', () {
                        context.push('/re-save-phone-number-screen');
                      }, Colors.black),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // 서비스 section
                Text(
                  '서비스',
                  style: TextStyles.kSemiBold.copyWith(
                    color: CustomColors.mediumGray,
                  ),
                ),

                SizedBox(height: 12),

                // Service section container
                Container(
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMenuItem('알림 설정', () {
                        context.push('/notificatios-settings');
                      }, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('서비스 이용약관', () {
                        context.push('/terms-of-use');
                        context.go('/login');
                      }, Colors.black),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // 서비스 section
                Text(
                  '계정',
                  style: TextStyles.kSemiBold.copyWith(
                    color: CustomColors.mediumGray,
                  ),
                ),

                SizedBox(height: 12),

                // Service section container
                Container(
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMenuItem('비밀번호 재설정', () {
                        context.push('/password-reset-confirmation-screen');
                        context.go('/login');
                      }, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('로그아웃', () {
                        authService.signOut();
                        context.go('/login');
                      }, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('테이터 삭제', () {}, Colors.red),
                      _buildDivider(),
                      _buildMenuItem('회원 탈퇴', () {}, Colors.red),
                    ],
                  ),
                ),

                // Add some bottom padding to prevent content from being too close to screen edge
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    VoidCallback onPressed,
    Color titleTextColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyles.kMedium.copyWith(
              color: titleTextColor ?? Colors.black,
            ),
          ),
          IconButton(
            onPressed: onPressed,
            icon: Icon(Icons.chevron_right, color: Colors.black, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: CustomColors.lightGray);
  }
}
