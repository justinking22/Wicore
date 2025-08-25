import 'package:Wicore/models/stats_request_model.dart';
import 'package:Wicore/models/stats_response_model.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/repository/stats_repository.dart';
import 'package:Wicore/services/stats_api_client.dart';
import 'package:Wicore/states/stats_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stats API client provider
final statsApiClientProvider = Provider<StatsApiClient>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return StatsApiClient(dio);
});

// Stats repository provider
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final apiClient = ref.watch(statsApiClientProvider);
  return StatsRepository(apiClient, ref);
});

// Stats notifier class
class StatsNotifier extends StateNotifier<StatsState> {
  final StatsRepository _repository;
  final Ref _ref;

  // Cache management
  final Map<String, StatsResponse> _statsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(
    minutes: 5,
  ); // Cache valid for 5 minutes
  static const Duration _currentDateCacheValidDuration = Duration(
    minutes: 1,
  ); // Current date cache valid for 1 minute

  StatsNotifier(this._repository, this._ref) : super(const StatsState());

  Future<void> loadTodayStats({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);
    if (kDebugMode) {
      print(
        '🔧 Stats - Auth check - isAuthenticated: ${authState.isAuthenticated}',
      );
    }

    if (!authState.isAuthenticated) {
      if (kDebugMode) print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    if (kDebugMode) print('🔧 ✅ Loading today\'s stats');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
      timeRange: StatsTimeRange.today,
    );

    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'No valid authentication token available',
        );
        return;
      }

      final response = await _repository.getTodayStats();
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';

      // Update cache
      if (response.data != null) {
        _statsCache[todayString] = response;
        _cacheTimestamps[todayString] = DateTime.now();
      }

      state = state.copyWith(
        currentStats: response.data != null ? response : null,
        isLoading: false,
        isRefreshing: false,
        error: null,
        selectedDate: todayString,
        timeRange: StatsTimeRange.today,
      );
      if (kDebugMode) print('🔧 ✅ Loaded today\'s stats successfully');
    } catch (e) {
      if (kDebugMode) print('🔧 ❌ Error loading today\'s stats: $e');
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Authentication failed. Please sign in again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          currentStats: null,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadStatsForDate(
    String date, {
    bool forceRefresh = false,
  }) async {
    if (state.isLoading && !forceRefresh) return;

    final authState = _ref.watch(authNotifierProvider);
    if (kDebugMode) {
      print(
        '🔧 Stats - Auth check for date $date - isAuthenticated: ${authState.isAuthenticated}',
      );
    }

    if (!authState.isAuthenticated) {
      if (kDebugMode) print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    // Check if we can use cached data
    if (!forceRefresh && _shouldUseCachedData(date)) {
      if (kDebugMode) print('🔧 📱 Using cached data for date: $date');
      final cachedResponse = _statsCache[date]!;
      state = state.copyWith(
        currentStats: cachedResponse,
        isLoading: false,
        isRefreshing: false,
        error: null,
        selectedDate: date,
        timeRange: StatsTimeRange.custom,
      );
      return;
    }

    if (kDebugMode) {
      print(
        '🔧 ✅ Loading stats for date: $date ${forceRefresh ? '(force refresh)' : ''}',
      );
    }

    state = state.copyWith(
      isLoading: !forceRefresh,
      isRefreshing: forceRefresh,
      error: null,
      timeRange: StatsTimeRange.custom,
    );

    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'No valid authentication token available',
        );
        return;
      }

      final request = StatsRequest(date: date);
      final response = await _repository.getStats(request);

      // Update cache
      if (response.data != null) {
        _statsCache[date] = response;
        _cacheTimestamps[date] = DateTime.now();
        if (kDebugMode) print('🔧 📱 Cached data for date: $date');
      }

      state = state.copyWith(
        currentStats: response.data != null ? response : null,
        isLoading: false,
        isRefreshing: false,
        error: null,
        selectedDate: date,
        timeRange: StatsTimeRange.custom,
      );
      if (kDebugMode) print('🔧 ✅ Loaded stats for $date successfully');
    } catch (e) {
      if (kDebugMode) print('🔧 ❌ Error loading stats for $date: $e');
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Authentication failed. Please sign in again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          currentStats: null,
          error: e.toString(),
        );
      }
    }
  }

  bool _shouldUseCachedData(String date) {
    if (!_statsCache.containsKey(date) || !_cacheTimestamps.containsKey(date)) {
      return false;
    }

    final now = DateTime.now();
    final cacheTime = _cacheTimestamps[date]!;
    final currentDateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Use shorter cache duration for current date, longer for historical dates
    final validDuration =
        date == currentDateString
            ? _currentDateCacheValidDuration
            : _cacheValidDuration;

    final isValid = now.difference(cacheTime) < validDuration;

    if (kDebugMode) {
      print(
        '🔧 📱 Cache check for $date: ${isValid ? 'VALID' : 'EXPIRED'} (age: ${now.difference(cacheTime).inMinutes} min)',
      );
    }

    return isValid;
  }

  void clearCache() {
    _statsCache.clear();
    _cacheTimestamps.clear();
    if (kDebugMode) print('🔧 🗑️ Stats cache cleared');
  }

  void clearCacheForDate(String date) {
    _statsCache.remove(date);
    _cacheTimestamps.remove(date);
    if (kDebugMode) print('🔧 🗑️ Stats cache cleared for date: $date');
  }

  Future<void> loadWeeklyStats({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);
    if (kDebugMode)
      print(
        '🔧 Stats - Auth check for weekly - isAuthenticated: ${authState.isAuthenticated}',
      );

    if (!authState.isAuthenticated) {
      if (kDebugMode) print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    if (kDebugMode) print('🔧 ✅ Loading weekly stats');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
      timeRange: StatsTimeRange.week,
    );

    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'No valid authentication token available',
        );
        return;
      }

      final weeklyStats = await _repository.getWeeklyStats();
      final validWeeklyStats =
          weeklyStats.where((stats) => stats.data != null).toList();
      final todayStats =
          validWeeklyStats.isNotEmpty ? validWeeklyStats.last : null;

      state = state.copyWith(
        currentStats: todayStats,
        historicalStats: validWeeklyStats,
        isLoading: false,
        isRefreshing: false,
        error: null,
        timeRange: StatsTimeRange.week,
      );
      if (kDebugMode)
        print('🔧 ✅ Loaded ${validWeeklyStats.length} days of weekly stats');
    } catch (e) {
      if (kDebugMode) print('🔧 ❌ Error loading weekly stats: $e');
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Authentication failed. Please sign in again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          currentStats: null,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadMonthlyStats({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);
    if (kDebugMode)
      print(
        '🔧 Stats - Auth check for monthly - isAuthenticated: ${authState.isAuthenticated}',
      );

    if (!authState.isAuthenticated) {
      if (kDebugMode) print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    if (kDebugMode) print('🔧 ✅ Loading monthly stats');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
      timeRange: StatsTimeRange.month,
    );

    try {
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      final token = await authNotifier.getValidToken();
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'No valid authentication token available',
        );
        return;
      }

      final monthlyStats = await _repository.getMonthlyStats();
      final validMonthlyStats =
          monthlyStats.where((stats) => stats.data != null).toList();
      final latestStats =
          validMonthlyStats.isNotEmpty ? validMonthlyStats.last : null;

      state = state.copyWith(
        currentStats: latestStats,
        historicalStats: validMonthlyStats,
        isLoading: false,
        isRefreshing: false,
        error: null,
        timeRange: StatsTimeRange.month,
      );
      if (kDebugMode)
        print('🔧 ✅ Loaded ${validMonthlyStats.length} days of monthly stats');
    } catch (e) {
      if (kDebugMode) print('🔧 ❌ Error loading monthly stats: $e');
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        _ref.read(authNotifierProvider.notifier).setUnauthenticated();
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Authentication failed. Please sign in again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          currentStats: null,
          error: e.toString(),
        );
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearState() {
    state = const StatsState();
    clearCache(); // Also clear cache when clearing state
  }

  void setTimeRange(StatsTimeRange timeRange) {
    state = state.copyWith(timeRange: timeRange);
  }
}

