import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../providers/device_list_provider.dart';
import 'dart:async';

class DeviceDetailsWidget extends ConsumerStatefulWidget {
  final String deviceId;
  final int batteryPercentage;
  final VoidCallback? onDisconnect;

  const DeviceDetailsWidget({
    Key? key,
    required this.deviceId,
    this.batteryPercentage = 75,
    this.onDisconnect,
  }) : super(key: key);

  @override
  ConsumerState<DeviceDetailsWidget> createState() =>
      _DeviceDetailsWidgetState();
}

class _DeviceDetailsWidgetState extends ConsumerState<DeviceDetailsWidget> {
  int? selectedStrength;
  bool isUpdating = false;
  Timer? _batteryUpdateTimer;

  @override
  void initState() {
    super.initState();
    print(
      '🔍 DeviceDetailsWidget initialized with deviceId: ${widget.deviceId}',
    );

    // Reset selected strength when widget initializes
    selectedStrength = null;

    // FIXED: Move provider calls to addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load active devices immediately when widget initializes
      _loadActiveDevicesData();

      // Set up periodic battery updates every 30 seconds
      _startBatteryUpdateTimer();
    });
  }

  @override
  void didUpdateWidget(DeviceDetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selected strength if device ID changes
    if (oldWidget.deviceId != widget.deviceId) {
      selectedStrength = null;
      print(
        '🔍 DeviceDetailsWidget - Device changed, resetting selected strength',
      );

      // Load new device data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadActiveDevicesData();
      });
    }
  }

  @override
  void dispose() {
    _batteryUpdateTimer?.cancel();
    super.dispose();
  }

  void _loadActiveDevicesData() {
    print('🔋 Loading active devices data for battery info...');

    // Load active devices using the notifier
    ref
        .read(deviceListNotifierProvider.notifier)
        .loadActiveDevices(refresh: true);

    // Also refresh the FutureProvider
    ref.invalidate(activeDeviceListProvider);
  }

  void _startBatteryUpdateTimer() {
    _batteryUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        print('🔋 Timer: Refreshing battery data...');
        _loadActiveDevicesData();
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

  int _getStrengthValue(String text) {
    switch (text) {
      case "약":
        return 0;
      case "중":
        return 1;
      case "강":
        return 2;
      default:
        return 0;
    }
  }

  // ✅ FIXED: No conversion needed - API and display use same values
  int _apiStrengthToDisplayStrength(int apiStrength) {
    // Both API and display use: 0=약, 1=중, 2=강
    return apiStrength;
  }

  // ✅ FIXED: No conversion needed - same values
  int _displayStrengthToUserStrength(int displayStrength) {
    // System uses: 0=약, 1=중, 2=강
    return displayStrength;
  }

  Future<void> _updateDeviceStrength(int newDisplayStrength) async {
    if (isUpdating) return;

    setState(() {
      isUpdating = true;
      selectedStrength = newDisplayStrength;
    });

    try {
      // Convert display strength to user profile strength
      final userStrength = _displayStrengthToUserStrength(newDisplayStrength);

      print(
        '🔧 DeviceDetails - Updating strength: display=$newDisplayStrength, user=$userStrength',
      );

      final updateRequest = UserUpdateRequest(deviceStrength: userStrength);
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(updateRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '기기 강도가 ${_getStrengthText(newDisplayStrength)}(으)로 업데이트되었습니다',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refresh device providers to get updated data
      ref.invalidate(userDeviceListProvider);
      ref.invalidate(activeDeviceListProvider);
      _loadActiveDevicesData();

      // Wait a moment for the providers to refresh
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        setState(() {
          // This will trigger a rebuild and re-fetch from providers
        });
      }

      print('✅ DeviceDetails - Strength updated and UI refreshed');
    } catch (error) {
      print('🔧 ❌ Error updating device strength: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('강도 업데이트에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Reset selection on error
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

  Widget _buildStrengthButton(
    String text,
    bool isSelected,
    int displayStrength,
  ) {
    final strengthValue = _getStrengthValue(text);
    final bool isCurrentlyUpdating =
        isUpdating && selectedStrength == strengthValue;

    return Expanded(
      child: GestureDetector(
        onTap:
            isUpdating
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

  Widget _buildDeviceContent({
    required String deviceId,
    required int? currentStrength,
    required int batteryLevel,
    required bool isNewlyPaired,
    required bool isLoadingBattery,
  }) {
    // Convert API strength to display strength for UI
    final displayStrength =
        currentStrength != null
            ? _apiStrengthToDisplayStrength(currentStrength)
            : 0;

    // Use selectedStrength if available (for immediate UI updates), otherwise use API strength
    final effectiveDisplayStrength = selectedStrength ?? displayStrength;

    print('🔍 DeviceDetails - Building content:');
    print('  - API strength: $currentStrength');
    print('  - Display strength: $displayStrength');
    print('  - Selected strength: $selectedStrength');
    print('  - Effective strength: $effectiveDisplayStrength');
    print('  - Battery: $batteryLevel');
    print('  - Loading battery: $isLoadingBattery');

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Device ID Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '기기번호',
                    style: TextStyles.kMedium.copyWith(fontSize: 18),
                  ),
                  Text(
                    deviceId,
                    style: TextStyles.kRegular.copyWith(
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Device Image Area - Flexible to take available space
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
                            if (isNewlyPaired) ...[
                              SizedBox(height: 8),
                              Text(
                                deviceId,
                                style: TextStyles.kRegular.copyWith(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Battery Section with improved centering
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .center, // Add this for better vertical alignment
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .center, // Center align all elements
                      children: [
                        Text(
                          '배터리',
                          style: TextStyles.kMedium.copyWith(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12), // Slightly increased spacing
                        if (isLoadingBattery)
                          Container(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline:
                                TextBaseline
                                    .alphabetic, // Align baselines for better text alignment
                            children: [
                              Text(
                                '$batteryLevel',
                                style: TextStyles.kSemiBold.copyWith(
                                  fontSize: 32,
                                  color: Colors.black,
                                  height:
                                      1.0, // Control line height for better alignment
                                ),
                              ),
                              Text(
                                ' %',
                                style: TextStyles.kMedium.copyWith(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.0, // Match line height
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Battery status button with proper centering
                  Container(
                    height: 36,
                    constraints: BoxConstraints(
                      minWidth:
                          80, // Ensure minimum width for consistent button size
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getBatteryButtonColor(batteryLevel),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      // Explicitly center the text
                      child: Text(
                        _getBatteryButtonText(batteryLevel),
                        style: TextStyles.kRegular.copyWith(
                          color: Colors.black,
                          height: 1.0, // Control line height
                        ),
                        textAlign: TextAlign.center, // Center align the text
                        overflow:
                            TextOverflow.ellipsis, // Handle overflow gracefully
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

              // Signal Strength Buttons
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildStrengthButton(
                      "약",
                      effectiveDisplayStrength == 0,
                      effectiveDisplayStrength,
                    ),
                    _buildStrengthButton(
                      "중",
                      effectiveDisplayStrength == 1,
                      effectiveDisplayStrength,
                    ),
                    _buildStrengthButton(
                      "강",
                      effectiveDisplayStrength == 2,
                      effectiveDisplayStrength,
                    ),
                  ],
                ),
              ),

              // Bottom spacing - flexible to push content up if needed
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

  @override
  Widget build(BuildContext context) {
    // Watch the device list state for loading indicators
    final deviceListState = ref.watch(deviceListNotifierProvider);
    final isLoadingBattery =
        deviceListState.isLoading || deviceListState.isRefreshing;

    // Priority 1: Try to get device from activeDeviceListProvider (has battery info)
    final activeDevicesAsync = ref.watch(activeDeviceListProvider);

    return activeDevicesAsync.when(
      data: (activeDevices) {
        print(
          '🔋 Checking activeDeviceListProvider: ${activeDevices.length} devices',
        );

        final activeDevice =
            activeDevices
                .where((d) => d.deviceId == widget.deviceId)
                .firstOrNull;
        if (activeDevice != null) {
          print(
            '🔋 Found device in activeDeviceListProvider: ${activeDevice.deviceId}',
          );
          print(
            '🔋 Device battery: ${activeDevice.battery}, strength: ${activeDevice.deviceStrength}',
          );
          return _buildDeviceContent(
            deviceId: activeDevice.deviceId,
            currentStrength: activeDevice.deviceStrength,
            batteryLevel: activeDevice.battery, // ✅ Use real battery from API
            isNewlyPaired: false,
            isLoadingBattery: isLoadingBattery,
          );
        }

        // Priority 2: Fallback to userDeviceListProvider
        print('🔋 Device not in active list, checking userDeviceListProvider');
        final userDevicesAsync = ref.watch(userDeviceListProvider);

        return userDevicesAsync.when(
          data: (userDevices) {
            print(
              '🔋 userDeviceListProvider returned ${userDevices.length} devices',
            );

            final userDevice =
                userDevices
                    .where((d) => d.deviceId == widget.deviceId)
                    .firstOrNull;
            if (userDevice != null) {
              print(
                '🔋 Found device in userDeviceListProvider: ${userDevice.deviceId}',
              );
              return _buildDeviceContent(
                deviceId: userDevice.deviceId,
                currentStrength: userDevice.deviceStrength,
                batteryLevel:
                    widget
                        .batteryPercentage, // Use widget default (user devices don't have battery info)
                isNewlyPaired: false,
                isLoadingBattery: isLoadingBattery,
              );
            }

            // Device not found anywhere
            print('🔋 ❌ Device not found in any provider');
            return _buildNotFoundError(userDevices, activeDevices);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            print('🔋 ❌ userDeviceListProvider error: $error');
            return _buildErrorWidget(error);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        print('🔋 ❌ activeDeviceListProvider error: $error');

        // If active devices fail, try user devices as fallback
        final userDevicesAsync = ref.watch(userDeviceListProvider);
        return userDevicesAsync.when(
          data: (userDevices) {
            final userDevice =
                userDevices
                    .where((d) => d.deviceId == widget.deviceId)
                    .firstOrNull;
            if (userDevice != null) {
              return _buildDeviceContent(
                deviceId: userDevice.deviceId,
                currentStrength: userDevice.deviceStrength,
                batteryLevel: widget.batteryPercentage,
                isNewlyPaired: false,
                isLoadingBattery: isLoadingBattery,
              );
            }
            return _buildErrorWidget(error);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (userError, userStack) => _buildErrorWidget(error),
        );
      },
    );
  }

  Widget _buildNotFoundError(
    List<dynamic> userDevices,
    List<dynamic> activeDevices,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Device not found: ${widget.deviceId}'),
          SizedBox(height: 8),
          Text(
            'Available user devices: ${userDevices.map((d) => d.deviceId).join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Available active devices: ${activeDevices.map((d) => d.deviceId).join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userDeviceListProvider);
              ref.invalidate(activeDeviceListProvider);
              _loadActiveDevicesData();
            },
            child: Text('Refresh'),
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
          Text('Error: $error'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userDeviceListProvider);
              ref.invalidate(activeDeviceListProvider);
              _loadActiveDevicesData();
            },
            child: Text('Retry'),
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
