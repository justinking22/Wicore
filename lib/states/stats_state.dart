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

  bool get hasData => currentStats != null && currentStats!.data != null;
  bool get hasError => error != null;
  bool get hasHistoricalData => historicalStats.isNotEmpty;

  StatsData? get statsData => currentStats?.data;

  int get postureScore => statsData?.postureScore ?? 0;
  String get postureGrade => statsData?.postureGrade ?? 'N/A';
  double get bentMeanDuration => statsData?.bentMeanDuration ?? 0.0;
  double get torsoAngleMeanAvg => statsData?.torsoAngleMeanAvg ?? 0.0;
  double get torsoAngleMinAvg => statsData?.torsoAngleMinAvg ?? 0.0;

  int get totalSteps => statsData?.totalSteps ?? 0;
  int get totalCalories => statsData?.totalCalories ?? 0;
  int get lmaCalories => statsData?.lmaCalories ?? 0;
  int get totalLmaCount => statsData?.totalLmaCount ?? 0;
  double get totalDistance => statsData?.totalDistance ?? 0.0;

  double get breathMean => statsData?.breathMean ?? 0.0;
  double get breathStd => statsData?.breathStd ?? 0.0;
  int get breathDataPoints => statsData?.breathDataPoints ?? 0;

  int get dataLength => statsData?.dataLength ?? 0;
  String get dataStartTime => statsData?.dataStartTime ?? '';
  String get dataEndTime => statsData?.dataEndTime ?? '';
  String get userId => statsData?.uId ?? '';
  String get deviceId => statsData?.dId ?? '';

  List<int> get weeklySteps {
    if (historicalStats.isEmpty) return [];
    return historicalStats.map((stats) => stats.data?.totalSteps ?? 0).toList();
  }

  List<int> get weeklyCalories {
    if (historicalStats.isEmpty) return [];
    return historicalStats
        .map((stats) => stats.data?.totalCalories ?? 0)
        .toList();
  }

  List<int> get weeklyPostureScores {
    if (historicalStats.isEmpty) return [];
    return historicalStats
        .map((stats) => stats.data?.postureScore ?? 0)
        .toList();
  }

  double get averagePostureScore {
    final scores = weeklyPostureScores;
    return scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
  }

  double get averageDailySteps {
    final steps = weeklySteps;
    return steps.isEmpty ? 0.0 : steps.reduce((a, b) => a + b) / steps.length;
  }

  double get averageDailyCalories {
    final calories = weeklyCalories;
    return calories.isEmpty
        ? 0.0
        : calories.reduce((a, b) => a + b) / calories.length;
  }
}

enum StatsTimeRange { today, week, month, custom }
