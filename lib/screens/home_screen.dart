// lib/screens/home_screen.dart - UPDATED WITH UNPAIR INTEGRATION
import 'package:Wicore/screens/qr_acanner_screen.dart';
import 'package:Wicore/widgets/device_details_widget.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/modals/qr_scan_info_modal_bottom_sheet.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wicore/providers/device_provider.dart';
import 'package:Wicore/states/device_state.dart';
import 'dart:io';
import 'dart:math' as math;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showQRScanner = false;
  bool _showDeviceDetails = false;

  @override
  void initState() {
    super.initState();
    // Check for paired device on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingDevice();
      _debugDeviceState();
    });
  }

  void _checkExistingDevice() {
    String? deviceId;

    // First try paired device provider
    final pairedDevice = ref.read(deviceDataProvider);
    if (pairedDevice != null) {
      deviceId = pairedDevice.deviceId;
      print('🔧 Using paired device ID: $deviceId');
    } else {
      // Try device state
      final deviceState = ref.read(deviceNotifierProvider);
      if (deviceState.pairedDevice != null) {
        deviceId = deviceState.pairedDevice!.deviceId;
        print('🔧 Using device from state: $deviceId');
      }
    }

    print('🏠 Checking for existing paired device');
    print('  - deviceId: $deviceId');

    if (deviceId != null) {
      print('🏠 Found existing paired device, showing device details');
      setState(() {
        _showDeviceDetails = true;
        _showQRScanner = false;
      });
    }
  }

  void _debugDeviceState() {
    final deviceState = ref.read(deviceNotifierProvider);
    final pairedDevice = ref.read(deviceDataProvider);
    print('🏠 HOME SCREEN DEBUG - Initial state:');
    print(
      '  - deviceState.pairedDevice: ${deviceState.pairedDevice?.deviceId}',
    );
    print('  - pairedDevice: ${pairedDevice?.deviceId}');
    print('  - isLoading: ${deviceState.isLoading}');
    print('  - error: ${deviceState.error}');
    print('  - _showQRScanner: $_showQRScanner');
    print('  - _showDeviceDetails: $_showDeviceDetails');
  }

  void _handleQRScanned(String qrData) {
    print('🏠 _handleQRScanned called with: $qrData');

    // Always navigate to device details when QR is successfully processed
    setState(() {
      _showQRScanner = false;
      _showDeviceDetails = true;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('기기 연결 완료'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDeviceDetails() {
    final deviceState = ref.read(deviceNotifierProvider);
    final pairedDevice = ref.read(deviceDataProvider);
    print('🏠 _navigateToDeviceDetails called');
    print(
      '  - deviceState.pairedDevice: ${deviceState.pairedDevice?.deviceId}',
    );
    print('  - pairedDevice: ${pairedDevice?.deviceId}');

    if (deviceState.pairedDevice != null || pairedDevice != null) {
      setState(() {
        _showDeviceDetails = true;
        _showQRScanner = false;
      });
    } else {
      print('🏠 ❌ No paired device found, cannot navigate to details');
    }
  }

  void _backFromDeviceDetails() {
    print('🏠 _backFromDeviceDetails called');
    setState(() {
      _showDeviceDetails = false;
    });
  }

  void _startQRScanning() async {
    print('🏠 _startQRScanning called');

    // Check if device is already paired before showing QR scanner
    final deviceState = ref.read(deviceNotifierProvider);
    final pairedDevice = ref.read(deviceDataProvider);
    print('🏠 Device state check:');
    print(
      '  - deviceState.pairedDevice: ${deviceState.pairedDevice?.deviceId}',
    );
    print('  - pairedDevice: ${pairedDevice?.deviceId}');

    if (deviceState.pairedDevice != null || pairedDevice != null) {
      print('🏠 Device already paired, going to device details');
      setState(() {
        _showDeviceDetails = true;
        _showQRScanner = false;
      });
      return;
    }

    print('🏠 No device paired, showing QR scanner');
    setState(() {
      _showQRScanner = true;
    });
  }

  // ✅ ENHANCED: Comprehensive disconnect/unpair method
  Future<void> _disconnectDevice() async {
    print('🏠 _disconnectDevice called');

    final beforeDeviceState = ref.read(deviceNotifierProvider);
    final beforePairedDevice = ref.read(deviceDataProvider);
    print('🏠 Before disconnect:');
    print(
      '  - deviceState.pairedDevice: ${beforeDeviceState.pairedDevice?.deviceId}',
    );
    print('  - pairedDevice: ${beforePairedDevice?.deviceId}');

    // Get device ID before clearing state
    String? deviceId =
        beforeDeviceState.pairedDevice?.deviceId ??
        beforePairedDevice?.deviceId;

    if (deviceId?.trim().isNotEmpty == true) {
      // Show confirmation dialog first
      final confirmed = await _showDisconnectConfirmation(deviceId!);
      if (!confirmed) return;

      // Show loading state
      _showDisconnectingDialog();

      try {
        print('🏠 Starting device unpair process for: $deviceId');

        // Call the unpair method from device notifier
        final success = await ref
            .read(deviceNotifierProvider.notifier)
            .unpairDevice(deviceId.trim());

        // Hide loading dialog
        Navigator.of(context).pop();

        if (success) {
          print('🏠 ✅ Device unpaired successfully');

          // Clear state after successful unpair
          ref.read(deviceNotifierProvider.notifier).clearState();

          setState(() {
            _showDeviceDetails = false;
            _showQRScanner = false;
          });

          // Invalidate providers
          ref.invalidate(allDevicesProvider);
          ref.invalidate(activeDeviceProvider);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('기기 연결이 성공적으로 해제되었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          print('🏠 ❌ Device unpair failed');

          final errorMessage =
              ref.read(deviceNotifierProvider).error ?? '기기 연결 해제에 실패했습니다';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (error) {
        print('🏠 ❌ Error during device unpair: $error');

        // Hide loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기기 연결 해제 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      print('🏠 No valid device ID found, performing simple state clear');

      // Simple state clear if no device ID
      ref.read(deviceNotifierProvider.notifier).clearState();

      setState(() {
        _showDeviceDetails = false;
      });

      ref.invalidate(allDevicesProvider);
      ref.invalidate(activeDeviceProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기기 연결이 해제되었습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Debug state after disconnect
    Future.delayed(Duration(milliseconds: 100), () {
      final afterDeviceState = ref.read(deviceNotifierProvider);
      final afterPairedDevice = ref.read(deviceDataProvider);
      print('🏠 After disconnect:');
      print(
        '  - deviceState.pairedDevice: ${afterDeviceState.pairedDevice?.deviceId}',
      );
      print('  - pairedDevice: ${afterPairedDevice?.deviceId}');
    });
  }

  // ✅ NEW: Show disconnect confirmation dialog
  Future<bool> _showDisconnectConfirmation(String deviceId) async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(
                '기기 연결 해제',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              content: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Text(
                      '다음 기기와의 연결을 해제하시겠습니까?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        deviceId,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  isDestructiveAction: true,
                  child: Text(
                    '연결 해제',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ✅ NEW: Show disconnecting progress dialog
  void _showDisconnectingDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(radius: 20),
                SizedBox(height: 16),
                Text(
                  '기기 연결을 해제하는 중...',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBackFromQRScanner() {
    print('🏠 _onBackFromQRScanner called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QRConnectionModal(),
    );
  }

  void _forceCleanState() {
    print('🏠 🗑️ FORCE CLEARING ALL STATE');

    ref.read(deviceNotifierProvider.notifier).clearState();

    setState(() {
      _showQRScanner = false;
      _showDeviceDetails = false;
    });

    ref.invalidate(deviceNotifierProvider);
    ref.invalidate(allDevicesProvider);
    ref.invalidate(activeDeviceProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('모든 상태가 초기화되었습니다.'),
        backgroundColor: Colors.red,
      ),
    );

    Future.delayed(Duration(milliseconds: 100), () {
      final afterDeviceState = ref.read(deviceNotifierProvider);
      final afterPairedDevice = ref.read(deviceDataProvider);
      print('🏠 After force clear:');
      print(
        '  - deviceState.pairedDevice: ${afterDeviceState.pairedDevice?.deviceId}',
      );
      print('  - pairedDevice: ${afterPairedDevice?.deviceId}');
    });
  }

  Widget _buildHomeContent() {
    final deviceState = ref.watch(deviceNotifierProvider);
    final pairedDevice = ref.watch(deviceDataProvider);

    print('🏠 _buildHomeContent called');
    print(
      '  - deviceState.pairedDevice: ${deviceState.pairedDevice?.deviceId}',
    );
    print('  - pairedDevice: ${pairedDevice?.deviceId}');
    print('  - _showDeviceDetails: $_showDeviceDetails');

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        final safePadding = MediaQuery.of(context).padding;

        final bottomPadding =
            math.max(safePadding.bottom + 24, 60.0).toDouble();
        final horizontalPadding = 24.0;

        final titleFontSize = 28.0;
        final bodyFontSize = 16.0;

        return Container(
          color: Colors.white,
          height: availableHeight,
          child: Padding(
            padding: EdgeInsets.only(
              top: safePadding.top + 60,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기기를 연결하려면\n접근 허용이 필요해요',
                      style: TextStyles.kSemiBold.copyWith(
                        fontSize: titleFontSize,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '블루투스(기기연결)와 카메라(QR촬영)가\n필요하며 그 외에는 사용되지 않습니다.',
                      style: TextStyles.kMedium.copyWith(
                        color: CustomColors.lightGray,
                        fontSize: bodyFontSize,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    RichText(
                      text: TextSpan(
                        style: TextStyles.kMedium.copyWith(
                          fontSize: bodyFontSize,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: '알림창의 ',
                            style: TextStyles.kMedium.copyWith(
                              color: Colors.red,
                              fontSize: bodyFontSize,
                            ),
                          ),
                          TextSpan(
                            text: '【허용】',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
                            ),
                          ),
                          TextSpan(
                            text: ' 또는 ',
                            style: TextStyles.kMedium.copyWith(
                              color: Colors.red,
                              fontSize: bodyFontSize,
                            ),
                          ),
                          TextSpan(
                            text: '[확인]',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
                            ),
                          ),
                          TextSpan(
                            text: ' 을 눌러주세요.',
                            style: TextStyles.kMedium.copyWith(
                              color: Colors.red,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _startQRScanning,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '확인했습니다',
                        style: TextStyles.kSemiBold.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQRScannerContent() {
    print('🏠 _buildQRScannerContent called');

    return QRScannerWidget(
      onQRScanned: _handleQRScanned,
      onBackPressed: _onBackFromQRScanner,
      onShowDeviceDetails: () {
        print('🏠 QR Scanner callback - onShowDeviceDetails called');
        setState(() {
          _showQRScanner = false;
          _showDeviceDetails = true;
        });
      },
    );
  }

  Widget _buildDeviceDetailsContent() {
    String? deviceId;

    final deviceState = ref.read(deviceNotifierProvider);
    if (deviceState.pairedDevice != null) {
      deviceId = deviceState.pairedDevice!.deviceId;
      print('🔧 Using device from state: $deviceId');
    }

    if (deviceId == null) {
      final pairedDevice = ref.read(deviceDataProvider);
      if (pairedDevice != null) {
        deviceId = pairedDevice.deviceId;
        print('🔧 Using paired device ID: $deviceId');
      }
    }

    print('🏠 _buildDeviceDetailsContent called');
    print('  - deviceId: $deviceId');

    if (deviceId == null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('기기 정보를 찾을 수 없습니다'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showDeviceDetails = false;
                  });
                },
                child: Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ✅ ENHANCED: CustomAppBar with proper unpair integration
        CustomAppBar(
          title: 'wicore',
          trailingButtonText: '연결 해제',
          onTrailingPressed:
              _disconnectDevice, // ✅ This now properly unpairs the device
          showTrailingButton: true,
          trailingButtonColor: Colors.red,
          showBackButton: false,
          onBackPressed: _backFromDeviceDetails,
        ),
        Expanded(
          child: DeviceDetailsWidget(
            deviceId: deviceId,
            onDisconnect:
                _disconnectDevice, // ✅ Pass the enhanced disconnect method
            onUnpaired: () {
              // ✅ Additional callback when unpaired from within widget
              setState(() {
                _showDeviceDetails = false;
                _showQRScanner = false;
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceNotifierProvider);
    final pairedDevice = ref.watch(deviceDataProvider);

    bool isDeviceConnected =
        deviceState.pairedDevice != null || pairedDevice != null;

    print('🏠 BUILD called:');
    print(
      '  - deviceState.pairedDevice: ${deviceState.pairedDevice?.deviceId}',
    );
    print('  - pairedDevice: ${pairedDevice?.deviceId}');
    print('  - isDeviceConnected: $isDeviceConnected');
    print('  - _showQRScanner: $_showQRScanner');
    print('  - _showDeviceDetails: $_showDeviceDetails');

    String screenToShow = 'UNKNOWN';
    if (_showQRScanner) {
      screenToShow = 'QR_SCANNER';
    } else if (isDeviceConnected || _showDeviceDetails) {
      screenToShow = 'DEVICE_DETAILS';
    } else {
      screenToShow = 'HOME_CONTENT';
    }

    print('  - Final screen: $screenToShow');

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child:
            _showQRScanner
                ? _buildQRScannerContent()
                : (isDeviceConnected || _showDeviceDetails)
                ? _buildDeviceDetailsContent()
                : _buildHomeContent(),
      ),
    );
  }
}
