import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<PermissionStatus> foregroundStatus() {
    return Permission.locationWhenInUse.status;
  }

  Future<PermissionStatus> backgroundStatus() {
    return Permission.locationAlways.status;
  }

  Future<PermissionStatus> requestForegroundLocation() {
    return Permission.locationWhenInUse.request();
  }

  Future<PermissionStatus> requestBackgroundLocation() {
    return Permission.locationAlways.request();
  }

  Future<PermissionStatus> requestNotificationPermission() {
    return Permission.notification.request();
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  bool get supportsBackgroundLocationPermission {
    return Platform.isAndroid || Platform.isIOS;
  }
}