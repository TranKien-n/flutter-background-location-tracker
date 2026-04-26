import 'package:flutter/material.dart';

import 'app.dart';
import 'services/background_service_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackgroundServiceManager.initialize();

  runApp(const MyApp());
}