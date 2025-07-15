import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui'; // Add this for ImageFilter
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String)? onQRScanned;
  final VoidCallback? onBackPressed;

  const QRScannerWidget({Key? key, this.onQRScanned, this.onBackPressed})
    : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late MobileScannerController controller;
  bool _isFlashOn = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  void _handleQRResult(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        _processQRCode(code);
      }
    }
  }

  void _processQRCode(String code) {
    setState(() {
      _hasScanned = true;
    });

    // Stop camera
    controller.stop();

    // Call the callback after 5 seconds or navigate if no callback
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (widget.onQRScanned != null) {
          widget.onQRScanned!(code);
        } else {
          // Fallback navigation
          context.go('/device-details?deviceId=$code');
        }
      }
    });
  }

  // Simulate QR scan for testing
  void _simulateQRScan() {
    String simulatedQRData =
        "DEV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    _processQRCode(simulatedQRData);
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                color: Colors.white, // White background instead of gradient
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Simulate button for testing
                      GestureDetector(
                        onTap: _simulateQRScan,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            '시뮬레이션',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Info button
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
                  const SizedBox(height: 20),
                  Text(
                    '기기의 QR을 스캔해서\n연결해주세요',
                    style: TextStyles.kSemiBold.copyWith(
                      fontSize: 28,
                      color: Colors.black, // Black text on white background
                      height: 1.3,
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

          // Scan success overlay
          if (_hasScanned)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'QR 코드 스캔 완료!',
                            style: TextStyles.kSemiBold.copyWith(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '5초 후 기기 상세 화면으로 이동합니다',
                            style: TextStyles.kMedium.copyWith(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(
                            color: Color(0xFFB8FF00),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          ..color = Colors.black.withOpacity(
            0.3,
          ) // Lighter overlay since we have blur
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
