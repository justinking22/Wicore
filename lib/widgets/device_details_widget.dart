import 'package:Wicore/dialogs/settings_confirmation_dialog.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import 'dart:async';

class DeviceDetailsWidget extends ConsumerStatefulWidget {
  final String deviceId;
  final VoidCallback? onDisconnect;
  final VoidCallback? onUnpaired;

  const DeviceDetailsWidget({
    Key? key,
    required this.deviceId,
    this.onDisconnect,
    this.onUnpaired,
  }) : super(key: key);

  @override
  ConsumerState<DeviceDetailsWidget> createState() =>
      _DeviceDetailsWidgetState();
}

class _DeviceDetailsWidgetState extends ConsumerState<DeviceDetailsWidget> {
  int? selectedStrength;
  bool isUpdating = false;
  bool isUnpairing = false;
  Timer? _batteryUpdateTimer;

  @override
  void initState() {
    super.initState();
    print(
      '🔍 DeviceDetailsWidget initialized with deviceId: ${widget.deviceId}',
    );

    selectedStrength = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveDeviceData();
      _startBatteryUpdateTimer();
    });
  }

  @override
  void didUpdateWidget(DeviceDetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      selectedStrength = null;
      print(
        '🔍 DeviceDetailsWidget - Device changed, resetting selected strength',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadActiveDeviceData();
      });
    }
  }

  @override
  void dispose() {
    _batteryUpdateTimer?.cancel();
    super.dispose();
  }

  // ✅ UPDATED: Load active device data using new provider
  void _loadActiveDeviceData() {
    print('🔋 === LOADING ACTIVE DEVICE DATA ===');
    print('🔋 Target device: ${widget.deviceId}');

    // Refresh the active device provider
    ref.invalidate(activeDeviceProvider);

    print('🔋 Active device data source refreshed');
  }

  void _startBatteryUpdateTimer() {
    _batteryUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        print('🔋 Timer: Refreshing battery data...');
        _loadActiveDeviceData();
      }
    });
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
        return "약";
      case 1:
        return "중";
      case 2:
        return "강";
      default:
        return "약";
    }
  }

  // UNPAIR METHODS (unchanged)
  Future<bool> _showUnpairConfirmation() async {
    final result = await DeviceUnpairConfirmationDialog.show(
      context,
      widget.deviceId,
    );
    return result ?? false;
  }

  // ENHANCED: Dynamic strength update
  Future<void> _updateDeviceStrength(int newStrength) async {
    if (isUpdating || isUnpairing) return;

    print('🔧 === STARTING DYNAMIC STRENGTH UPDATE ===');
    print('🔧 Device: ${widget.deviceId}');
    print('🔧 New strength: $newStrength');

    setState(() {
      isUpdating = true;
      selectedStrength = newStrength; // Immediate UI update
    });

    try {
      final currentUser = ref.read(currentUserDataProvider);
      print('🔧 Current user before update:');
      print('  - Username: ${currentUser?.firstName}');
      print('  - Current strength: ${currentUser?.deviceStrength}');

      final updateRequest = UserUpdateRequest(deviceStrength: newStrength);
      print('🔧 Update request: ${updateRequest.toString()}');

      print('🔧 Calling updateCurrentUserProfile...');
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(updateRequest);
      print('🔧 ✅ updateCurrentUserProfile completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '기기 강도가 ${_getStrengthText(newStrength)}(으)로 업데이트되었습니다',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Force refresh of device data
      print('🔧 Refreshing device data...');
      _loadActiveDeviceData();

      await Future.delayed(const Duration(milliseconds: 300));

      print('🔧 ✅ === DYNAMIC STRENGTH UPDATE COMPLETED ===');
    } catch (error) {
      print('🔧 ❌ === DYNAMIC STRENGTH UPDATE FAILED ===');
      print('🔧 ❌ Error: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('강도 업데이트에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        selectedStrength = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Widget _buildStrengthButton(String text, bool isSelected, int strengthValue) {
    final bool isCurrentlyUpdating =
        isUpdating && selectedStrength == strengthValue;

    return Expanded(
      child: GestureDetector(
        onTap:
            isUpdating || isUnpairing
                ? null
                : () {
                  _updateDeviceStrength(strengthValue);
                },
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child:
                isCurrentlyUpdating
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                    : Text(
                      text,
                      style: TextStyles.kMedium.copyWith(
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  // ✅ OPTIMIZED: Smart build method with new providers
  @override
  Widget build(BuildContext context) {
    print('🔋 === DeviceDetailsWidget Build ===');
    print('🔋 Target deviceId: ${widget.deviceId}');

    // ✅ UPDATED: Use the new simplified providers
    final activeDeviceAsync = ref.watch(activeDeviceProvider);
    final deviceBatteryAsync = ref.watch(
      deviceBatteryProvider(widget.deviceId),
    );
    final deviceSignalAsync = ref.watch(deviceSignalProvider(widget.deviceId));

    return activeDeviceAsync.when(
      data: (activeDevice) {
        if (activeDevice == null) {
          return _buildNotFoundError();
        }

        // Check if this is the correct device
        if (activeDevice.safeDeviceId != widget.deviceId) {
          return _buildDeviceNotActiveError();
        }

        print('🔋 ✅ Using active device data');

        return _buildDeviceContent(
          deviceId: activeDevice.safeDeviceId,
          currentStrength: deviceSignalAsync.when(
            data: (signal) => signal,
            loading: () => activeDevice.signalStrength,
            error: (_, __) => activeDevice.signalStrength,
          ),
          batteryLevel: deviceBatteryAsync.when(
            data: (battery) => battery ?? activeDevice.batteryLevel,
            loading: () => activeDevice.batteryLevel,
            error: (_, __) => activeDevice.batteryLevel,
          ),
          isNewlyPaired: false,
          isLoadingBattery: false,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildDeviceContent({
    required String deviceId,
    required int? currentStrength,
    required int batteryLevel,
    required bool isNewlyPaired,
    required bool isLoadingBattery,
  }) {
    final effectiveStrength = selectedStrength ?? currentStrength ?? 0;

    print('🔍 DeviceDetails - Building content:');
    print('  - Current strength from API: $currentStrength');
    print('  - Selected strength (UI): $selectedStrength');
    print('  - Effective strength: $effectiveStrength');
    print('  - Battery: $batteryLevel');

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with device info and unpair button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '기기번호',
                          style: TextStyles.kMedium.copyWith(fontSize: 18),
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Text(
                    deviceId,
                    style: TextStyles.kRegular.copyWith(
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Device Image Area
              Flexible(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  child: DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      color: Colors.grey[400]!,
                      strokeWidth: 2,
                      dashPattern: [8, 4],
                      radius: Radius.circular(8),
                      padding: EdgeInsets.zero,
                    ),
                    child: Container(
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isNewlyPaired
                                  ? Icons.qr_code_scanner
                                  : Icons.devices,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              isNewlyPaired ? '새로 연결된 기기' : '기기 이미지 영역',
                              style: TextStyles.kMedium.copyWith(
                                fontSize: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ✅ DYNAMIC Battery Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '배터리',
                          style: TextStyles.kMedium.copyWith(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isLoadingBattery)
                          Container(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              // ✅ DYNAMIC: Battery level updates automatically
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  '$batteryLevel',
                                  key: ValueKey(batteryLevel),
                                  style: TextStyles.kSemiBold.copyWith(
                                    fontSize: 32,
                                    color: Colors.black,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              Text(
                                ' %',
                                style: TextStyles.kMedium.copyWith(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // ✅ DYNAMIC Battery status button
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 36,
                    constraints: BoxConstraints(minWidth: 80),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getBatteryButtonColor(batteryLevel),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        _getBatteryButtonText(batteryLevel),
                        style: TextStyles.kRegular.copyWith(
                          color: Colors.black,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 16),

              // Signal Strength Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '출력값(강도)',
                    style: TextStyles.kMedium.copyWith(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ DYNAMIC Signal Strength Buttons
              Opacity(
                opacity: isUnpairing ? 0.5 : 1.0,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildStrengthButton("약", effectiveStrength == 0, 0),
                      _buildStrengthButton("중", effectiveStrength == 1, 1),
                      _buildStrengthButton("강", effectiveStrength == 2, 2),
                    ],
                  ),
                ),
              ),

              // Show unpair status
              if (isUnpairing) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '기기 연결을 해제하는 중입니다...',
                          style: TextStyles.kRegular.copyWith(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Bottom spacing
              Flexible(
                flex: 1,
                child: Container(constraints: BoxConstraints(minHeight: 40)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('활성 기기를 찾을 수 없습니다'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _loadActiveDeviceData();
            },
            child: Text('새로고침'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceNotActiveError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_off, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text('기기가 비활성 상태입니다'),
          Text('기기를 켜고 다시 시도해주세요'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _loadActiveDeviceData();
            },
            child: Text('다시 확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('오류: $error'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _loadActiveDeviceData();
            },
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Color _getBatteryButtonColor(int batteryPercentage) {
    if (batteryPercentage <= 20) {
      return const Color(0xFFFF6B47);
    } else if (batteryPercentage <= 50) {
      return CustomColors.beigeTone;
    } else {
      return const Color(0xFFB8FF00);
    }
  }

  String _getBatteryButtonText(int batteryPercentage) {
    if (batteryPercentage <= 20) {
      return "매우 부족";
    } else if (batteryPercentage <= 50) {
      return "부족함";
    } else {
      return "충분함";
    }
  }
}
