import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoggingOut = false;

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

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말로 로그아웃하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('로그아웃'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

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
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('데이터 삭제'),
            content: const Text(
              '정말로 모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.\n\n삭제될 데이터:\n• 기기 사용 기록\n• 신체 정보\n• 앱 설정',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
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
    // Show initial confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              '회원 탈퇴',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              '정말로 회원 탈퇴를 하시겠습니까?\n\n계정과 모든 데이터가 영구적으로 삭제되며, 이 작업은 되돌릴 수 없습니다.\n\n삭제될 내용:\n• 계정 정보\n• 모든 사용 데이터\n• 기기 사용 기록\n• 신체 정보',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '탈퇴하기',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Show final confirmation with text input
    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('최종 확인', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '회원 탈퇴를 진행하려면 아래에 "탈퇴"를 입력해주세요.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '탈퇴',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim() == '탈퇴') {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('"탈퇴"를 정확히 입력해주세요.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('탈퇴하기', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (finalConfirmed == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('계정을 삭제하고 있습니다...'),
                  ],
                ),
              ),
        );

        // Implement actual account deletion here
        // final userNotifier = ref.read(userProvider.notifier);
        // final success = await userNotifier.deleteProfile();

        // Simulate account deletion
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          // Clear auth state and navigate to login
          await ref.read(authNotifierProvider.notifier).signOut();
          context.go('/welcome');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원 탈퇴가 완료되었습니다. 그동안 이용해 주셔서 감사합니다.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원 탈퇴 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                // Handle info button press
                context.push('/app-info');
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
                              context.push('/password-reset');
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
                              '회원 탈퇴',
                              _handleDeleteAccount,
                              Colors.red,
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
      onTap: onPressed,
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // Added to handle long text properly
                child: Text(
                  title,
                  style: TextStyles.kMedium.copyWith(color: titleTextColor),
                ),
              ),
              if (showArrow)
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
