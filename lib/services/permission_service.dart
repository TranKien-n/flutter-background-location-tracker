import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ask when-in-use before always—Android 10+ expects that order for background/“always” access.
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
    // Typically shown after when-in-use is granted; user may still need to pick “Allow all the time”.
    return Permission.locationAlways.request();
  }

  Future<PermissionStatus> notificationStatus() {
    return Permission.notification.status;
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