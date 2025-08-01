import 'package:Wicore/providers/authentication_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(endpoint, queryParameters: queryParameters);
  }

  Future<Response> post(String endpoint, {dynamic data}) {
    return _dio.post(endpoint, data: data);
  }

  Future<Response> put(String endpoint, {dynamic data}) {
    return _dio.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) {
    return _dio.delete(endpoint);
  }
}

// Provider for authenticated API service
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return ApiService(dio);
});
