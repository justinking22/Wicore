import 'package:Wicore/models/device_response_model.dart'
    show DeviceResponseData;
import 'package:Wicore/states/device_state.dart';
import 'package:flutter/material.dart';
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

    // Initialize controller and start immediately (like diagnox after user action)
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: false,
      torchEnabled: false,
      facing: CameraFacing.back,
      returnImage: false,
    );

    // Start listening to barcode events
    _subscription = controller!.barcodes.listen(_onDetect);

    // Start camera immediately after controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // EXACT same lifecycle handling as diagnox
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
    // EXACT same detection logic as diagnox
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
          // Check if device is already paired first
          final deviceState = ref.read(deviceNotifierProvider);
          final pairedDevice = ref.read(deviceDataProvider);

          if (deviceState.pairedDevice != null || pairedDevice != null) {
            print('📱 Device already paired, navigating to details');
            _navigateToDeviceDetails();
            return;
          }

          // Process the QR code
          await _processQRCode(code);
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

  Future<void> _processQRCode(String code) async {
    final timeZoneOffset = DateTime.now().timeZoneOffset.inMinutes;
    ref.read(deviceNotifierProvider.notifier).pairDevice(code, timeZoneOffset);
  }

  void _resetScanning() {
    setState(() {
      _isProcessing = false;
    });
    _lastScannedCode = null;

    // Try to restart camera
    controller?.start();
  }

  void _handleSuccess(DeviceResponseData device) {
    if (widget.onQRScanned != null) {
      widget.onQRScanned!(device.deviceId);
    }
  }

  // Manual start method - now called automatically
  void _startScanning() {
    print('📱 Starting camera scanning...');
    controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceNotifierProvider);

    // Listen for device pairing state changes
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
          // Reset scanner for other errors
          _resetScanning();
        }
      }
    });

    // Show loading while controller initializes
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

        final topSectionHeight = math.max(160.0, availableHeight * 0.2);
        final bottomSectionHeight = math.max(120.0, availableHeight * 0.15);
        final scannerAreaHeight =
            availableHeight - topSectionHeight - bottomSectionHeight;

        final maxScannerSize = math.min(
          availableWidth * 0.9,
          scannerAreaHeight * 0.9,
        );
        final scannerSize = maxScannerSize;

        final scannerTop =
            topSectionHeight + (scannerAreaHeight - scannerSize) * 0.6;

        return Container(
          child: Stack(
            children: [
              // Mobile Scanner View - EXACT same pattern as diagnox
              Positioned.fill(
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    // Handle detection - redundant since we use stream
                  },
                ),
              ),

              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: QROverlayPainter(
                      cutOutSize: scannerSize,
                      borderRadius: 20,
                      cutOutTop:
                          scannerTop -
                          topSectionHeight, // Adjust for the new positioned offset
                    ),
                  ),
                ),
              ),

              // Clear scanning area (no blur)
              Positioned(
                top: scannerTop,
                left: (availableWidth - scannerSize) / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: scannerSize,
                    height: scannerSize,
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (capture) {},
                    ),
                  ),
                ),
              ),

              // Center QR Scanner Frame with rounded corners
              Positioned(
                top: scannerTop,
                left: (availableWidth - scannerSize) / 2,
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

              // Top section with WHITE background and title
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

              // Bottom section with instruction text and start button
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ),
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

              // Processing overlay
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: CustomColors.splashLimeColor,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '기기 연결 중...',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

              // // Error overlay for device pairing errors
              // if (deviceState.error != null &&
              //     !deviceState.error!.contains('already paired') &&
              //     !deviceState.error!.contains('-106'))
              //   _buildErrorOverlay(deviceState.error!),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildErrorOverlay(String error) {
  //   return Container(
  //     color: Colors.black54,
  //     child: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(Icons.error, color: Colors.red, size: 64),
  //           const SizedBox(height: 16),
  //           Text('연결 실패', style: TextStyle(fontSize: 20, color: Colors.white)),
  //           const SizedBox(height: 8),
  //           Text(
  //             error,
  //             style: TextStyle(color: Colors.white70),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 24),
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: CustomColors.splashLimeColor,
  //               foregroundColor: Colors.black,
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 24,
  //                 vertical: 12,
  //               ),
  //             ),
  //             onPressed: _resetScanning,
  //             child: const Text('다시 시도'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

// Add this helper function for async operations
void unawaited(Future<void>? future) {
  // Explicitly ignore the future
}

// Custom painter for the QR overlay (same as before)
class QROverlayPainter extends CustomPainter {
  final double cutOutSize;
  final double borderRadius;
  final double cutOutTop;

  QROverlayPainter({
    required this.cutOutSize,
    required this.borderRadius,
    required this.cutOutTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.0)
          ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, cutOutTop + cutOutSize / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    final outerPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        );

    final overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
