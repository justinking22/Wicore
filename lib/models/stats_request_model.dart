import 'package:json_annotation/json_annotation.dart';

part 'stats_request_model.g.dart';

@JsonSerializable()
class StatsRequest {
  final String date;

  const StatsRequest({required this.date});

  factory StatsRequest.fromJson(Map<String, dynamic> json) =>
      _$StatsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StatsRequestToJson(this);

  /// Helper method to create request with current date
  factory StatsRequest.today() {
    final now = DateTime.now();
    return StatsRequest(date: '${now.year}-${now.month}-${now.day}');
  }

  /// Helper method to create request with specific DateTime
  factory StatsRequest.fromDateTime(DateTime dateTime) {
    return StatsRequest(
      date: '${dateTime.year}-${dateTime.month}-${dateTime.day}',
    );
  }

  /// Validates date format (YYYY-M-D)
  bool isValidDateFormat() {
    final regex = RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$');
    return regex.hasMatch(date);
  }
}
