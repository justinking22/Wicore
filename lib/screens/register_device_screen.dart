import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:with_force/providers/auth_provider.dart';
import 'package:with_force/screens/scan_qr_code_screen.dart';

class RegisterDeviceScreen extends StatefulWidget {
  const RegisterDeviceScreen({Key? key}) : super(key: key);

  @override
  _RegisterDeviceScreenState createState() => _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends State<RegisterDeviceScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = false;
  String? _scannedDeviceId;
  Map<String, dynamic>? _scannedDeviceData;
  List<Map<String, dynamic>> _registeredDevices = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _loadRegisteredDevices();
  }

  // Load registered devices similar to your original implementation
  Future<void> _loadRegisteredDevices() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final result = await authService.makeAuthenticatedRequest(
        endpoint: 'device/get',
        method: 'GET',
        queryParams: {
          // Add any query params you need for filtering devices
        },
      );
      
      if (result['success'] && result['data'] != null) {
        final deviceData = result['data'];
        if (deviceData is Map<String, dynamic>) {
          setState(() {
            _registeredDevices = [deviceData];
          });
        } else if (deviceData is List) {
          setState(() {
            _registeredDevices = List<Map<String, dynamic>>.from(deviceData);
          });
        }
      }
    } catch (e) {
      _showMessage('Error loading registered devices: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _locationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Handle QR code scanning
  Future<void> _scanQRCode() async {
    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterDeviceQRScanScreen(),
        ),
      );
      
      if (result != null && result['success'] == true) {
        setState(() {
          _scannedDeviceId = result['deviceId'];
          _scannedDeviceData = result['deviceData'];
        });
        
        // Show success dialog since device is registered
        _showSuccessDialog(
          'Device Registered Successfully!',
          'Your IoT device has been successfully registered and linked to your account.',
          () {
            Navigator.pushReplacementNamed(context, '/home');
          }
        );
        
        // Reload the devices list to show the new device
        _loadRegisteredDevices();
      } else if (result != null && result['success'] == false) {
        // Error was already shown in the scanner screen
      }
    } catch (e) {
      _showMessage('Failed to scan QR code. Please try again.');
    }
  }

  // Handle device registration


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, VoidCallback onOk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Scan IoT Device'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section with device icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.devices_other,
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan Your Device',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan the QR code on your IoT device to connect it',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // QR Code section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _scannedDeviceId != null ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _scannedDeviceId != null ? Icons.qr_code : Icons.qr_code_scanner,
                              color: _scannedDeviceId != null ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _scannedDeviceId != null ? 'Device Scanned' : 'Scan QR Code',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _scannedDeviceId != null 
                                      ? 'Device ID: ${_scannedDeviceId!.substring(0, 12)}...'
                                      : 'Tap to scan device QR code',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _scanQRCode,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(_scannedDeviceId != null ? 'Scan Again' : 'Scan QR Code'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                          ],
                  ),
                ),
              ],  // Closes Column children
            ),   // Closes Form
          ),    // Closes SingleChildScrollView
        ),     // Closes SafeArea
      ),      // Closes Scaffold
    );       // Closes build method return
  }        // Closes build method
}    
