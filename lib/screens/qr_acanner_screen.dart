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

        // Calculate top section height with much more space for the two-line title
        final topSectionHeight = math.max(220.0, availableHeight * 0.28);
        final bottomSectionHeight = math.max(120.0, availableHeight * 0.15);

        // Add more spacing between top section and scanner
        final spacing = 20.0;
        final availableForScanner =
            availableHeight - topSectionHeight - bottomSectionHeight - spacing;

        // Make scanner size bigger again - use more aggressive sizing
        final maxScannerSize = math.min(
          availableWidth * 0.85,
          availableForScanner * 0.9,
        );
        final scannerSize = math.max(
          300.0,
          maxScannerSize,
        ); // Increased minimum to 300

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
                      onDetect: _onDetect, // Use the actual onDetect method
                    ),
                  ),
                ),
              ),

              // QR Scanner Frame with rounded corners - positioned to match scanner area
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

              // Top section with WHITE background - positioned above blur
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

// Updated Custom painter that respects the top section and positions scanner area correctly
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
          ..color = Colors.black.withOpacity(0.3) // Lighter since we have blur
          ..style = PaintingStyle.fill;

    // Calculate available height for scanner positioning with reduced spacing
    final spacing = 20.0;
    final availableForScanner =
        size.height - topSectionHeight - (size.height * 0.15) - spacing;

    // Position scanner in the center of available space with reduced spacing
    final center = Offset(
      size.width / 2,
      topSectionHeight + spacing + (availableForScanner / 2),
    );

    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Create paths for the overlay
    final outerPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Exclude the top section from the overlay
    final topSectionPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, topSectionHeight));

    final innerPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        );

    // Combine paths: outer - top section - scanner area
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
