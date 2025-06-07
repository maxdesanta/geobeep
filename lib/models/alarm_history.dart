import 'dart:convert';

class AlarmHistory {
  final String stationId;
  final String stationName;
  final DateTime triggeredAt;
  final double latitude;
  final double longitude;

  AlarmHistory({
    required this.stationId,
    required this.stationName,
    required this.triggeredAt,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'stationName': stationName,
      'triggeredAt': triggeredAt.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory AlarmHistory.fromMap(Map<String, dynamic> map) {
    return AlarmHistory(
      stationId: map['stationId'] ?? '',
      stationName: map['stationName'] ?? '',
      triggeredAt: DateTime.fromMillisecondsSinceEpoch(map['triggeredAt']),
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlarmHistory.fromJson(String source) =>
      AlarmHistory.fromMap(json.decode(source));
}
