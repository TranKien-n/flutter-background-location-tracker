import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'location_storage_service.dart';
import 'location_tracking_service.dart';

class BackgroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    // Android needs a foreground service (with a visible notification) for reliable ongoing location.
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        foregroundServiceNotificationId: 1001,
        initialNotificationTitle: 'Background Location Active',
        initialNotificationContent: 'Tracking location in background',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
      ),
    );

    // If an old/stale service instance is still running (common during dev),
    // stop it so the next "Start Tracking" begins from a clean state.
    final isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('stopService');
    }
  }

  static Future<void> start() async {
    final isRunning = await _service.isRunning();

    if (isRunning) {
        return;
    }
    
    await _service.startService();
    }

  static Future<void> stop() async {
    _service.invoke('stopService');
  }

  static Future<bool> isRunning() {
    return _service.isRunning();
  }
}

// Keeps this symbol when tree-shaking; the native side starts it outside the main isolate.
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Background isolate: same plugins as the UI, but needs its own binding init first.
  WidgetsFlutterBinding.ensureInitialized();
  dev.log('background service onStart()', name: 'BackgroundServiceManager');

  final storageService = LocationStorageService();
  final trackingService = LocationTrackingService(storageService);

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: 'Background Location Active',
      content: 'Tracking location in background',
    );
  }

  service.on('stopService').listen((event) async {
    dev.log('stopService received', name: 'BackgroundServiceManager');
    await trackingService.stopTracking();
    await service.stopSelf();
  });

  await trackingService.startTracking(
    onLocationUpdate: (record) {
      dev.log(
        'sending locationUpdate to UI',
        name: 'BackgroundServiceManager',
        error:
            'lat=${record.latitude}, lon=${record.longitude}, acc=${record.accuracy}, speed=${record.speed}, '
            'time=${record.timestamp.toIso8601String()}, mocked=${record.isMocked}',
      );
      service.invoke(
        'locationUpdate',
        {
          'latitude': record.latitude,
          'longitude': record.longitude,
          'accuracy': record.accuracy,
          'speed': record.speed,
          'timestamp': record.timestamp.toIso8601String(),
          'isMocked': record.isMocked,
        },
      );
    },
  );
}