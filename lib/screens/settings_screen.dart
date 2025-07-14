import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart'; // Update this import path

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '설정',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingsItem(
                    icon: Icons.notifications_outlined,
                    title: '알림 설정',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: '개인정보 처리방침',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: '앱 정보',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: '도움말',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: '로그아웃',
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Use your AuthService to logout
                await context.read<AuthService>().signOut();
                // GoRouter will automatically redirect to login due to your redirect logic
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
