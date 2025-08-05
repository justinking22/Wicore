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

  StatsNotifier(this._repository, this._ref) : super(const StatsState());

  Future<void> loadTodayStats({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);

    print(
      '🔧 Stats - Auth check - isAuthenticated: ${authState.isAuthenticated}',
    );

    // Enhanced authentication check
    if (!authState.isAuthenticated) {
      print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    print('🔧 ✅ Loading today\'s stats');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
      timeRange: StatsTimeRange.today,
    );

    try {
      // Ensure we have a valid token before making the request
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

      if (response.code == 0) {
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month}-${today.day}';

        state = state.copyWith(
          currentStats: response,
          isLoading: false,
          isRefreshing: false,
          error: null,
          selectedDate: todayString,
          timeRange: StatsTimeRange.today,
        );
        print('🔧 ✅ Loaded today\'s stats successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Failed to load stats: ${response.code}',
        );
      }
    } catch (e) {
      print('🔧 ❌ Error loading today\'s stats: $e');

      // Check if it's an authentication error
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
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadStatsForDate(String date, {bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);

    if (!authState.isAuthenticated) {
      print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    print('🔧 ✅ Loading stats for date: $date');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
      timeRange: StatsTimeRange.custom,
    );

    try {
      // Ensure we have a valid token before making the request
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

      if (response.code == 0) {
        state = state.copyWith(
          currentStats: response,
          isLoading: false,
          isRefreshing: false,
          error: null,
          selectedDate: date,
          timeRange: StatsTimeRange.custom,
        );
        print('🔧 ✅ Loaded stats for $date successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Failed to load stats for $date: ${response.code}',
        );
      }
    } catch (e) {
      print('🔧 ❌ Error loading stats for $date: $e');

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
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadWeeklyStats({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);

    if (!authState.isAuthenticated) {
      print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    print('🔧 ✅ Loading weekly stats');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
      timeRange: StatsTimeRange.week,
    );

    try {
      // Ensure we have a valid token before making the request
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
      final todayStats = weeklyStats.isNotEmpty ? weeklyStats.last : null;

      state = state.copyWith(
        currentStats: todayStats,
        historicalStats: weeklyStats,
        isLoading: false,
        isRefreshing: false,
        error: null,
        timeRange: StatsTimeRange.week,
      );
      print('🔧 ✅ Loaded ${weeklyStats.length} days of weekly stats');
    } catch (e) {
      print('🔧 ❌ Error loading weekly stats: $e');

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
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadMonthlyStats({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.watch(authNotifierProvider);

    if (!authState.isAuthenticated) {
      print('🔧 ❌ Stats authentication failed');
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
        isRefreshing: false,
      );
      return;
    }

    print('🔧 ✅ Loading monthly stats');

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
      timeRange: StatsTimeRange.month,
    );

    try {
      // Ensure we have a valid token before making the request
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
      final latestStats = monthlyStats.isNotEmpty ? monthlyStats.last : null;

      state = state.copyWith(
        currentStats: latestStats,
        historicalStats: monthlyStats,
        isLoading: false,
        isRefreshing: false,
        error: null,
        timeRange: StatsTimeRange.month,
      );
      print('🔧 ✅ Loaded ${monthlyStats.length} days of monthly stats');
    } catch (e) {
      print('🔧 ❌ Error loading monthly stats: $e');

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
