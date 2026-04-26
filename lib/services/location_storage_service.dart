import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_record.dart';

class LocationStorageService {
  static const String _recordsKey = 'location_records';

  // Treat updates as duplicates if they are effectively the same point in time/space.
  // This prevents log spam from rapid stream emissions or multiple connected engines.
  static const int _dedupeWindowSeconds = 60;
  static const double _dedupeDistanceMeters = 5.0;
  static const int _dedupeMaxRecentToCheck = 8;

  double _distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Haversine formula.
    const earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  bool _isDuplicate(LocationRecord record, List<LocationRecord> records) {
    if (records.isEmpty) return false;

    final recent = records.take(_dedupeMaxRecentToCheck);
    for (final existing in recent) {
      // Strongest signal: same timestamp (or within 1s) and extremely close coords.
      final timeDifferenceSeconds =
          existing.timestamp.difference(record.timestamp).abs().inSeconds;

      final distance = _distanceMeters(
        lat1: existing.latitude,
        lon1: existing.longitude,
        lat2: record.latitude,
        lon2: record.longitude,
      );

      if (timeDifferenceSeconds <= 1 && distance <= 1.0) {
        return true;
      }

      // General de-dupe: essentially same place within a short time window.
      if (timeDifferenceSeconds <= _dedupeWindowSeconds &&
          distance <= _dedupeDistanceMeters) {
        return true;
      }
    }

    return false;
  }

  Future<void> saveRecord(LocationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();

    final isDuplicate = _isDuplicate(record, records);

    if (isDuplicate) {
      dev.log(
        'saveRecord() skipped duplicate',
        name: 'LocationStorageService',
        error:
            'lat=${record.latitude}, lon=${record.longitude}, time=${record.timestamp.toIso8601String()}',
      );
      return;
    }

    records.insert(0, record);

    final limitedRecords = records.take(100).toList();

    final encodedRecords = limitedRecords
        .map((record) => record.toJson())
        .toList();

    await prefs.setString(_recordsKey, jsonEncode(encodedRecords));
    dev.log(
      'saveRecord() stored (count=${limitedRecords.length})',
      name: 'LocationStorageService',
      error:
          'lat=${record.latitude}, lon=${record.longitude}, time=${record.timestamp.toIso8601String()}',
    );
  }

  Future<List<LocationRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();

    // This forces the UI isolate to read the latest saved values.
    await prefs.reload();

    final rawRecords = prefs.getString(_recordsKey);

    if (rawRecords == null || rawRecords.isEmpty) {
      return [];
    }

    final decodedRecords = jsonDecode(rawRecords) as List<dynamic>;

    return decodedRecords
        .map(
          (item) => LocationRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }
}