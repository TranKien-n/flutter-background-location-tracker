import 'dart:async';
import 'dart:developer' as dev;

import 'package:geolocator/geolocator.dart';

import '../models/location_record.dart';
import 'location_storage_service.dart';

class LocationTrackingService {
  final LocationStorageService _storageService;

  StreamSubscription<Position>? _positionSubscription;

  LocationTrackingService(this._storageService);

  bool get isTracking => _positionSubscription != null;

  Future<void> startTracking({
    required void Function(LocationRecord record) onLocationUpdate,
  }) async {
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      // 0 m: don't suppress fixes when idle or on emulator; larger values hide most updates.
      distanceFilter: 0,
    );

    await stopTracking();

    // Push-based: OS sends each new/refined position; we filter duplicates only at save time.
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) async {
      dev.log(
        'position stream event',
        name: 'LocationTrackingService',
        error:
            'lat=${position.latitude}, lon=${position.longitude}, acc=${position.accuracy}, '
            'speed=${position.speed}, time=${position.timestamp.toIso8601String()}, '
            'mocked=${position.isMocked}',
      );

      final record = LocationRecord(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        timestamp: position.timestamp,
        isMocked: position.isMocked,
      );

      await _storageService.saveRecord(record);
      onLocationUpdate(record);
    }, onError: (Object error, StackTrace stackTrace) {
      dev.log(
        'position stream error',
        name: 'LocationTrackingService',
        error: error,
        stackTrace: stackTrace,
      );
    });

    dev.log(
      'started position stream (accuracy=high, distanceFilter=0)',
      name: 'LocationTrackingService',
    );
  }

  Future<void> stopTracking() async {
    dev.log('stopping position stream', name: 'LocationTrackingService');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}