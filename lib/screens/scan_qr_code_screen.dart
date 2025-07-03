// QR Scanner Full Screen (similar to your reference)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart';

class RegisterDeviceQRScanScreen extends StatefulWidget {
  const RegisterDeviceQRScanScreen({Key? key}) : super(key: key);

  @override
  _RegisterDeviceQRScanScreenState createState() => _RegisterDeviceQRScanScreenState();
}

class _RegisterDeviceQRScanScreenState extends State<RegisterDeviceQRScanScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isFlashOn = false;
  bool _hasScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      cameraController.stop();
    } else if (Platform.isIOS) {
      cameraController.start();
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    cameraController.toggleTorch();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      
      if (code != null && code.isNotEmpty) {
        setState(() {
          _hasScanned = true;
        });
        
        await cameraController.stop();
        
        try {
          // Parse QR code data to extract device information
          Map<String, dynamic> qrData = {};
          
          try {
            // If QR code contains JSON data
            qrData = json.decode(code);
          } catch (e) {
            // If QR code is just a device ID, create basic structure
            qrData = {
              'd_id': code,
              'fv': '0.0.1',
              'rev': 1,
              'offset': 540
            };
          }
          
          // Get current user data
          final authService = Provider.of<AuthService>(context, listen: false);
          final user = authService.userData;

          if (user == null) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not found. Please login again.')),
              );
            }
            return;
          }

          // Prepare data in your exact format
          final requestData = {
            "u_id": user['id'] ?? user['userId'], // Get user ID from auth
            "item": {
              "d_id": qrData['d_id'] ?? code,
              "fv": qrData['fv'] ?? "0.0.1",
              "rev": qrData['rev'] ?? 1,
              "offset": qrData['offset'] ?? 540
            }
          };

          // Make API call using your makeAuthenticatedRequest method
          final result = await authService.makeAuthenticatedRequest(
            endpoint: 'device/register', // Adjust endpoint as needed
            method: 'POST',
            body: requestData,
          );

          if (mounted) {
            if (result['success']) {
              // Return success and device info to the previous screen
              Navigator.pop(context, {
                'success': true,
                'deviceId': qrData['d_id'] ?? code,
                'deviceData': qrData,
                'apiResponse': result['data'], // API response data
              });
            } else {
              // Show error and return to previous screen
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Device registration failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Network error occurred. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Device QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          
          // Custom overlay
          _buildScannerOverlay(context),
          
          // Header text
          const Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Text(
              'Scan the QR Code on the device.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Bottom instructions
          Positioned(
            bottom: 80,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Position the QR code within the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure the code is clearly visible and well-lit',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Success overlay when scanned
          if (_hasScanned)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'QR Code Scanned!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Processing device information...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
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
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final double cutOutSize = MediaQuery.of(context).size.width * 0.6;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: ShapeDecoration(
        shape: _ScannerOverlayShape(
          borderColor: Theme.of(context).primaryColor,
          borderRadius: 12,
          borderLength: 25,
          borderWidth: 4,
          cutOutSize: cutOutSize,
        ),
      ),
    );
  }
}

// Custom scanner overlay shape (similar to your reference)
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const _ScannerOverlayShape({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final double centerX = rect.center.dx;
    final double centerY = rect.center.dy;
    final double halfSize = cutOutSize / 2;
    
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - halfSize,
          centerY - halfSize,
          cutOutSize,
          cutOutSize,
        ),
        Radius.circular(borderRadius),
      ));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final double centerX = rect.center.dx;
    final double centerY = rect.center.dy;
    final double halfSize = cutOutSize / 2;
    
    // Create the overlay with transparent center
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);
    
    final Path overlayPath = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - halfSize,
          centerY - halfSize,
          cutOutSize,
          cutOutSize,
        ),
        Radius.circular(borderRadius),
      ))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(overlayPath, overlayPaint);
    
    // Draw corner borders
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final double left = centerX - halfSize;
    final double top = centerY - halfSize;
    final double right = centerX + halfSize;
    final double bottom = centerY + halfSize;
    
    // Top-left corner
    canvas.drawLine(
      Offset(left, top + borderRadius),
      Offset(left, top + borderRadius + borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, top),
      Offset(left + borderRadius + borderLength, top),
      borderPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(right, top + borderRadius),
      Offset(right, top + borderRadius + borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(right - borderRadius, top),
      Offset(right - borderRadius - borderLength, top),
      borderPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(left, bottom - borderRadius),
      Offset(left, bottom - borderRadius - borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, bottom),
      Offset(left + borderRadius + borderLength, bottom),
      borderPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(right, bottom - borderRadius),
      Offset(right, bottom - borderRadius - borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(right - borderRadius, bottom),
      Offset(right - borderRadius - borderLength, bottom),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}