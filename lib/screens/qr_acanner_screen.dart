// lib/screens/qr_scanner_screen.dart - UPDATED
import 'package:Wicore/models/device_response_model.dart'
    show DeviceResponseData;
import 'package:Wicore/states/device_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/models/device_request_model.dart';
import 'package:Wicore/providers/device_provider.dart';
import 'dart:math' as math;

class QRScannerWidget extends ConsumerStatefulWidget {
  final Function(String)? onQRScanned;
  final VoidCallback? onBackPressed;
  final VoidCallback? onShowDeviceDetails;

  const QRScannerWidget({
    Key? key,
    this.onQRScanned,
    this.onBackPressed,
    this.onShowDeviceDetails,
  }) : super(key: key);

  @override
  ConsumerState<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends ConsumerState<QRScannerWidget>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  StreamSubscription<Object?>? _subscription;
  bool _isDisposed = false;
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();

    // Check for existing device immediately after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingPairedDevice();
    });
  }

  void _initializeController() {
    if (_isDisposed) return;

    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: false,
      torchEnabled: false,
      facing: CameraFacing.back,
      returnImage: false,
    );

    _subscription = controller!.barcodes.listen(_onDetect);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller!.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        unawaited(controller!.start());
        break;
      case AppLifecycleState.inactive:
        unawaited(controller!.stop());
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isDisposed || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;

      if (code != null &&
          code.isNotEmpty &&
          code != _lastScannedCode &&
          !_isProcessing) {
        _lastScannedCode = code;

        setState(() {
          _isProcessing = true;
        });

        await controller?.stop();

        print('📱 QR Code detected: $code');

        try {
          final deviceState = ref.read(deviceNotifierProvider);
          final pairedDevice = ref.read(deviceDataProvider);

          if (deviceState.pairedDevice != null || pairedDevice != null) {
            print('📱 Device already paired, navigating to details');
            _navigateToDeviceDetails();
            return;
          }

          // ✅ NEW: Check if device is active before pairing
          await _checkDeviceStatusAndPair(code);
        } catch (e) {
          print('📱 Error processing QR code: $e');
          _resetScanning();
        }
      }
    }
  }

  void _checkExistingPairedDevice() {
    final deviceState = ref.read(deviceNotifierProvider);
    final pairedDevice = ref.read(deviceDataProvider);

    if (deviceState.pairedDevice != null || pairedDevice != null) {
      String deviceId =
          deviceState.pairedDevice?.deviceId ?? pairedDevice?.deviceId ?? '';
      print('📱 Found existing paired device: $deviceId');
      _navigateToDeviceDetails();
    }
  }

  void _navigateToDeviceDetails() {
    controller?.stop();
    if (widget.onShowDeviceDetails != null) {
      widget.onShowDeviceDetails!();
    }
  }

  // ✅ NEW: Check device status before pairing
  Future<void> _checkDeviceStatusAndPair(String deviceId) async {
    print('📱 🔍 Checking device status for: $deviceId');

    try {
      // First, try to check if device is active by fetching active device data
      ref.invalidate(activeDeviceProvider);
      final activeDevice = await ref.read(activeDeviceProvider.future);

      print('📱 Active device response: ${activeDevice?.safeDeviceId}');

      // Check if the scanned device is the currently active device
      if (activeDevice != null && activeDevice.safeDeviceId == deviceId) {
        print('📱 ✅ Device is active, proceeding with pairing');
        await _processQRCode(deviceId);
      } else {
        print('📱 ❌ Device is not active or not found, showing turn on dialog');
        _showDeviceTurnOnDialog(deviceId);
      }
    } catch (e) {
      print('📱 ❌ Error checking device status: $e');
      // If there's an error checking status, show the turn on dialog
      _showDeviceTurnOnDialog(deviceId);
    }
  }

  // ✅ NEW: Show iOS-style dialog for device turn on
  void _showDeviceTurnOnDialog(String deviceId) {
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
              '스캔하신 기기가 꺼져있거나 연결되지 않았습니다.\n기기를 켜고 다시 스캔해주세요.',
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
                _resetScanningAfterDialog();
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

  // ✅ NEW: Reset scanning after dialog
  void _resetScanningAfterDialog() {
    setState(() {
      _isProcessing = false;
    });
    _lastScannedCode = null;

    // Restart scanning after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (!_isDisposed && controller != null) {
        controller?.start();
      }
    });
  }

  Future<void> _processQRCode(String code) async {
    final timeZoneOffset = DateTime.now().timeZoneOffset.inMinutes;
    ref.read(deviceNotifierProvider.notifier).pairDevice(code, timeZoneOffset);
  }

  void _resetScanning() {
    setState(() {
      _isProcessing = false;
    });
    _lastScannedCode = null;
    controller?.start();
  }

  void _handleSuccess(DeviceResponseData device) {
    if (widget.onQRScanned != null) {
      widget.onQRScanned!(device.deviceId);
    }
  }

  void _startScanning() {
    print('📱 Starting camera scanning...');
    controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceNotifierProvider);

    ref.listen<DeviceState>(deviceNotifierProvider, (previous, next) {
      if (next.pairedDevice != null && previous?.pairedDevice == null) {
        print('📱 Device just paired: ${next.pairedDevice?.deviceId}');
        _handleSuccess(next.pairedDevice!);
        _navigateToDeviceDetails();
      }

      if (next.error != null && previous?.error == null) {
        if (next.error!.contains('already paired') ||
            next.error!.contains('-106')) {
          print('📱 Device already paired error detected, attempting redirect');
          _navigateToDeviceDetails();
        } else {
          _resetScanning();
        }
      }
    });

    if (controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        final safePadding = MediaQuery.of(context).padding;

        final topSectionHeight = math.max(220.0, availableHeight * 0.28);
        final bottomSectionHeight = math.max(120.0, availableHeight * 0.15);

        final spacing = 20.0;
        final availableForScanner =
            availableHeight - topSectionHeight - bottomSectionHeight - spacing;

        final maxScannerSize = math.min(
          availableWidth * 0.85,
          availableForScanner * 0.9,
        );
        final scannerSize = math.max(300.0, maxScannerSize);

        return Container(
          child: Stack(
            children: [
              // Mobile Scanner View - Full background
              Positioned.fill(
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {},
                ),
              ),

              // Blur effect with proper overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: QROverlayPainter(
                      cutOutSize: scannerSize,
                      borderRadius: 20,
                      topSectionHeight: topSectionHeight,
                    ),
                  ),
                ),
              ),

              // Clear scanning area (no blur) - positioned with proper spacing
              Positioned(
                left: (availableWidth - scannerSize) / 2,
                top:
                    topSectionHeight +
                    spacing +
                    ((availableForScanner - scannerSize) / 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: scannerSize,
                    height: scannerSize,
                    child: MobileScanner(
                      controller: controller,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
              ),

              // QR Scanner Frame with rounded corners
              Positioned(
                left: (availableWidth - scannerSize) / 2,
                top:
                    topSectionHeight +
                    spacing +
                    ((availableForScanner - scannerSize) / 2),
                child: Container(
                  width: scannerSize,
                  height: scannerSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFB8FF00),
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Top section with WHITE background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: topSectionHeight,
                  padding: EdgeInsets.only(
                    top: safePadding.top + 20,
                    left: 24,
                    right: 24,
                    bottom: 20,
                  ),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 32),
                          if (widget.onBackPressed != null)
                            GestureDetector(
                              onTap: widget.onBackPressed,
                              child: Container(
                                width: 32,
                                height: 40,
                                child: Icon(
                                  Icons.info_outline,
                                  color: Colors.black.withOpacity(0.9),
                                  size: 30,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 32,
                              height: 40,
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.black.withOpacity(0.9),
                                size: 30,
                              ),
                            ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          '기기의 QR을 스캔해서\n연결해주세요',
                          style: TextStyles.kSemiBold.copyWith(
                            fontSize: availableWidth < 400 ? 24 : 28,
                            color: Colors.black,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section with instruction text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: safePadding.bottom + 20,
                    top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '위 사각 테두리 안에\nQR코드를 인식시켜주세요',
                        textAlign: TextAlign.center,
                        style: TextStyles.kMedium.copyWith(
                          fontSize: availableWidth < 400 ? 14 : 16,
                          color: const Color(0xFFB8FF00),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ NEW: Processing overlay
              if (_isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFB8FF00),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '기기 상태를 확인 중...',
                            style: TextStyles.kMedium.copyWith(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

void unawaited(Future<void>? future) {
  // Explicitly ignore the future
}

// Custom painter (unchanged)
class QROverlayPainter extends CustomPainter {
  final double cutOutSize;
  final double borderRadius;
  final double topSectionHeight;

  QROverlayPainter({
    required this.cutOutSize,
    required this.borderRadius,
    required this.topSectionHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    final spacing = 20.0;
    final availableForScanner =
        size.height - topSectionHeight - (size.height * 0.15) - spacing;

    final center = Offset(
      size.width / 2,
      topSectionHeight + spacing + (availableForScanner / 2),
    );

    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final outerPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final topSectionPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, topSectionHeight));

    final innerPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        );

    final overlayPath = Path.combine(
      PathOperation.difference,
      Path.combine(PathOperation.difference, outerPath, topSectionPath),
      innerPath,
    );

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
