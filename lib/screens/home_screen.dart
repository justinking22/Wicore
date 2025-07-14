import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isChecked = false;
  bool _isDeviceConnected = false;
  String _deviceName = "";

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
      _simulateQRScan();
    } else {
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

  void _simulateQRScan() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isDeviceConnected = true;
          _deviceName = "Samsung Galaxy S24";
        });
      }
    });
  }

  void _disconnectDevice() {
    setState(() {
      _isDeviceConnected = false;
      _deviceName = "";
      _isChecked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          // Main content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isDeviceConnected) ...[
                    const Text(
                      '기기를 연결하려면\n접근 허용이 필요해요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      '블루투스(기기연결)와 카메라(QR촬영)가\n필요하며 그 외에는 사용되지 않습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: '일반창의 '),
                          TextSpan(
                            text: '【허용】',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' 또는 '),
                          TextSpan(
                            text: '【허가】',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' 을 눌러주세요.'),
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
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _disconnectDevice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              foregroundColor: Colors.red[700],
                              elevation: 0,
                            ),
                            child: const Text('연결 해제'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom section with checkbox and button
          if (!_isDeviceConnected)
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: _isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              _isChecked = value ?? false;
                            });

                            if (_isChecked) {
                              _requestCameraPermission();
                            }
                          },
                          activeColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '확인했습니다',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isChecked ? _requestCameraPermission : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isChecked ? Colors.blue : Colors.grey[300],
                        foregroundColor:
                            _isChecked ? Colors.white : Colors.grey[600],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '확인했습니다',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
