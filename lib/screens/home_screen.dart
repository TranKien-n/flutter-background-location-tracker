import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/location_record.dart';

import '../services/location_storage_service.dart';
import '../services/permission_service.dart';
import '../services/background_service_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final LocationStorageService _storageService = LocationStorageService();
  final PermissionService _permissionService = PermissionService();
  StreamSubscription? _serviceSubscription;

  bool _isTracking = false;
  bool _locationServiceEnabled = false;

  PermissionStatus? _foregroundPermission;
  PermissionStatus? _backgroundPermission;

  List<LocationRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadPermissionStatus();

    _serviceSubscription = FlutterBackgroundService()
        .on('locationUpdate')
        .listen((event) async {
      dev.log(
        'UI received locationUpdate',
        name: 'HomeScreen',
        error: event,
      );
      // Every update is already saved by the background isolate.
      // Reload to reflect saved records.
      await _loadRecords();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadRecords() async {
    dev.log('UI reloading records...', name: 'HomeScreen');
    final records = await _storageService.getRecords();

    if (!mounted) return;

    setState(() {
      _records = records;
    });

    dev.log(
      'UI records reloaded (count=${records.length})',
      name: 'HomeScreen',
    );
  }

  Future<void> _loadPermissionStatus() async {
    final serviceEnabled = await _permissionService.isLocationServiceEnabled();
    final foreground = await _permissionService.foregroundStatus();
    final background = await _permissionService.backgroundStatus();

    if (!mounted) return;

    setState(() {
      _locationServiceEnabled = serviceEnabled;
      _foregroundPermission = foreground;
      _backgroundPermission = background;
    });
  }

  Future<void> _requestPermissions() async {
    await _permissionService.requestForegroundLocation();
    await _permissionService.requestBackgroundLocation();
    await _permissionService.requestNotificationPermission();
    await _loadPermissionStatus();
  }

  Future<void> _clearRecords() async {
    await _storageService.clearRecords();
    await _loadRecords();
  }

  Future<void> _startTracking() async {
    await _loadPermissionStatus();

    if (!_locationServiceEnabled ||
        _foregroundPermission == null ||
        !_foregroundPermission!.isGranted) {
      return;
    }

    await BackgroundServiceManager.start();

    if (!mounted) return;

    setState(() {
      _isTracking = true;
    });

    await _loadRecords();
  }

  Future<void> _stopTracking() async {
    await BackgroundServiceManager.stop();

    if (!mounted) return;

    setState(() {
      _isTracking = false;
    });

    await _loadRecords();
  }

  String _permissionLabel(PermissionStatus? status) {
    if (status == null) return 'checking...';
    return status.name;
  }

  // Stop tracking when the screen is disposed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      dev.log('app resumed -> reload records/permissions', name: 'HomeScreen');
      _loadRecords();
      _loadPermissionStatus();
    }
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _isTracking ? 'Tracking active' : 'Tracking stopped';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Location'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadRecords();
          await _loadPermissionStatus();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Location service: '
                      '${_locationServiceEnabled ? "enabled" : "disabled"}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Foreground permission: '
                      '${_permissionLabel(_foregroundPermission)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Background permission: '
                      '${_permissionLabel(_backgroundPermission)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _requestPermissions,
              child: const Text('Request Location Permissions'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isTracking ? null : _startTracking,
                    child: const Text('Start Tracking'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTracking ? _stopTracking : null,
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _records.isEmpty ? null : _clearRecords,
              child: const Text('Clear Saved Logs'),
            ),
            const SizedBox(height: 24),
            Text(
              'Saved Location Updates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_records.isEmpty)
              const Text('No location updates saved yet.')
            else
              ..._records.map(
                (record) => Card(
                  child: ListTile(
                    title: Text(
                      '${record.latitude.toStringAsFixed(6)}, '
                      '${record.longitude.toStringAsFixed(6)}',
                    ),
                    subtitle: Text(
                      'Accuracy: ${record.accuracy.toStringAsFixed(1)}m',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}