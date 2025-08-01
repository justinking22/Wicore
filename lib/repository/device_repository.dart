import 'package:Wicore/models/device_list_response_model.dart';
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

  Future<DeviceListResponse> getActiveDevices(String userId) async {
    try {
      final response = await _apiClient.getActiveDevices(userId: userId);
      return response;
    } on DioException catch (e) {
      return _handleDeviceListDioError(e);
    } catch (e) {
      if (kDebugMode) print('Error fetching active devices: $e');
      return DeviceListResponse(code: -1, error: e.toString());
    }
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
}
