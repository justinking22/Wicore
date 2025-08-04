import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PlatformAwarePermissions {
  static Future<void> requestPermissions(BuildContext context) async {
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
      // Return success or call your callback
      return;
    } else {
      await _handlePermissionDenied(context, statuses);
    }
  }

  static Future<void> _handlePermissionDenied(
    BuildContext context,
    Map<Permission, PermissionStatus> statuses,
  ) async {
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

    // Check if any permissions are permanently denied
    bool anyPermanentlyDenied = statuses.values.any(
      (status) => status.isPermanentlyDenied,
    );

    if (anyPermanentlyDenied) {
      await _showSettingsDialog(context);
    }
  }

  static Future<void> _showSettingsDialog(BuildContext context) async {
    if (Platform.isIOS) {
      // Use Cupertino dialog for iOS
      return showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('권한 필요'),
            content: const Text(
              'WICORE에서 근처 기기를 찾아 연결하고 기기 간 상대적 위치를 파악하도록 허용하시겠습니까?\n\n설정에서 카메라, 블루투스, 위치 권한을 허용해주세요.',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('설정으로 이동'),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
              CupertinoDialogAction(
                child: const Text('취소'),
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      // Use Material dialog for Android
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text('권한 필요'),
              ],
            ),
            content: const Text(
              'WICORE에서 근처 기기를 찾아 연결하고 기기 간 상대적 위치를 파악하도록 허용하시겠습니까?\n\n설정에서 필요한 권한들을 허용해주세요.',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          );
        },
      );
    }
  }
}

// Alternative approach: You can also check permission status first
class PermissionChecker {
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // First check current status
    Map<Permission, PermissionStatus> currentStatuses = {};

    for (Permission permission in [
      Permission.camera,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ]) {
      currentStatuses[permission] = await permission.status;
    }

    // If all granted, return immediately
    bool allGranted = currentStatuses.values.every(
      (status) => status.isGranted,
    );
    if (allGranted) return true;

    // Check which permissions need requesting
    List<Permission> permissionsToRequest = [];
    List<Permission> permanentlyDenied = [];

    currentStatuses.forEach((permission, status) {
      if (status.isDenied) {
        permissionsToRequest.add(permission);
      } else if (status.isPermanentlyDenied) {
        permanentlyDenied.add(permission);
      }
    });

    // If some are permanently denied, go straight to settings
    if (permanentlyDenied.isNotEmpty) {
      await PlatformAwarePermissions._showSettingsDialog(context);
      return false;
    }

    // Request permissions that can still be requested
    if (permissionsToRequest.isNotEmpty) {
      Map<Permission, PermissionStatus> results =
          await permissionsToRequest.request();

      // Check results
      bool allNowGranted = results.values.every((status) => status.isGranted);

      if (!allNowGranted) {
        // Some still denied, show appropriate dialog
        await PlatformAwarePermissions._handlePermissionDenied(
          context,
          results,
        );
        return false;
      }
    }

    return true;
  }
}
