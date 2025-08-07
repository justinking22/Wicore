import 'package:json_annotation/json_annotation.dart';

part 'stats_response_model.g.dart';

@JsonSerializable()
class StatsResponse {
  @JsonKey(defaultValue: null)
  final StatsData? data;
  final int code;

  const StatsResponse({required this.data, required this.code});

  factory StatsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StatsResponseToJson(this);
}

@JsonSerializable()
class StatsData {
  @JsonKey(defaultValue: 0.0)
  final double? bentMeanDuration;
  @JsonKey(defaultValue: 0)
  final int? postureScore;
  @JsonKey(defaultValue: '')
  final String? dataEndTime;
  @JsonKey(defaultValue: 0)
  final int? breathDataPoints;
  @JsonKey(defaultValue: 0.0)
  final double? torsoAngleMinAvg;
  @JsonKey(defaultValue: 0)
  final int? dataLength;
  @JsonKey(defaultValue: 0)
  final int? lmaCalories;
  @JsonKey(defaultValue: '')
  final String? uId;
  @JsonKey(defaultValue: 0)
  final int? totalLmaCount;
  @JsonKey(defaultValue: 0.0)
  final double? breathStd;
  @JsonKey(defaultValue: '')
  final String? updated;
  @JsonKey(defaultValue: 0)
  final int? totalSteps;
  @JsonKey(defaultValue: 0)
  final int? totalCalories;
  @JsonKey(defaultValue: 0.0)
  final double? breathMean;
  @JsonKey(defaultValue: 0.0)
  final double? torsoAngleMeanAvg;
  @JsonKey(defaultValue: 0.0)
  final double? totalDistance;
  @JsonKey(defaultValue: '')
  final String? postureGrade;
  @JsonKey(defaultValue: '')
  final String? dataStartTime;
  @JsonKey(defaultValue: '')
  final String? dId;
  @JsonKey(defaultValue: '')
  final String? created;

  const StatsData({
    this.bentMeanDuration,
    this.postureScore,
    this.dataEndTime,
    this.breathDataPoints,
    this.torsoAngleMinAvg,
    this.dataLength,
    this.lmaCalories,
    this.uId,
    this.totalLmaCount,
    this.breathStd,
    this.updated,
    this.totalSteps,
    this.totalCalories,
    this.breathMean,
    this.torsoAngleMeanAvg,
    this.totalDistance,
    this.postureGrade,
    this.dataStartTime,
    this.dId,
    this.created,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) =>
      _$StatsDataFromJson(json);

  Map<String, dynamic> toJson() => _$StatsDataToJson(this);
}
