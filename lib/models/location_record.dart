class LocationRecord {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final DateTime timestamp;
  final bool isMocked;

  const LocationRecord({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.timestamp,
    required this.isMocked,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'isMocked': isMocked,
    };
  }

  factory LocationRecord.fromJson(Map<String, dynamic> json) {
    return LocationRecord(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMocked: json['isMocked'] as bool? ?? false,
    );
  }
}