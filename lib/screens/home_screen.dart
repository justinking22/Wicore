// lib/screens/home_screen.dart - UPDATED WITH DEVICE/ACTIVE ENDPOINT LOGIC
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
  bool _isCheckingActiveDevice = true;
  String? _activeDeviceId;

  @override
  void initState() {
    super.initState();
    // Check for active device on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveDeviceStatus();
    });
  }

  // ✅ NEW: Check device/active endpoint first
  Future<void> _checkActiveDeviceStatus() async {
    print('🏠 === CHECKING ACTIVE DEVICE STATUS ===');

    setState(() {
      _isCheckingActiveDevice = true;
    });

    try {
      // Clear any cached data first
      ref.invalidate(activeDeviceProvider);

      // Check the device/active endpoint
      final activeDevice = await ref.read(activeDeviceProvider.future);

      if (activeDevice != null && activeDevice.safeDeviceId.isNotEmpty) {
        // Active device found - show device details
        print('🏠 ✅ Active device found: ${activeDevice.safeDeviceId}');
        setState(() {
          _activeDeviceId = activeDevice.safeDeviceId;
          _showDeviceDetails = true;
          _showQRScanner = false;
          _isCheckingActiveDevice = false;
        });
      } else {
        // No active device - show QR scanner after home content
        print('🏠 ❌ No active device found - will show QR scanner');
        setState(() {
          _activeDeviceId = null;
          _showDeviceDetails = false;
          _showQRScanner = false;
          _isCheckingActiveDevice = false;
        });
      }
    } catch (error) {
      print('🏠 ❌ Error checking active device: $error');
      // On error, assume no active device
      setState(() {
        _activeDeviceId = null;
        _showDeviceDetails = false;
        _showQRScanner = false;
        _isCheckingActiveDevice = false;
      });
    }
  }

  void _handleQRScanned(String qrData) async {
    print('🏠 _handleQRScanned called with: $qrData');

    // After QR scanning, check if device/active returns data
    await _recheckActiveDeviceAfterPairing();
  }

  // ✅ NEW: Recheck active device after pairing
  Future<void> _recheckActiveDeviceAfterPairing() async {
    print('🏠 === RECHECKING ACTIVE DEVICE AFTER PAIRING ===');

    try {
      // Wait a moment for the pairing to complete
      await Future.delayed(Duration(milliseconds: 1000));

      // Clear cache and check device/active again
      ref.invalidate(activeDeviceProvider);
      final activeDevice = await ref.read(activeDeviceProvider.future);

      if (activeDevice != null && activeDevice.safeDeviceId.isNotEmpty) {
        // Device is now active - show device details
        print('🏠 ✅ Device is now active: ${activeDevice.safeDeviceId}');

        setState(() {
          _activeDeviceId = activeDevice.safeDeviceId;
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
      } else {
        // Device still not active - show turn on dialog
        print('🏠 ❌ Device still not active after pairing');
        _showDeviceTurnOnDialog();
      }
    } catch (error) {
      print('🏠 ❌ Error rechecking active device: $error');
      _showDeviceTurnOnDialog();
    }
  }

  // ✅ NEW: Show device turn on dialog and return to QR scanner
  void _showDeviceTurnOnDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            '기기를 켜주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              '페어링된 기기가 꺼져있거나 연결되지 않았습니다.\n기기를 켜고 다시 스캔해주세요.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                _returnToQRScanner();
              },
              child: Text(
                '확인',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ NEW: Return to QR scanner
  void _returnToQRScanner() {
    setState(() {
      _showDeviceDetails = false;
      _showQRScanner = true;
    });
  }

  void _navigateToDeviceDetails() {
    if (_activeDeviceId != null) {
      setState(() {
        _showDeviceDetails = true;
        _showQRScanner = false;
      });
    } else {
      print('🏠 ❌ No active device ID found, cannot navigate to details');
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

    // Always recheck active device before showing QR scanner
    await _checkActiveDeviceStatus();

    // If still no active device, show QR scanner
    if (_activeDeviceId == null) {
      print('🏠 No active device, showing QR scanner');
      setState(() {
        _showQRScanner = true;
      });
    }
  }

  // ✅ ENHANCED: Comprehensive disconnect/unpair method
  Future<void> _disconnectDevice() async {
    print('🏠 _disconnectDevice called');

    if (_activeDeviceId?.trim().isNotEmpty == true) {
      // Show confirmation dialog first
      final confirmed = await _showDisconnectConfirmation(_activeDeviceId!);
      if (!confirmed) return;

      // Show loading state
      _showDisconnectingDialog();

      try {
        print('🏠 Starting device unpair process for: $_activeDeviceId');

        // Call the unpair method from device notifier
        final success = await ref
            .read(deviceNotifierProvider.notifier)
            .unpairDevice(_activeDeviceId!.trim());

        // Hide loading dialog
        Navigator.of(context).pop();

        if (success) {
          print('🏠 ✅ Device unpaired successfully');

          // Clear state after successful unpair
          ref.read(deviceNotifierProvider.notifier).clearState();

          setState(() {
            _activeDeviceId = null;
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
        _activeDeviceId = null;
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
      _activeDeviceId = null;
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
  }

  // ✅ NEW: Loading screen while checking active device
  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
            SizedBox(height: 16),
            Text(
              '기기 상태를 확인하고 있습니다...',
              style: TextStyles.kMedium.copyWith(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
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
        // Trigger recheck instead of direct navigation
        _recheckActiveDeviceAfterPairing();
      },
    );
  }

  Widget _buildDeviceDetailsContent() {
    print('🏠 _buildDeviceDetailsContent called');
    print('  - _activeDeviceId: $_activeDeviceId');

    if (_activeDeviceId == null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('활성 기기를 찾을 수 없습니다'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _checkActiveDeviceStatus();
                },
                child: Text('다시 확인'),
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
          onTrailingPressed: _disconnectDevice,
          showTrailingButton: true,
          trailingButtonColor: Colors.red,
          showBackButton: false,
          onBackPressed: _backFromDeviceDetails,
        ),
        Expanded(
          child: DeviceDetailsWidget(
            deviceId: _activeDeviceId!,
            onDisconnect: _disconnectDevice,
            onUnpaired: () {
              // ✅ Additional callback when unpaired from within widget
              setState(() {
                _activeDeviceId = null;
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
    print('🏠 BUILD called:');
    print('  - _isCheckingActiveDevice: $_isCheckingActiveDevice');
    print('  - _activeDeviceId: $_activeDeviceId');
    print('  - _showQRScanner: $_showQRScanner');
    print('  - _showDeviceDetails: $_showDeviceDetails');

    // Show loading screen while checking active device
    if (_isCheckingActiveDevice) {
      return Scaffold(body: _buildLoadingScreen());
    }

    String screenToShow = 'UNKNOWN';
    Widget screenWidget;

    if (_showQRScanner) {
      screenToShow = 'QR_SCANNER';
      screenWidget = _buildQRScannerContent();
    } else if (_showDeviceDetails && _activeDeviceId != null) {
      screenToShow = 'DEVICE_DETAILS';
      screenWidget = _buildDeviceDetailsContent();
    } else {
      screenToShow = 'HOME_CONTENT';
      screenWidget = _buildHomeContent();
    }

    print('  - Final screen: $screenToShow');

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: screenWidget,
      ),
    );
  }
}
