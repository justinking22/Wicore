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
    // Get device ID from multiple sources
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

  // SIMPLIFIED: Just navigate to QR scanner, let mobile_scanner handle permissions
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
      // Device already paired, go directly to device details
      setState(() {
        _showDeviceDetails = true;
        _showQRScanner = false;
      });
      return;
    }

    print('🏠 No device paired, showing QR scanner');
    // No device paired, show QR scanner - mobile_scanner will handle permissions
    setState(() {
      _showQRScanner = true;
    });
  }

  void _disconnectDevice() {
    print('🏠 _disconnectDevice called');

    final beforeDeviceState = ref.read(deviceNotifierProvider);
    final beforePairedDevice = ref.read(deviceDataProvider);
    print('🏠 Before disconnect:');
    print(
      '  - deviceState.pairedDevice: ${beforeDeviceState.pairedDevice?.deviceId}',
    );
    print('  - pairedDevice: ${beforePairedDevice?.deviceId}');

    ref.read(deviceNotifierProvider.notifier).clearState();

    setState(() {
      _showDeviceDetails = false;
    });

    // Check state after clearing
    Future.delayed(Duration(milliseconds: 100), () {
      final afterDeviceState = ref.read(deviceNotifierProvider);
      final afterPairedDevice = ref.read(deviceDataProvider);
      print('🏠 After disconnect:');
      print(
        '  - deviceState.pairedDevice: ${afterDeviceState.pairedDevice?.deviceId}',
      );
      print('  - pairedDevice: ${afterPairedDevice?.deviceId}');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('기기 연결이 해제되었습니다.'),
        backgroundColor: Colors.orange,
      ),
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

  // DEBUG: Add force clear method
  void _forceCleanState() {
    print('🏠 🗑️ FORCE CLEARING ALL STATE');

    // Clear device state
    ref.read(deviceNotifierProvider.notifier).clearState();

    // Clear local UI state
    setState(() {
      _showQRScanner = false;
      _showDeviceDetails = false;
    });

    // Invalidate providers
    ref.invalidate(deviceNotifierProvider);
    ref.invalidate(userDeviceListProvider);
    ref.invalidate(activeDeviceListProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('모든 상태가 초기화되었습니다.'),
        backgroundColor: Colors.red,
      ),
    );

    // Check state after force clear
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

        // Calculate responsive dimensions
        final topPadding =
            math.max(safePadding.top + 40, availableHeight * 0.15).toDouble();
        final bottomPadding =
            math.max(safePadding.bottom + 24, 60.0).toDouble();
        final horizontalPadding =
            math.max(24.0, availableWidth * 0.06).toDouble();

        // Calculate available space for content
        final contentHeight =
            availableHeight -
            topPadding -
            bottomPadding -
            80; // 80 for button + spacing

        // Responsive font sizes
        final titleFontSize =
            math.min(32, math.max(24, availableWidth * 0.08)).toDouble();
        final bodyFontSize =
            math.min(16, math.max(14, availableWidth * 0.04)).toDouble();

        return Container(
          color: Colors.white,
          height: availableHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPadding),

                // Main content area - flexible
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '기기를 연결하려면\n접근 허용이 필요해요',
                        style: TextStyles.kSemiBold.copyWith(
                          fontSize: titleFontSize,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(
                        height:
                            math.max(20, availableHeight * 0.025).toDouble(),
                      ),

                      Text(
                        '블루투스(기기연결)와 카메라(QR촬영)가\n필요하며 그 외에는 사용되지 않습니다.',
                        style: TextStyles.kMedium.copyWith(
                          color: CustomColors.lightGray,
                          fontSize: bodyFontSize,
                        ),
                      ),
                      SizedBox(
                        height:
                            math.max(12, availableHeight * 0.015).toDouble(),
                      ),

                      RichText(
                        text: TextSpan(
                          style: TextStyles.kMedium.copyWith(
                            fontSize: bodyFontSize,
                          ),
                          children: [
                            TextSpan(
                              text: Platform.isIOS ? '설정에서 ' : '알림창의 ',
                              style: TextStyles.kMedium.copyWith(
                                color: Colors.red,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            TextSpan(
                              text: Platform.isIOS ? '【권한 허용】' : '【허용】',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            if (!Platform.isIOS) ...[
                              TextSpan(
                                text: ' 또는 ',
                                style: TextStyles.kMedium.copyWith(
                                  color: Colors.red,
                                  fontSize: bodyFontSize,
                                ),
                              ),
                              TextSpan(
                                text: '【허가】',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: bodyFontSize,
                                ),
                              ),
                            ],
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
                ),

                // Bottom button - fixed position
                Container(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: SizedBox(
                    width: double.infinity,
                    height: math.max(56, availableHeight * 0.07).toDouble(),
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
                        style: TextStyles.kSemiBold.copyWith(
                          fontSize:
                              math
                                  .min(16, math.max(14, availableWidth * 0.04))
                                  .toDouble(),
                        ),
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
    // Get device ID from multiple sources
    String? deviceId;

    // First try device state
    final deviceState = ref.read(deviceNotifierProvider);
    if (deviceState.pairedDevice != null) {
      deviceId = deviceState.pairedDevice!.deviceId;
      print('🔧 Using device from state: $deviceId');
    }

    // Fall back to paired device provider
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
      // Fallback if no device ID is available
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
            deviceId: deviceId,
            onDisconnect: _disconnectDevice,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceNotifierProvider);
    final pairedDevice = ref.watch(deviceDataProvider);

    // Determine if device is connected from multiple sources
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
