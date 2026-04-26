import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/location_record.dart';

import '../services/location_storage_service.dart';
import '../services/permission_service.dart';
import '../services/background_service_manager.dart';
import '../widgets/location_log_panel.dart';
import '../widgets/tracking_controls.dart';
import '../widgets/tracking_status_card.dart';

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
  PermissionStatus? _notificationPermission;

  List<LocationRecord> _records = [];
  bool _initialRecordsLoaded = false;
  DateTime? _lastListUpdated;

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
      await _loadRecords();
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTrackingFromService();
    });
  }

  Future<void> _syncTrackingFromService() async {
    final running = await BackgroundServiceManager.isRunning();
    if (!mounted) return;
    setState(() {
      _isTracking = running;
    });
  }

  Future<void> _loadRecords() async {
    dev.log('UI reloading records...', name: 'HomeScreen');
    final records = await _storageService.getRecords();

    if (!mounted) return;

    setState(() {
      _records = records;
      _initialRecordsLoaded = true;
      _lastListUpdated = DateTime.now();
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
    final notification = await _permissionService.notificationStatus();

    if (!mounted) return;

    setState(() {
      _locationServiceEnabled = serviceEnabled;
      _foregroundPermission = foreground;
      _backgroundPermission = background;
      _notificationPermission = notification;
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

  bool get _canStartTracking {
    return _locationServiceEnabled &&
        _foregroundPermission != null &&
        _foregroundPermission!.isGranted;
  }

  Future<void> _startTracking() async {
    await _loadPermissionStatus();

    if (!_canStartTracking) {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      dev.log('app resumed -> reload records/permissions', name: 'HomeScreen');
      _syncTrackingFromService();
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location tracker'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadRecords(),
            _loadPermissionStatus(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TrackingStatusCard(
                  isTracking: _isTracking,
                  locationServiceEnabled: _locationServiceEnabled,
                  foregroundPermission: _foregroundPermission,
                  backgroundPermission: _backgroundPermission,
                  notificationPermission: _notificationPermission,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TrackingControls(
                  isTracking: _isTracking,
                  canStart: _canStartTracking,
                  hasRecords: _records.isNotEmpty,
                  onRequestPermissions: _requestPermissions,
                  onStart: _startTracking,
                  onStop: _stopTracking,
                  onClear: _clearRecords,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Location history',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverToBoxAdapter(
                child: LocationLogPanel(
                  records: _records,
                  initialLoadComplete: _initialRecordsLoaded,
                  lastUpdated: _lastListUpdated,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
