import 'package:Wicore/screens/qr_acanner_screen.dart';
import 'package:Wicore/widgets/device_details_widget.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/modals/qr_scan_info_modal_bottom_sheet.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wicore/providers/device_provider.dart';
import 'package:Wicore/states/device_state.dart';
import 'dart:io';

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
    // Debug device state on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugDeviceState();
    });
  }

  void _debugDeviceState() {
    final deviceState = ref.read(deviceNotifierProvider);
    print('🏠 HOME SCREEN DEBUG - Initial state:');
    print('  - pairedDevice: ${deviceState.pairedDevice?.deviceId}');
    print('  - isLoading: ${deviceState.isLoading}');
    print('  - error: ${deviceState.error}');
    print('  - _showQRScanner: $_showQRScanner');
    print('  - _showDeviceDetails: $_showDeviceDetails');
  }

  void _handleQRScanned(String qrData) {
    print('🏠 _handleQRScanned called with: $qrData');
    setState(() {
      _showQRScanner = false;
      _showDeviceDetails = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR 코드 스캔 완료: $qrData'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToDeviceDetails() {
    final deviceState = ref.read(deviceNotifierProvider);
    print('🏠 _navigateToDeviceDetails called');
    print('  - pairedDevice: ${deviceState.pairedDevice?.deviceId}');

    if (deviceState.pairedDevice != null) {
      setState(() {
        _showDeviceDetails = true;
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

  Future<void> _requestCameraPermission() async {
    print('🏠 _requestCameraPermission called');

    // Check if device is already paired before requesting permissions
    final deviceState = ref.read(deviceNotifierProvider);
    print('🏠 Device state check:');
    print('  - pairedDevice: ${deviceState.pairedDevice?.deviceId}');

    if (deviceState.pairedDevice != null) {
      print('🏠 Device already paired, going to device details');
      // Device already paired, go directly to device details
      setState(() {
        _showDeviceDetails = true;
      });
      return;
    }

    print('🏠 No device paired, proceeding with permissions');
    // No device paired, proceed with permissions and QR scanner
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    print('🏠 _requestPermissions called');

    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.camera,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.location,
        ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    print('🏠 Permissions result: allGranted = $allGranted');

    if (allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 권한이 허용되었습니다. QR 스캔을 시작합니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // Double-check device state before showing QR scanner
      final deviceState = ref.read(deviceNotifierProvider);
      print('🏠 Double-check before QR scanner:');
      print('  - pairedDevice: ${deviceState.pairedDevice?.deviceId}');

      if (deviceState.pairedDevice != null) {
        print(
          '🏠 Device was paired during permissions, going to device details',
        );
        // Device was paired while requesting permissions, go to device details
        setState(() {
          _showDeviceDetails = true;
        });
      } else {
        print('🏠 No device paired, showing QR scanner');
        // No device paired, show QR scanner
        setState(() {
          _showQRScanner = true;
        });
      }
    } else {
      _handlePermissionDenied(statuses);
    }
  }

  void _handlePermissionDenied(Map<Permission, PermissionStatus> statuses) {
    List<String> deniedPermissions = [];

    if (statuses[Permission.camera]?.isDenied == true) {
      deniedPermissions.add('카메라');
    }
    if (statuses[Permission.bluetoothConnect]?.isDenied == true) {
      deniedPermissions.add('블루투스 연결');
    }
    if (statuses[Permission.bluetoothScan]?.isDenied == true) {
      deniedPermissions.add('블루투스 스캔');
    }
    if (statuses[Permission.location]?.isDenied == true) {
      deniedPermissions.add('위치');
    }

    if (deniedPermissions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('다음 권한이 필요합니다: ${deniedPermissions.join(', ')}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    bool anyPermanentlyDenied = statuses.values.any(
      (status) => status.isPermanentlyDenied,
    );

    if (anyPermanentlyDenied) {
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    if (Platform.isIOS) {
      showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('권한 필요'),
            content: const Text(
              'WICORE에서 근처 기기를 찾아 연결하고 기기 간 상대적 위치를 파악하도록 허용하시겠습니까?\n\n설정에서 카메라, 블루투스, 위치 권한을 허용해주세요.',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('설정으로 이동'),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
              CupertinoDialogAction(
                child: const Text('취소'),
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text('권한 필요'),
              ],
            ),
            content: const Text(
              'WICORE에서 근처 기기를 찾아 연결하고 기기 간 상대적 위치를 파악하도록 허용하시겠습니까?\n\n설정에서 필요한 권한들을 허용해주세요.',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          );
        },
      );
    }
  }

  void _disconnectDevice() {
    print('🏠 _disconnectDevice called');

    final beforeState = ref.read(deviceNotifierProvider);
    print(
      '🏠 Before disconnect - pairedDevice: ${beforeState.pairedDevice?.deviceId}',
    );

    ref.read(deviceNotifierProvider.notifier).clearState();

    setState(() {
      _showDeviceDetails = false;
    });

    // Check state after clearing
    Future.delayed(Duration(milliseconds: 100), () {
      final afterState = ref.read(deviceNotifierProvider);
      print(
        '🏠 After disconnect - pairedDevice: ${afterState.pairedDevice?.deviceId}',
      );
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
      final afterState = ref.read(deviceNotifierProvider);
      print(
        '🏠 After force clear - pairedDevice: ${afterState.pairedDevice?.deviceId}',
      );
    });
  }

  Widget _buildHomeContent() {
    final deviceState = ref.watch(deviceNotifierProvider);

    print('🏠 _buildHomeContent called');
    print('  - pairedDevice: ${deviceState.pairedDevice?.deviceId}');
    print('  - _showDeviceDetails: $_showDeviceDetails');

    // This method now only shows when no device is connected
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 140),
                Text(
                  '기기를 연결하려면\n접근 허용이 필요해요',
                  style: TextStyles.kSemiBold.copyWith(
                    fontSize: 32,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '블루투스(기기연결)와 카메라(QR촬영)가\n필요하며 그 외에는 사용되지 않습니다.',
                  style: TextStyles.kMedium.copyWith(
                    color: CustomColors.lightGray,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyles.kMedium,
                    children: [
                      TextSpan(
                        text: Platform.isIOS ? '설정에서 ' : '알림창의 ',
                        style: TextStyles.kMedium.copyWith(color: Colors.red),
                      ),
                      TextSpan(
                        text: Platform.isIOS ? '【권한 허용】' : '【허용】',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!Platform.isIOS) ...[
                        TextSpan(
                          text: ' 또는 ',
                          style: TextStyles.kMedium.copyWith(color: Colors.red),
                        ),
                        TextSpan(
                          text: '【허가】',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      TextSpan(
                        text: ' 을 눌러주세요.',
                        style: TextStyles.kMedium.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _requestCameraPermission,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('확인했습니다', style: TextStyles.kSemiBold),
              ),
            ),
          ),
        ],
      ),
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
    final deviceState = ref.watch(deviceNotifierProvider);
    final scannedDeviceId = deviceState.pairedDevice?.deviceId ?? "";

    print('🏠 _buildDeviceDetailsContent called');
    print('  - scannedDeviceId: $scannedDeviceId');

    return Column(
      children: [
        CustomAppBar(
          title: 'wicore',
          trailingButtonText: '연결 해제',
          onTrailingPressed: _disconnectDevice,
          showTrailingButton: true,
          trailingButtonColor: Colors.red,
          showBackButton: true,
          onBackPressed: _backFromDeviceDetails,
        ),
        Expanded(
          child: DeviceDetailsWidget(
            deviceId: scannedDeviceId,
            onDisconnect: _disconnectDevice,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceNotifierProvider);
    final isDeviceConnected = deviceState.pairedDevice != null;

    print('🏠 BUILD called:');
    print('  - isDeviceConnected: $isDeviceConnected');
    print('  - _showQRScanner: $_showQRScanner');
    print('  - _showDeviceDetails: $_showDeviceDetails');
    print(
      '  - Final screen: ${_showQRScanner
          ? 'QR_SCANNER'
          : (isDeviceConnected || _showDeviceDetails)
          ? 'DEVICE_DETAILS'
          : 'HOME_CONTENT'}',
    );

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
