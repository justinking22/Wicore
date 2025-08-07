// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatsResponse _$StatsResponseFromJson(Map<String, dynamic> json) =>
    StatsResponse(
      data: json['data'] == null
          ? null
          : StatsData.fromJson(json['data'] as Map<String, dynamic>),
      code: (json['code'] as num).toInt(),
    );

Map<String, dynamic> _$StatsResponseToJson(StatsResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'code': instance.code,
    };

StatsData _$StatsDataFromJson(Map<String, dynamic> json) => StatsData(
      bentMeanDuration: (json['bentMeanDuration'] as num?)?.toDouble() ?? 0.0,
      postureScore: (json['postureScore'] as num?)?.toInt() ?? 0,
      dataEndTime: json['dataEndTime'] as String? ?? '',
      breathDataPoints: (json['breathDataPoints'] as num?)?.toInt() ?? 0,
      torsoAngleMinAvg: (json['torsoAngleMinAvg'] as num?)?.toDouble() ?? 0.0,
      dataLength: (json['dataLength'] as num?)?.toInt() ?? 0,
      lmaCalories: (json['lmaCalories'] as num?)?.toInt() ?? 0,
      uId: json['uId'] as String? ?? '',
      totalLmaCount: (json['totalLmaCount'] as num?)?.toInt() ?? 0,
      breathStd: (json['breathStd'] as num?)?.toDouble() ?? 0.0,
      updated: json['updated'] as String? ?? '',
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toInt() ?? 0,
      breathMean: (json['breathMean'] as num?)?.toDouble() ?? 0.0,
      torsoAngleMeanAvg: (json['torsoAngleMeanAvg'] as num?)?.toDouble() ?? 0.0,
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0.0,
      postureGrade: json['postureGrade'] as String? ?? '',
      dataStartTime: json['dataStartTime'] as String? ?? '',
      dId: json['dId'] as String? ?? '',
      created: json['created'] as String? ?? '',
    );

Map<String, dynamic> _$StatsDataToJson(StatsData instance) => <String, dynamic>{
      'bentMeanDuration': instance.bentMeanDuration,
      'postureScore': instance.postureScore,
      'dataEndTime': instance.dataEndTime,
      'breathDataPoints': instance.breathDataPoints,
      'torsoAngleMinAvg': instance.torsoAngleMinAvg,
      'dataLength': instance.dataLength,
      'lmaCalories': instance.lmaCalories,
      'uId': instance.uId,
      'totalLmaCount': instance.totalLmaCount,
      'breathStd': instance.breathStd,
      'updated': instance.updated,
      'totalSteps': instance.totalSteps,
      'totalCalories': instance.totalCalories,
      'breathMean': instance.breathMean,
      'torsoAngleMeanAvg': instance.torsoAngleMeanAvg,
      'totalDistance': instance.totalDistance,
      'postureGrade': instance.postureGrade,
      'dataStartTime': instance.dataStartTime,
      'dId': instance.dId,
      'created': instance.created,
    };
