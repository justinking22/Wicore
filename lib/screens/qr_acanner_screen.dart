import 'package:Wicore/models/device_response_model.dart'
    show DeviceResponseData;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/models/device_request_model.dart';
import 'package:Wicore/providers/device_provider.dart'; // Add this import

class QRScannerWidget extends ConsumerStatefulWidget {
  final Function(String)? onQRScanned;
  final VoidCallback? onBackPressed;

  const QRScannerWidget({Key? key, this.onQRScanned, this.onBackPressed})
    : super(key: key);

  @override
  ConsumerState<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends ConsumerState<QRScannerWidget> {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  void _handleQRResult(BarcodeCapture capture) {
    final deviceState = ref.read(deviceNotifierProvider);
    if (deviceState.isLoading || deviceState.pairedDevice != null) return;

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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceNotifierProvider);

    return Container(
      child: Stack(
        children: [
          // Mobile Scanner View (blurred background)
          MobileScanner(controller: controller, onDetect: _handleQRResult),

          // Blurred overlay everywhere except the scanning area
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: QROverlayPainter(cutOutSize: 280, borderRadius: 20),
              ),
            ),
          ),

          // Clear scanning area (no blur)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 400,
                height: 400,
                child: MobileScanner(
                  controller: controller,
                  onDetect: _handleQRResult,
                ),
              ),
            ),
          ),

          // Center QR Scanner Frame with rounded corners
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB8FF00), width: 4),
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
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 20,
              ),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      // Info button
                      GestureDetector(
                        onTap: () => context.go('/pairing-info'),
                        child: Container(
                          width: 32,
                          height: 40,
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.black.withOpacity(0.9),
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '기기의 QR을 스캔해서\n연결해주세요',
                    style: TextStyles.kSemiBold.copyWith(
                      fontSize: 28,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Flash toggle button

          // Bottom section with instruction text
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 40,
                top: 40,
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
              child: Text(
                '위 사각 테두리 안에\nQR코드를 인식시켜주세요',
                textAlign: TextAlign.center,
                style: TextStyles.kMedium.copyWith(
                  fontSize: 16,
                  color: const Color(0xFFB8FF00),
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Handle device pairing states
          if (deviceState.isLoading) _buildLoadingOverlay(),
          if (deviceState.error != null) _buildErrorOverlay(deviceState.error!),
          if (deviceState.pairedDevice != null)
            _buildSuccessOverlay(deviceState.pairedDevice!),
        ],
      ),
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

  Widget _buildSuccessOverlay(DeviceResponseData device) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              '기기 연결 성공!',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '기기 ID: ${device.deviceId}',
              style: TextStyle(color: Colors.white70),
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
              onPressed: () {
                context.push('/device-details?deviceId=${device.deviceId}');
                ref.read(deviceNotifierProvider.notifier).clearState();
              },
              child: const Text('기기 상세 정보 보기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
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

  QROverlayPainter({required this.cutOutSize, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final cutOutRect = Rect.fromCenter(
      center: center,
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
