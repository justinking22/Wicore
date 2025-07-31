import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(userProvider.notifier).loadUserProfile();
    });
  }

  Future<void> _handleLogout() async {
    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final result = await authNotifier.signOut();

      if (result.success && mounted) {
        // Clear any cached user data
        // ref.invalidate(userProvider);

        // Navigate to login
        context.go('/login');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '로그아웃 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Future<void> _handleDeleteData() async {
  //   // Show confirmation dialog first
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('데이터 삭제'),
  //           content: const Text('정말로 모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, false),
  //               child: const Text('취소'),
  //             ),
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, true),
  //               child: const Text('삭제', style: TextStyle(color: Colors.red)),
  //             ),
  //           ],
  //         ),
  //   );

  //   if (confirmed == true) {
  //     // Implement data deletion logic here
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('데이터 삭제 기능은 곧 구현될 예정입니다.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //   }
  // }

  // Future<void> _handleDeleteAccount() async {
  //   // Show confirmation dialog first
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('회원 탈퇴'),
  //           content: const Text('정말로 회원 탈퇴를 하시겠습니까?\n계정과 모든 데이터가 영구적으로 삭제됩니다.'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, false),
  //               child: const Text('취소'),
  //             ),
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, true),
  //               child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
  //             ),
  //           ],
  //         ),
  //   );

  //   if (confirmed == true) {
  //     try {
  //       // final userNotifier = ref.read(userProvider.notifier);
  //       // final success = await userNotifier.deleteProfile();

  //       if (success && mounted) {
  //         // Clear auth state and navigate to login
  //         ref.read(authNotifierProvider.notifier).signOut();
  //         context.go('/login');

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('회원 탈퇴가 완료되었습니다.'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       } else if (mounted) {
  //         final errorMessage = ref.read(userProvider).errorMessage;
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(errorMessage ?? '회원 탈퇴 중 오류가 발생했습니다.'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('회원 탈퇴 중 오류가 발생했습니다.'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    // final userState = ref.watch(userProvider);

    // Get user email - either from user profile or auth state
    String displayEmail = 'user@email.com'; // fallback
    // if (userState.user?.email != null) {
    //   displayEmail = userState.user!.email;
    // } else if (authState.user?.email != null) {
    //   displayEmail = authState.user!.email;
    // }

    return Scaffold(
      backgroundColor: CustomColors.lighterGray,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    context.push('/app-info');
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
                    displayEmail,
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
                        context.push('/notifications-settings');
                      }, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('서비스 이용약관', () {
                        context.push('/terms-of-use');
                      }, Colors.black),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // 계정 section
                Text(
                  '계정',
                  style: TextStyles.kSemiBold.copyWith(
                    color: CustomColors.mediumGray,
                  ),
                ),

                SizedBox(height: 12),

                // Account section container
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
                      }, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('로그아웃', _handleLogout, Colors.black),
                      _buildDivider(),
                      _buildMenuItem('데이터 삭제', () {}, Colors.red),
                      _buildDivider(),
                      _buildMenuItem('회원 탈퇴', () {}, Colors.red),
                    ],
                  ),
                ),

                // Add some bottom padding
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
            style: TextStyles.kMedium.copyWith(color: titleTextColor),
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
