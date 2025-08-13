import 'package:Wicore/dialogs/settings_confirmation_dialog.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/user_provider.dart'; // Add this import
import 'package:Wicore/screens/personal_info_input_screen.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    // Load user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(userProvider.notifier).loadUserProfile();
    });
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    // Show custom logout confirmation dialog
    final confirmed = await LogoutConfirmationDialog.show(context);

    if (confirmed != true) return; // User chose "아니요" (No)

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.signOut();

      if (mounted) {
        // Navigate to login
        context.go('/login');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다.'),
            backgroundColor: Colors.green,
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _handleDeleteData() async {
    // Show iOS style confirmation dialog
    final confirmed = await IOSConfirmationDialog.show(
      context: context,
      title: '데이터 삭제',
      content:
          '정말로 모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.\n\n삭제될 데이터:\n• 기기 사용 기록\n• 신체 정보\n• 앱 설정',
      confirmText: '삭제',
      cancelText: '취소',
      confirmTextColor: CupertinoColors.destructiveRed,
    );

    if (confirmed == true) {
      try {
        // Show loading dialog
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const CupertinoAlertDialog(
                content: Row(
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 16),
                    Text('데이터를 삭제하고 있습니다...'),
                  ],
                ),
              ),
        );

        // Simulate data deletion (implement actual logic here)
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모든 데이터가 삭제되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('데이터 삭제 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeletingAccount) return;

    // Show custom account deletion dialog
    final confirmed = await AccountDeletionDialog.show(context);

    if (confirmed != true) return; // User chose "아니요" (No)

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      // Show loading dialog
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const CupertinoAlertDialog(
              content: Row(
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(width: 16),
                  Text('계정을 삭제하고 있습니다...'),
                ],
              ),
            ),
      );

      // Get current user data from auth state
      final authState = ref.read(authNotifierProvider);
      final userData = authState.userData;
      final userId = userData?.id ?? userData?.username;

      if (userId == null || userId.isEmpty) {
        throw Exception('사용자 ID를 찾을 수 없습니다.');
      }

      // Call delete user endpoint
      final userNotifier = ref.read(userProvider.notifier);
      await userNotifier.deleteUser(userId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Clear auth state and navigate to welcome/login
        await ref.read(authNotifierProvider.notifier).signOut();

        // Clear user provider state
        ref.read(userProvider.notifier).clearState();

        // Navigate to welcome screen
        context.go('/welcome');

        // Show completion dialog
        await IOSConfirmationDialog.show(
          context: context,
          title: '회원 탈퇴 완료',
          content: '회원님의 정보가 모두 삭제되었습니다.\n다시 이용하시려면 새로 가입해주세요.',
          confirmText: '확인',
          cancelText: '', // Hide cancel button
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        await IOSConfirmationDialog.show(
          context: context,
          title: '오류',
          content: '회원 탈퇴 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
          confirmText: '확인',
          cancelText: '', // Hide cancel button
          confirmTextColor: CupertinoColors.destructiveRed,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Get user email from auth state
    String displayEmail = 'user@email.com'; // fallback
    if (authState.userData?.email != null) {
      displayEmail = authState.userData!.email!;
    }

    return Scaffold(
      backgroundColor: CustomColors.lighterGray,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              backgroundColor: CustomColors.lighterGray,
              title: '설정',
              trailingButtonIcon: Icons.info_outline,
              showTrailingButton: true,
              onTrailingPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalInfoInputScreen(),
                  ),
                );
              },
              showBackButton: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
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

                      const SizedBox(height: 24),

                      // 사용자 section
                      Text(
                        '사용자',
                        style: TextStyles.kSemiBold.copyWith(
                          color: CustomColors.mediumGray,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // User section container
                      Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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

                      const SizedBox(height: 32),

                      // 서비스 section
                      Text(
                        '서비스',
                        style: TextStyles.kSemiBold.copyWith(
                          color: CustomColors.mediumGray,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Service section container
                      Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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

                      const SizedBox(height: 32),

                      // 계정 section
                      Text(
                        '계정',
                        style: TextStyles.kSemiBold.copyWith(
                          color: CustomColors.mediumGray,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Account section container
                      Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMenuItem('비밀번호 재설정', () {
                              context.push(
                                '/password-reset-confirmation-screen',
                              );
                            }, Colors.black),
                            _buildDivider(),
                            _buildMenuItem(
                              _isLoggingOut ? '로그아웃 중...' : '로그아웃',
                              _isLoggingOut ? () {} : _handleLogout,
                              Colors.black,
                              isLoading: _isLoggingOut,
                              showArrow: false,
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              '데이터 삭제',
                              _handleDeleteData,
                              Colors.red,
                              showArrow: false,
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              _isDeletingAccount ? '탈퇴 처리 중...' : '회원 탈퇴',
                              _isDeletingAccount ? () {} : _handleDeleteAccount,
                              Colors.red,
                              isLoading: _isDeletingAccount,
                              showArrow: false,
                            ),
                          ],
                        ),
                      ),

                      // Add some bottom padding
                      const SizedBox(height: 20),
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

  Widget _buildMenuItem(
    String title,
    VoidCallback onPressed,
    Color titleTextColor, {
    bool isLoading = false,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.kMedium.copyWith(
                    color: isLoading ? Colors.grey : titleTextColor,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CupertinoActivityIndicator(),
                )
              else if (showArrow)
                const Icon(Icons.chevron_right, color: Colors.black, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: CustomColors.lighterGray);
  }
}
