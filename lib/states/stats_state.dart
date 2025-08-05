import 'package:Wicore/models/stats_response_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_state.freezed.dart';

@freezed
class StatsState with _$StatsState {
  const factory StatsState({
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    StatsResponse? currentStats,
    @Default([]) List<StatsResponse> historicalStats,
    String? error,
    String? selectedDate,
    @Default(StatsTimeRange.today) StatsTimeRange timeRange,
  }) = _StatsState;

  const StatsState._();

  bool get hasData => currentStats != null;
  bool get hasError => error != null;
  bool get hasHistoricalData => historicalStats.isNotEmpty;

  // Convenience getters for current stats data
  StatsData? get statsData => currentStats?.data;

  // Posture related getters
  int get postureScore => statsData?.postureScore ?? 0;
  String get postureGrade => statsData?.postureGrade ?? 'N/A';
  double get bentMeanDuration => statsData?.bentMeanDuration ?? 0.0;
  double get torsoAngleMeanAvg => statsData?.torsoAngleMeanAvg ?? 0.0;
  double get torsoAngleMinAvg => statsData?.torsoAngleMinAvg ?? 0.0;

  // Activity related getters
  int get totalSteps => statsData?.totalSteps ?? 0;
  int get totalCalories => statsData?.totalCalories ?? 0;
  int get lmaCalories => statsData?.lmaCalories ?? 0;
  int get totalLmaCount => statsData?.totalLmaCount ?? 0;
  double get totalDistance => statsData?.totalDistance ?? 0.0;

  // Breathing related getters
  double get breathMean => statsData?.breathMean ?? 0.0;
  double get breathStd => statsData?.breathStd ?? 0.0;
  int get breathDataPoints => statsData?.breathDataPoints ?? 0;

  // Data info getters
  int get dataLength => statsData?.dataLength ?? 0;
  String? get dataStartTime => statsData?.dataStartTime;
  String? get dataEndTime => statsData?.dataEndTime;
  String? get userId => statsData?.uId;
  String? get deviceId => statsData?.dId;

  // Helper methods for historical data analysis
  List<int> get weeklySteps {
    if (historicalStats.isEmpty) return [];
    return historicalStats.map((stats) => stats.data.totalSteps).toList();
  }

  List<int> get weeklyCalories {
    if (historicalStats.isEmpty) return [];
    return historicalStats.map((stats) => stats.data.totalCalories).toList();
  }

  List<int> get weeklyPostureScores {
    if (historicalStats.isEmpty) return [];
    return historicalStats.map((stats) => stats.data.postureScore).toList();
  }

  double get averagePostureScore {
    if (historicalStats.isEmpty) return 0.0;
    final scores = weeklyPostureScores;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double get averageDailySteps {
    if (historicalStats.isEmpty) return 0.0;
    final steps = weeklySteps;
    return steps.reduce((a, b) => a + b) / steps.length;
  }

  double get averageDailyCalories {
    if (historicalStats.isEmpty) return 0.0;
    final calories = weeklyCalories;
    return calories.reduce((a, b) => a + b) / calories.length;
  }
}

enum StatsTimeRange { today, week, month, custom }
