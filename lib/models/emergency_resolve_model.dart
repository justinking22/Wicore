import 'package:json_annotation/json_annotation.dart';

part 'emergency_resolve_model.g.dart';

// Emergency item model matching your API response structure
@JsonSerializable()
class EmergencyItem {
  final String updated;
  final int resolved;
  final String userName;
  final String created;
  final String uId;
  final String userPhoneNumber;
  final String dId;

  const EmergencyItem({
    required this.updated,
    required this.resolved,
    required this.userName,
    required this.created,
    required this.uId,
    required this.userPhoneNumber,
    required this.dId,
  });

  factory EmergencyItem.fromJson(Map<String, dynamic> json) =>
      _$EmergencyItemFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyItemToJson(this);

  // Helper to check if emergency is resolved
  bool get isResolved => resolved == 1;
}

// Emergency data container matching your nested "data" structure
@JsonSerializable()
class EmergencyData {
  final List<EmergencyItem> data;
  final int code;

  const EmergencyData({required this.data, required this.code});

  factory EmergencyData.fromJson(Map<String, dynamic> json) =>
      _$EmergencyDataFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyDataToJson(this);
}

// Main response model matching your exact API response: {"data": {"data": [...], "code": 0}, "code": 0}
@JsonSerializable()
class EmergencyResolveResponse {
  final EmergencyData data;
  final int code;

  const EmergencyResolveResponse({required this.data, required this.code});

  factory EmergencyResolveResponse.fromJson(Map<String, dynamic> json) =>
      _$EmergencyResolveResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyResolveResponseToJson(this);

  // Helper to check if the API call was successful
  bool get isSuccess => code == 0 && data.code == 0;

  // Helper to get the list of emergency items
  List<EmergencyItem> get emergencyItems => data.data;
}
