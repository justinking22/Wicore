import 'package:Wicore/models/notification_preferences_model.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool batteryLow = true;
  bool connectionDisabled = true;
  bool userFallConfirmed = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load current settings will be handled by the providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    // Get current settings from the provider
    final notifications = ref.read(currentNotificationPreferencesProvider);

    if (notifications != null) {
      setState(() {
        batteryLow = notifications.lowBattery ?? true;
        connectionDisabled = notifications.deviceDisconnected ?? true;
        userFallConfirmed = notifications.fallDetection ?? true;
      });
      print(
        '🔔 📱 Loaded current notification settings: battery=$batteryLow, connection=$connectionDisabled, fall=$userFallConfirmed',
      );
    } else {
      print('🔔 📱 No notification settings found, using defaults');
      // Keep default values (true)
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to notification changes from the provider
    ref.listen<
      NotificationPreferences?
    >(currentNotificationPreferencesProvider, (previous, next) {
      if (next != null && mounted) {
        setState(() {
          batteryLow = next.lowBattery ?? true;
          connectionDisabled = next.deviceDisconnected ?? true;
          userFallConfirmed = next.fallDetection ?? true;
        });
        print(
          '🔔 📱 Provider updated notification settings: battery=$batteryLow, connection=$connectionDisabled, fall=$userFallConfirmed',
        );
      }
    });

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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingItem('배터리 낮음', batteryLow, (value) async {
                    await _updateNotificationSetting('batteryLow', value);
                  }),
                  const Divider(height: 1, color: CustomColors.softGray),
                  _buildSettingItem('연결 해지', connectionDisabled, (value) async {
                    await _updateNotificationSetting(
                      'connectionDisabled',
                      value,
                    );
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingItem('사용자 낙상여부 확인', userFallConfirmed, (
                    value,
                  ) async {
                    await _updateNotificationSetting(
                      'userFallConfirmed',
                      value,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNotificationSetting(
    String settingType,
    bool value,
  ) async {
    if (isLoading) return; // Prevent multiple simultaneous updates

    setState(() {
      isLoading = true;
      // Update UI immediately for better UX
      switch (settingType) {
        case 'batteryLow':
          batteryLow = value;
          break;
        case 'connectionDisabled':
          connectionDisabled = value;
          break;
        case 'userFallConfirmed':
          userFallConfirmed = value;
          break;
      }
    });

    try {
      final userNotifier = ref.read(userProvider.notifier);

      // PATCH: Update only the specific setting (more efficient)
      switch (settingType) {
        case 'batteryLow':
          await userNotifier.updateBatteryLowNotification(value);
          break;
        case 'connectionDisabled':
          await userNotifier.updateConnectionDisconnectedNotification(value);
          break;
        case 'userFallConfirmed':
          await userNotifier.updateFallDetectionNotification(value);
          break;
      }

      print(
        '🔔 ✅ Single notification setting updated via PATCH: $settingType = $value',
      );
    } catch (error) {
      print('🔔 ❌ Error updating notification setting: $error');

      // Revert UI state on error
      setState(() {
        switch (settingType) {
          case 'batteryLow':
            batteryLow = !value;
            break;
          case 'connectionDisabled':
            connectionDisabled = !value;
            break;
          case 'userFallConfirmed':
            userFallConfirmed = !value;
            break;
        }
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 설정 업데이트에 실패했습니다: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildSettingItem(String title, bool value, Function(bool) onChanged) {
    return Container(
      height: 60, // Fixed height for all rows
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              height: 60, // Same height as parent
              alignment:
                  Alignment.centerLeft, // Center text vertically and align left
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 60, // Same height as parent
            alignment: Alignment.center, // Center switch vertically
            child: Stack(
              alignment: Alignment.center,
              children: [
                CupertinoSwitch(
                  value: value,
                  onChanged:
                      isLoading ? null : onChanged, // Disable when loading
                  activeColor: const Color(0xFF4CAF50),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
