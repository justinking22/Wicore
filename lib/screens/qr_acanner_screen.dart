// lib/screens/qr_scanner_screen.dart - UPDATED WITH NEW LOGIC
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
          // ✅ UPDATED: Process QR code with new logic
          await _processQRCodeWithNewLogic(code);
        } catch (e) {
          print('📱 Error processing QR code: $e');
          _resetScanning();
        }
      }
    }
  }

  // ✅ NEW: Process QR code with updated logic
  Future<void> _processQRCodeWithNewLogic(String deviceId) async {
    print('📱 === PROCESSING QR CODE WITH NEW LOGIC ===');
    print('📱 Device ID: $deviceId');

    try {
      // Step 1: Pair the device
      print('📱 Step 1: Pairing device...');
      final timeZoneOffset = DateTime.now().timeZoneOffset.inMinutes;

      // Call the pairing method
      ref
          .read(deviceNotifierProvider.notifier)
          .pairDevice(deviceId, timeZoneOffset);

      // Wait a moment for pairing to complete
      await Future.delayed(Duration(milliseconds: 1500));

      // Step 2: Check if pairing was successful by checking device state
      final deviceState = ref.read(deviceNotifierProvider);
      if (deviceState.error != null) {
        print('📱 ❌ Pairing failed: ${deviceState.error}');

        if (deviceState.error!.contains('already paired') ||
            deviceState.error!.contains('-106')) {
          print('📱 Device already paired, proceeding to check active status');
        } else {
          _showPairingErrorDialog(deviceState.error!);
          return;
        }
      }

      // Step 3: Check device/active endpoint after pairing
      print('📱 Step 2: Checking device/active endpoint...');
      await _checkDeviceActiveStatus(deviceId);
    } catch (error) {
      print('📱 ❌ Error in processQRCodeWithNewLogic: $error');
      _showPairingErrorDialog('페어링 중 오류가 발생했습니다');
    }
  }

  // ✅ NEW: Check device active status after pairing
  Future<void> _checkDeviceActiveStatus(String deviceId) async {
    print('📱 🔍 Checking device active status for: $deviceId');

    try {
      // Clear cache and check device/active endpoint
      ref.invalidate(activeDeviceProvider);
      final activeDevice = await ref.read(activeDeviceProvider.future);

      print('📱 Active device response: ${activeDevice?.safeDeviceId}');

      // Check if the paired device is now active
      if (activeDevice != null && activeDevice.safeDeviceId == deviceId) {
        print('📱 ✅ Device is active, proceeding to device details');
        _handleSuccessfulPairing(deviceId);
      } else {
        print(
          '📱 ❌ Device is not active after pairing, showing turn on dialog',
        );
        _showDeviceTurnOnDialog(deviceId);
      }
    } catch (e) {
      print('📱 ❌ Error checking device active status: $e');
      // If there's an error checking status, show the turn on dialog
      _showDeviceTurnOnDialog(deviceId);
    }
  }

  // ✅ NEW: Handle successful pairing
  void _handleSuccessfulPairing(String deviceId) {
    print('📱 ✅ Handling successful pairing for: $deviceId');

    setState(() {
      _isProcessing = false;
    });

    // Notify parent that QR was successfully scanned and device is active
    if (widget.onQRScanned != null) {
      widget.onQRScanned!(deviceId);
    }

    // Also trigger the show device details callback
    if (widget.onShowDeviceDetails != null) {
      widget.onShowDeviceDetails!();
    }
  }

  // ✅ NEW: Show pairing error dialog
  void _showPairingErrorDialog(String errorMessage) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            '페어링 실패',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              errorMessage,
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

  // ✅ UPDATED: Show device turn on dialog (updated message)
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

  // ✅ UPDATED: Reset scanning after dialog
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

  void _resetScanning() {
    setState(() {
      _isProcessing = false;
    });
    _lastScannedCode = null;
    controller?.start();
  }

  void _startScanning() {
    print('📱 Starting camera scanning...');
    controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ REMOVED: Device state listener (no longer needed with new logic)

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

              // ✅ UPDATED: Processing overlay with new messaging
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
                            '기기를 페어링하고 있습니다...',
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
