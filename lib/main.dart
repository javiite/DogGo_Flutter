import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/offline/offline_connectivity_sync_service.dart';
import 'core/offline/offline_walk_sync_service.dart';
import 'services/background_tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeServices();

  runApp(const DogGoApp());
}

Future<void> _initializeServices() async {
  try {
    await OfflineWalkSyncService.instance.initialize();
    await OfflineConnectivitySyncService.instance.initialize();
    await BackgroundTrackingService.inicializarServicio();
  } catch (error, stackTrace) {
    debugPrint(
      'No se pudo inicializar el seguimiento '
      'en segundo plano: $error',
    );

    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
