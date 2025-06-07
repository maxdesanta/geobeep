class StationModel {
  final String id;
  final String name;
  final String line;
  final double latitude;
  final double longitude;
  final bool isAlarmActive;
  final int radiusInMeters;
  final bool isFavorite;
  final int? alarmRadius;
 
  StationModel({
    required this.id,
    required this.name,
    required this.line,
    required this.latitude,
    required this.longitude,
    this.isAlarmActive = false,
    this.radiusInMeters = 100,
    this.isFavorite = false,

    required this.alarmRadius,
  });

  StationModel copyWith({
    String? id,
    String? name,
    String? line,
    double? latitude,
    double? longitude,
    bool? isAlarmActive,
    int? radiusInMeters,
    bool? isFavorite,
    int? alarmRadius,
  }) {
    return StationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      line: line ?? this.line,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      isFavorite: isFavorite ?? this.isFavorite,
      alarmRadius: alarmRadius ?? this.alarmRadius,
    );
  }
}
