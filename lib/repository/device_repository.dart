import 'package:Wicore/models/active_device_model.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:Wicore/models/device_unpair_response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/device_request_model.dart';
import '../models/device_response_model.dart';
import '../services/device_api_client.dart';

class DeviceRepository {
  final DeviceApiClient _apiClient;

  DeviceRepository(this._apiClient);

  Future<DeviceResponse> registerDevice(DeviceRequest request) async {
    try {
      final response = await _apiClient.registerDevice(request);
      return response;
    } on DioException catch (e) {
      return _handleDeviceDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error during device registration: $e');
      return DeviceResponse(code: -1, error: e.toString());
    }
  }

  DeviceResponse _handleDeviceDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return DeviceResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return DeviceResponse(code: e.response?.statusCode ?? -1, error: e.message);
  }

  // Method for getting active devices with battery info
  Future<ActiveDeviceResponse> getActiveDevices(String userId) async {
    try {
      print('🔧 Repository - Fetching active devices for userId: $userId');
      return await _apiClient.getActiveDevices(userId: userId);
    } catch (e) {
      print('🔧 ❌ Repository - Error fetching active devices: $e');
      rethrow;
    }
  }

  // Method: Get all user devices from /device/all endpoint
  Future<DeviceListResponse> getAllUserDevices(String userId) async {
    try {
      final response = await _apiClient.getAllDevices(userId: userId);
      return response;
    } on DioException catch (e) {
      return _handleDeviceListDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error fetching all user devices: $e');
      return DeviceListResponse(code: -1, error: e.toString());
    }
  }

  // UPDATED: Unpair device with proper return type
  Future<DeviceUnpairResponse> unpairDevice(String deviceId) async {
    try {
      print('🔧 Repository - Unpairing device: $deviceId');
      final response = await _apiClient.unpairDevice(deviceId: deviceId);
      print('🔧 Repository - Unpair response: ${response.code}');

      if (response.isSuccess && response.data != null) {
        print('🔧 ✅ Device unpaired successfully: ${response.data!.deviceId}');
        print('🔧 📱 New status: ${response.data!.status}');
      }

      return response;
    } on DioException catch (e) {
      print('🔧 ❌ Repository - Error unpairing device: $e');
      return _handleUnpairDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error unpairing device: $e');
      return DeviceUnpairResponse(code: -1, error: e.toString());
    }
  }

  DeviceUnpairResponse _handleUnpairDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return DeviceUnpairResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return DeviceUnpairResponse(
      code: e.response?.statusCode ?? -1,
      error: e.message,
    );
  }

  DeviceListResponse _handleDeviceListDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        try {
          return DeviceListResponse.fromJson(data);
        } catch (_) {
          // Fallback if response doesn't match expected format
        }
      }
    }

    return DeviceListResponse(
      code: e.response?.statusCode ?? -1,
      error: e.message,
    );
  }

  // UTILITY METHODS for working with device data

  /// Get devices filtered by status from all devices
  Future<List<DeviceListItem>> getDevicesByStatus(
    String userId,
    String status,
  ) async {
    try {
      final response = await getAllUserDevices(userId);
      if (response.isSuccess && response.devices != null) {
        return response.devices!
            .where((device) => device.status == status)
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Error getting devices by status: $e');
      return [];
    }
  }

  /// Get device counts grouped by status
  Future<Map<String, int>> getDeviceStatusCounts(String userId) async {
    try {
      final response = await getAllUserDevices(userId);
      if (response.isSuccess && response.devices != null) {
        final statusCount = <String, int>{};
        for (final device in response.devices!) {
          statusCount[device.status] = (statusCount[device.status] ?? 0) + 1;
        }
        return statusCount;
      }
      return {};
    } catch (e) {
      if (kDebugMode) print('Error getting device status counts: $e');
      return {};
    }
  }

  /// Get only active devices from all devices
  Future<List<DeviceListItem>> getActiveDevicesList(String userId) async {
    return getDevicesByStatus(userId, 'active');
  }

  /// Get only expired devices from all devices
  Future<List<DeviceListItem>> getExpiredDevicesList(String userId) async {
    return getDevicesByStatus(userId, 'expired');
  }

  /// Check if user has any active devices
  Future<bool> hasActiveDevices(String userId) async {
    try {
      final activeDevices = await getActiveDevicesList(userId);
      return activeDevices.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Error checking active devices: $e');
      return false;
    }
  }

  /// Get total device count for user
  Future<int> getTotalDeviceCount(String userId) async {
    try {
      final response = await getAllUserDevices(userId);
      if (response.isSuccess && response.devices != null) {
        return response.devices!.length;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) print('Error getting total device count: $e');
      return 0;
    }
  }

  /// NEW UTILITY: Check if device unpair was successful
  // bool isUnpairSuccessful(DeviceListResponse response) {
  //   return response.code == 0 && response.data?.status == 'expired';
  // }

  // /// NEW UTILITY: Get unpaired device info
  // Map<String, dynamic>? getUnpairedDeviceInfo(DeviceListResponse response) {
  //   if (isUnpairSuccessful(response) && response.data != null) {
  //     return {
  //       'deviceId': response.data!.dId,
  //       'status': response.data!.status,
  //       'updatedAt': response.data!.updated,
  //       'expiryDate': response.data!.expiryDate,
  //     };
  //   }
  //   return null;
  // }
}
