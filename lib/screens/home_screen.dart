import 'package:Wicore/screens/qr_acanner_screen.dart';
import 'package:Wicore/widgets/device_details_widget.dart'; // Add this import
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDeviceConnected = false;
  bool _showQRScanner = false;
  bool _showDeviceDetails = false;
  String _deviceName = "";
  String _scannedDeviceId = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForQRResult();
    });
  }

  void _checkForQRResult() {
    final GoRouterState state = GoRouterState.of(context);
    final String? qrResult = state.uri.queryParameters['qrResult'];

    if (qrResult != null) {
      _handleQRScanned(qrResult);
      context.go('/home');
    }
  }

  void _handleQRScanned(String qrData) {
    setState(() {
      _showQRScanner = false;
      _showDeviceDetails = true;
      _isDeviceConnected = true;
      _deviceName = "Samsung Galaxy S24";
      _scannedDeviceId = qrData;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR 코드 스캔 완료: $qrData'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Add this method to navigate to device details
  void _navigateToDeviceDetails() {
    if (_isDeviceConnected && _scannedDeviceId.isNotEmpty) {
      setState(() {
        _showDeviceDetails = true;
      });
    }
  }

  // Add method to go back from device details
  void _backFromDeviceDetails() {
    setState(() {
      _showDeviceDetails = false;
    });
  }

  Future<void> _requestCameraPermission() async {
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.camera,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.location,
        ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 권한이 허용되었습니다. QR 스캔을 시작합니다.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _showQRScanner = true;
      });
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black54, width: 2),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 24,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'WICORE에서 근처 기기를 찾아 연결하고 기기 간 상대적 위치를 파악하도록 허용하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          openAppSettings();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '허용',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '허용 안 함',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _disconnectDevice() {
    setState(() {
      _isDeviceConnected = false;
      _showDeviceDetails = false;
      _deviceName = "";
      _scannedDeviceId = "";
    });
  }

  void _onBackFromQRScanner() {
    setState(() {
      _showQRScanner = false;
    });
  }

  Widget _buildHomeContent() {
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
                if (!_isDeviceConnected) ...[
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
                          text: '알림창의 ',
                          style: TextStyles.kMedium.copyWith(color: Colors.red),
                        ),
                        TextSpan(
                          text: '【허용】',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        TextSpan(
                          text: ' 을 눌러주세요.',
                          style: TextStyles.kMedium.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green[600],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '기기가 연결되었습니다!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '연결된 기기: $_deviceName',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '기기 ID: $_scannedDeviceId',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _navigateToDeviceDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[100],
                                  foregroundColor: Colors.blue[700],
                                  elevation: 0,
                                ),
                                child: const Text('기기 상세보기'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _disconnectDevice,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[100],
                                  foregroundColor: Colors.red[700],
                                  elevation: 0,
                                ),
                                child: const Text('연결 해제'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_isDeviceConnected)
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
    return QRScannerWidget(
      onQRScanned: _handleQRScanned,
      onBackPressed: _onBackFromQRScanner,
    );
  }

  Widget _buildDeviceDetailsContent() {
    return Column(
      children: [
        CustomAppBar(
          title: 'wicore',
          trailingButtonText: '연결 해제',
          onTrailingPressed: _disconnectDevice,
          showTrailingButton: true,
          trailingButtonColor: Colors.red,
          showBackButton: false,
        ),
        // Device details widget
        Expanded(
          child: DeviceDetailsWidget(
            deviceId: _scannedDeviceId,
            onDisconnect: _disconnectDevice,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child:
            _showQRScanner
                ? _buildQRScannerContent()
                : _showDeviceDetails
                ? _buildDeviceDetailsContent()
                : _buildHomeContent(),
      ),
    );
  }
}
