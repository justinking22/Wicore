import 'package:json_annotation/json_annotation.dart';

part 'stats_response_model.g.dart';

@JsonSerializable()
class StatsResponse {
  final StatsData data;
  final int code;

  const StatsResponse({required this.data, required this.code});

  factory StatsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StatsResponseToJson(this);
}

@JsonSerializable()
class StatsData {
  final double bentMeanDuration;
  final int postureScore;
  final String dataEndTime;
  final int breathDataPoints;
  final double torsoAngleMinAvg;
  final int dataLength;
  final int lmaCalories;
  final String uId;
  final int totalLmaCount;
  final double breathStd;
  final String updated;
  final int totalSteps;
  final int totalCalories;
  final double breathMean;
  final double torsoAngleMeanAvg;
  final double totalDistance;
  final String postureGrade;
  final String dataStartTime;
  final String dId;
  final String created;

  const StatsData({
    required this.bentMeanDuration,
    required this.postureScore,
    required this.dataEndTime,
    required this.breathDataPoints,
    required this.torsoAngleMinAvg,
    required this.dataLength,
    required this.lmaCalories,
    required this.uId,
    required this.totalLmaCount,
    required this.breathStd,
    required this.updated,
    required this.totalSteps,
    required this.totalCalories,
    required this.breathMean,
    required this.torsoAngleMeanAvg,
    required this.totalDistance,
    required this.postureGrade,
    required this.dataStartTime,
    required this.dId,
    required this.created,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) =>
      _$StatsDataFromJson(json);

  Map<String, dynamic> toJson() => _$StatsDataToJson(this);
}
