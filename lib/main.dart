import 'package:flutter/material.dart';

import 'app.dart';
import 'services/background_service_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire up background entrypoints before runApp so start/stop can attach to the same configuration.
  await BackgroundServiceManager.initialize();

  runApp(const MyApp());
}