// Stats state notifier provider
final statsNotifierProvider = StateNotifierProvider<StatsNotifier, StatsState>((
  ref,
) {
  final repository = ref.watch(statsRepositoryProvider);
  return StatsNotifier(repository, ref);
});

// Convenience providers for specific data
final currentStatsProvider = Provider<StatsResponse?>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.currentStats;
});

final postureScoreProvider = Provider<int>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.postureScore;
});

final totalStepsProvider = Provider<int>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.totalSteps;
});

final totalCaloriesProvider = Provider<int>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.totalCalories;
});

final postureGradeProvider = Provider<String>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.postureGrade;
});

final historicalStatsProvider = Provider<List<StatsResponse>>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.historicalStats;
});

final weeklyStepsProvider = Provider<List<int>>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.weeklySteps;
});

final weeklyCaloriesProvider = Provider<List<int>>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.weeklyCalories;
});

final weeklyPostureScoresProvider = Provider<List<int>>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.weeklyPostureScores;
});

final averagePostureScoreProvider = Provider<double>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.averagePostureScore;
});

final averageDailyStepsProvider = Provider<double>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.averageDailySteps;
});

final averageDailyCaloriesProvider = Provider<double>((ref) {
  final state = ref.watch(statsNotifierProvider);
  return state.averageDailyCalories;
});
