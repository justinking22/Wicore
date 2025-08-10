import 'package:Wicore/models/device_response_model.dart'
    show DeviceResponseData;
import 'package:Wicore/states/device_state.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
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

class _QRScannerWidgetState extends ConsumerState<QRScannerWidget> {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();

    // Check for existing device immediately after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingPairedDevice();
    });
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
    try {
      // Stop camera before navigation
      controller.stop();
    } catch (e) {
      print('Error stopping camera: $e');
    }

    if (widget.onShowDeviceDetails != null) {
      widget.onShowDeviceDetails!();
    }
  }

  void _handleQRResult(BarcodeCapture capture) {
    final deviceState = ref.read(deviceNotifierProvider);
    final pairedDevice = ref.read(deviceDataProvider);

    // First check if device is already paired
    if (deviceState.pairedDevice != null || pairedDevice != null) {
      print('📱 Device already paired, navigating to details');
      _navigateToDeviceDetails();
      return;
    }

    // Proceed with scanning if no device is paired
    if (deviceState.isLoading) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _processQRCode(code);
      }
    }
  }

  Future<void> _processQRCode(String code) async {
    try {
      await controller.stop();
    } catch (e) {
      print('Error stopping camera: $e');
    }

    final timeZoneOffset = DateTime.now().timeZoneOffset.inMinutes;
    ref.read(deviceNotifierProvider.notifier).pairDevice(code, timeZoneOffset);
  }

  void _resetScanner() {
    ref.read(deviceNotifierProvider.notifier).clearState();
    try {
      controller.start();
    } catch (e) {
      print('Error restarting camera: $e');
    }
  }

  void _handleSuccess(DeviceResponseData device) {
    // Call the callback when API call succeeds
    if (widget.onQRScanned != null) {
      widget.onQRScanned!(device.deviceId);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceNotifierProvider);

    // Listen for successful pairing and navigate (including -106 already paired case)
    ref.listen<DeviceState>(deviceNotifierProvider, (previous, next) {
      // Handle successful pairing (including -106 already paired case)
      if (next.pairedDevice != null && previous?.pairedDevice == null) {
        print('📱 Device just paired: ${next.pairedDevice?.deviceId}');
        _handleSuccess(next.pairedDevice!);
        _navigateToDeviceDetails();
      }

      // Handle specific error cases that should still redirect
      if (next.error != null && previous?.error == null) {
        // Check if the error is about device already being paired
        if (next.error!.contains('already paired') ||
            next.error!.contains('-106')) {
          print('📱 Device already paired error detected, attempting redirect');
          // The pairDevice method should have handled this, but just in case
          _navigateToDeviceDetails();
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        final safePadding = MediaQuery.of(context).padding;

        // Calculate adaptive sizes to prevent overlapping
        final topSectionHeight = math.max(160.0, availableHeight * 0.2);
        final bottomSectionHeight = math.max(120.0, availableHeight * 0.15);
        final scannerAreaHeight =
            availableHeight - topSectionHeight - bottomSectionHeight;

        // Calculate scanner size based on available space
        final maxScannerSize = math.min(
          availableWidth * 0.8,
          scannerAreaHeight * 0.8,
        );
        final scannerSize = math.min(400.0, maxScannerSize);

        // Calculate scanner position
        final scannerTop =
            topSectionHeight + (scannerAreaHeight - scannerSize) / 2;

        return Container(
          child: Stack(
            children: [
              // Mobile Scanner View (blurred background)
              Positioned.fill(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: scannerSize,
                      height: scannerSize,
                      child: MobileScanner(
                        controller: controller,
                        onDetect: _handleQRResult,
                      ),
                    ),
                  ),
                ),
              ),

              // Blurred overlay everywhere except the scanning area
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: QROverlayPainter(
                      cutOutSize: scannerSize * 0.6,
                      borderRadius: 20,
                      cutOutTop: scannerTop + (scannerSize * 0.2),
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
                      onDetect: _handleQRResult,
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
                          // Back button (if callback provided)
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
                  height: bottomSectionHeight,
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
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '위 사각 테두리 안에\nQR코드를 인식시켜주세요',
                      textAlign: TextAlign.center,
                      style: TextStyles.kMedium.copyWith(
                        fontSize: availableWidth < 400 ? 14 : 16,
                        color: const Color(0xFFB8FF00),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              // Handle device pairing states
              if (deviceState.isLoading) _buildLoadingOverlay(),
              if (deviceState.error != null)
                _buildErrorOverlay(deviceState.error!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: CustomColors.splashLimeColor),
            const SizedBox(height: 20),
            Text(
              '기기 연결 중...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
    // Don't show error overlay for "already paired" cases as they should redirect
    if (error.contains('already paired') || error.contains('-106')) {
      return Container(); // Return empty container
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text('연결 실패', style: TextStyle(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.splashLimeColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _resetScanner,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the QR overlay
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
          ..color = Colors.black.withOpacity(0.3)
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
