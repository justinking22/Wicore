import 'package:Wicore/models/stats_request_model.dart';
import 'package:Wicore/models/stats_response_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/services/stats_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsRepository {
  final StatsApiClient _apiClient;
  final Ref _ref;

  StatsRepository(this._apiClient, this._ref);

  Future<StatsResponse> getStats(StatsRequest request) async {
    try {
      if (kDebugMode) {
        print('🔧 Repository - Getting stats for date: ${request.date}');
      }
      final response = await _apiClient.getStats(request.date);
      if (response.code == 0 && response.data != null) {
        return response;
      }
      throw Exception(
        'No stats data available for date: ${request.date}, code: ${response.code}',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('🔧 ❌ Repository - Error getting stats: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('🔧 ❌ Repository - Unexpected error: $e');
      }
      throw Exception('Failed to fetch stats: $e');
    }
  }

  Future<StatsResponse> getStatsForDate(String date) async {
    try {
      if (kDebugMode) {
        print('🔧 Repository - Getting stats for date: $date');
      }
      final response = await _apiClient.getStats(date);
      if (response.code == 0 && response.data != null) {
        return response;
      }
      throw Exception(
        'No stats data available for date: $date, code: ${response.code}',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print(
          '🔧 ❌ Repository - Error getting stats for date: ${e.response?.data}',
        );
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('🔧 ❌ Repository - Unexpected error: $e');
      }
      throw Exception('Failed to fetch stats: $e');
    }
  }

  Future<StatsResponse> getTodayStats() async {
    final request = StatsRequest.today();
    return getStats(request);
  }

  Future<StatsResponse> getStatsForDateTime(DateTime dateTime) async {
    final request = StatsRequest.fromDateTime(dateTime);
    return getStats(request);
  }

  // Enhanced error handling
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          try {
            _ref.read(authNotifierProvider.notifier).setUnauthenticated();
          } catch (authError) {
            if (kDebugMode) print('Error setting unauthenticated: $authError');
          }
          return Exception('Authentication failed. Please sign in again.');
        }
        // Handle specific status codes
        switch (e.response?.statusCode) {
          case 400:
            return Exception('Bad request. Please check your input.');
          case 403:
            return Exception('Access forbidden. Insufficient permissions.');
          case 404:
            return Exception('Stats not found for the specified date.');
          case 422:
            return Exception('Invalid date format provided.');
          case 500:
            return Exception('Server error. Please try again later.');
        }
        if (e.response?.data != null &&
            e.response!.data is Map<String, dynamic>) {
          try {
            final errorResponse = StatsResponse.fromJson(e.response!.data);
            return Exception('API Error: ${errorResponse.code}');
          } catch (_) {
            return Exception(
              'Invalid error response format: ${e.response?.data}',
            );
          }
        }
        return Exception(
          'Server error: ${e.response?.statusCode ?? 'unknown'}',
        );
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
      default:
        if (e.message?.contains('SocketException') == true) {
          return Exception(
            'No internet connection. Please check your network.',
          );
        }
        return Exception('Network error occurred. Please try again.');
    }
  }

  // Helper method to validate date format
  bool _isValidDateFormat(String date) {
    final regex = RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$');
    return regex.hasMatch(date);
  }

  // Enhanced method with validation
  Future<StatsResponse> getStatsWithValidation(String date) async {
    if (!_isValidDateFormat(date)) {
      throw Exception('Invalid date format. Use YYYY-M-D format.');
    }
    return getStatsForDate(date);
  }

  // Utility method to get stats for a range of dates
  Future<List<StatsResponse>> getStatsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (startDate.isAfter(endDate)) {
      throw Exception('Start date must be before or equal to end date.');
    }
    final results = <StatsResponse>[];
    var currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
      try {
        final stats = await getStatsForDateTime(currentDate);
        results.add(stats);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to get stats for ${currentDate.toString()}: $e');
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return results;
  }

  // Utility method to get stats for the last N days
  Future<List<StatsResponse>> getStatsForLastDays(int days) async {
    if (days <= 0) {
      throw Exception('Days must be greater than 0.');
    }
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));
    return getStatsForDateRange(startDate, endDate);
  }

  // Utility method to get weekly stats (last 7 days)
  Future<List<StatsResponse>> getWeeklyStats() async {
    return getStatsForLastDays(7);
  }

  // Utility method to get monthly stats (last 30 days)
  Future<List<StatsResponse>> getMonthlyStats() async {
    return getStatsForLastDays(30);
  }
}
