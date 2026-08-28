import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/offline/offline_tracking_models.dart';
import '../core/offline/offline_tracking_repository.dart';
import '../core/offline/offline_tracking_sync_service.dart';
import 'storage_service.dart';

class BackgroundTrackingService {
  static const String notificationChannelId = 'doggo_tracking_channel';
  static const String notificationChannelName = 'DogGo tracking';
  static const int notificationId = 8801;
  static const String routeAlertChannelId = 'doggo_route_alerts';
  static const String routeAlertChannelName = 'Alertas de ruta DogGo';
  static const String _routeStateKey = 'doggo_tracking_estado_ruta';
  static const Duration intervaloEnvio = Duration(seconds: 5);

  static Future<void> inicializarServicio() async {
    final localNotifications = FlutterLocalNotificationsPlugin();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await localNotifications.initialize(initSettings);

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        notificationChannelId,
        notificationChannelName,
        description: 'Notificación para compartir ubicación durante un paseo.',
        importance: Importance.low,
      );

      await localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      const routeChannel = AndroidNotificationChannel(
        routeAlertChannelId,
        routeAlertChannelName,
        description:
            'Desvíos, reingresos y puntos alcanzados durante el paseo.',
        importance: Importance.high,
      );

      await localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(routeChannel);
    }

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'DogGo · Paseo en curso',
        initialNotificationContent: 'Preparando ubicación en vivo...',
        foregroundServiceNotificationId: notificationId,
        foregroundServiceTypes: const [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<bool> estaCorriendo() async {
    final service = FlutterBackgroundService();
    return service.isRunning();
  }

  static Future<bool> iniciarTracking({
    required int paseoId,
    required String nombrePerro,
    required String nombrePaseador,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_routeStateKey);

    await StorageService.guardarTrackingActivo(
      paseoId: paseoId,
      nombrePerro: nombrePerro,
      nombrePaseador: nombrePaseador,
    );

    final service = FlutterBackgroundService();

    final corriendo = await service.isRunning();

    if (!corriendo) {
      final iniciado = await service.startService();

      if (!iniciado) return false;

      await Future.delayed(const Duration(milliseconds: 700));
    }

    service.invoke('iniciarTracking', {
      'paseoId': paseoId,
      'nombrePerro': nombrePerro,
      'nombrePaseador': nombrePaseador,
    });

    return true;
  }

  static Future<void> detenerTracking() async {
    final service = FlutterBackgroundService();

    service.invoke('detenerTracking');

    await StorageService.limpiarTrackingActivo();
  }

  static Future<Map<String, dynamic>?> obtenerTrackingActivo() async {
    return StorageService.obtenerTrackingActivo();
  }

  static Future<Map<String, dynamic>?> obtenerEstadoRuta() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_routeStateKey);
    if (value == null || value.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static Stream<Map<String, dynamic>?> get cambiosEstadoRuta {
    return FlutterBackgroundService().on('estadoRutaActualizado');
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    final repository = OfflineTrackingRepository();
    final syncService = OfflineTrackingSyncService(repository: repository);
    await syncService.initialize();
    final result = await syncService.syncPending(maxBatches: 3);
    return !result.hasIrrecoverable;
  } catch (_) {
    return false;
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  int? paseoId;
  String nombrePerro = 'Perro';
  bool activo = false;
  bool procesando = false;
  Timer? timer;

  final offlineRepository = OfflineTrackingRepository();
  final syncService = OfflineTrackingSyncService(repository: offlineRepository);
  final routeNotifications = FlutterLocalNotificationsPlugin();

  await syncService.initialize();
  await routeNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  Future<RouteMonitoringEvent?> procesarMonitoreoRuta(
    List<RouteMonitoringEvent> events,
  ) async {
    if (events.isEmpty) return null;

    final latest = events.last;
    final prefs = await SharedPreferences.getInstance();
    final previousRaw = prefs.getString(
      BackgroundTrackingService._routeStateKey,
    );
    final accumulatedCheckpoints = <String>{...latest.checkpointsReached};

    if (previousRaw != null) {
      try {
        final previous = jsonDecode(previousRaw);
        if (previous is Map) {
          final previousCheckpoints = previous['checkpointsAlcanzados'];
          if (previousCheckpoints is List) {
            accumulatedCheckpoints.addAll(
              previousCheckpoints.map((item) => item.toString()),
            );
          }
        }
      } catch (_) {
        // El nuevo estado reemplazará cualquier valor local inválido.
      }
    }

    final persistedMap = latest.toMap()
      ..['checkpointsAlcanzados'] = accumulatedCheckpoints.toList();
    final persistedEvent = RouteMonitoringEvent.fromMap(
      paseoId: latest.paseoId,
      map: persistedMap,
    );

    await prefs.setString(
      BackgroundTrackingService._routeStateKey,
      jsonEncode(persistedMap),
    );

    service.invoke('estadoRutaActualizado', persistedMap);

    final significant = events.where((event) => event.significant).toList();

    for (final event in significant.reversed.take(3).toList().reversed) {
      final title = event.outsideRoute
          ? 'DogGo · Fuera de la ruta'
          : event.reentryDetected
          ? 'DogGo · Regresaste a la ruta'
          : 'DogGo · Punto alcanzado';
      final message = event.message.isNotEmpty
          ? event.message
          : event.hasCheckpoint
          ? 'Llegaste a ${event.checkpointsReached.join(', ')}.'
          : 'Se actualizó el estado del recorrido.';

      await routeNotifications.show(
        8900 + DateTime.now().millisecondsSinceEpoch.remainder(1000),
        title,
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            BackgroundTrackingService.routeAlertChannelId,
            BackgroundTrackingService.routeAlertChannelName,
            channelDescription:
                'Desvíos, reingresos y puntos alcanzados durante el paseo.',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.status,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
      );
    }

    return persistedEvent;
  }

  Future<void> cargarTrackingGuardado() async {
    final prefs = await SharedPreferences.getInstance();

    final activoPrefs = prefs.getBool('doggo_tracking_activo') ?? false;
    final paseoIdPrefs = prefs.getInt('doggo_tracking_paseo_id');

    if (activoPrefs && paseoIdPrefs != null) {
      activo = true;
      paseoId = paseoIdPrefs;
      nombrePerro = prefs.getString('doggo_tracking_nombre_perro') ?? 'Perro';
    }
  }

  Future<void> actualizarNotificacion(String contenido) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'DogGo · Paseo en curso',
        content: contenido,
      );
    }
  }

  Future<bool> permisosOk() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) return false;

    final permiso = await Geolocator.checkPermission();

    return permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse;
  }

  Future<bool> capturarYSincronizarUbicacion() async {
    if (!activo || paseoId == null || procesando) return false;

    final permisoCorrecto = await permisosOk();

    if (!permisoCorrecto) {
      await actualizarNotificacion('Permiso de ubicación pendiente.');
      return false;
    }

    procesando = true;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final capturedAt = pos.timestamp.toUtc();

      await offlineRepository.saveTrackingPoint(
        OfflineTrackingPointDraft(
          paseoId: paseoId!,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy >= 0 ? pos.accuracy : null,
          altitude: pos.altitude >= -1000 && pos.altitude <= 20000
              ? pos.altitude
              : null,
          speed: pos.speed >= 0 && pos.speed <= 200 ? pos.speed : null,
          heading: pos.heading >= 0 && pos.heading <= 360 ? pos.heading : null,
          capturedAt: capturedAt,
        ),
      );

      final fecha = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble('doggo_tracking_ultima_latitud', pos.latitude);
      await prefs.setDouble('doggo_tracking_ultima_longitud', pos.longitude);
      await prefs.setString(
        'doggo_tracking_ultima_captura',
        fecha.toIso8601String(),
      );

      final syncResult = await syncService.syncPending();
      if (syncResult.hasIrrecoverable) {
        activo = false;
        paseoId = null;
        timer?.cancel();
        timer = null;
        await StorageService.limpiarTrackingActivo();
        await actualizarNotificacion(
          '$nombrePerro · Seguimiento detenido: el paseo ya no acepta GPS',
        );
        return false;
      }
      final routeEvent = await procesarMonitoreoRuta(
        syncResult.monitoringEvents,
      );

      if (syncResult.synced > 0) {
        await prefs.setString(
          'doggo_tracking_ultimo_envio',
          fecha.toIso8601String(),
        );
      }

      if (routeEvent?.outsideRoute == true) {
        final distance = routeEvent?.distanceRouteMeters;
        await actualizarNotificacion(
          distance == null
              ? '$nombrePerro · Fuera de la ruta permitida'
              : '$nombrePerro · Fuera de ruta · ${distance.round()} m',
        );
      } else if (routeEvent?.reentryDetected == true) {
        await actualizarNotificacion('$nombrePerro · Regresó a la ruta');
      } else if (routeEvent?.hasCheckpoint == true) {
        await actualizarNotificacion(
          '$nombrePerro · ${routeEvent!.checkpointsReached.last}',
        );
      } else if (syncResult.pending > 0) {
        await actualizarNotificacion(
          '$nombrePerro · GPS guardado · '
          '${syncResult.pending} por sincronizar',
        );
      } else {
        await actualizarNotificacion(
          '$nombrePerro · GPS actualizado ${_hora(fecha)}',
        );
      }

      service.invoke('ubicacionEnviada', {
        'paseoId': paseoId,
        'latitud': pos.latitude,
        'longitud': pos.longitude,
        'precisionGpsMetros': pos.accuracy,
        'fecha': fecha.toIso8601String(),
        'sincronizada': syncResult.pending == 0,
        'pendientes': syncResult.pending,
      });

      return true;
    } catch (_) {
      await actualizarNotificacion('$nombrePerro · No se pudo guardar el GPS');

      return false;
    } finally {
      procesando = false;
    }
  }

  void iniciarTimer() {
    timer?.cancel();

    timer = Timer.periodic(BackgroundTrackingService.intervaloEnvio, (_) async {
      await capturarYSincronizarUbicacion();
    });
  }

  service.on('iniciarTracking').listen((event) async {
    final data = event ?? {};

    final idRaw = data['paseoId'];

    if (idRaw is int) {
      paseoId = idRaw;
    } else {
      paseoId = int.tryParse(idRaw?.toString() ?? '');
    }

    nombrePerro = data['nombrePerro']?.toString() ?? 'Perro';
    activo = paseoId != null;

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    if (activo) {
      await actualizarNotificacion('$nombrePerro · Enviando ubicación');

      await capturarYSincronizarUbicacion();

      iniciarTimer();
    }
  });

  service.on('detenerTracking').listen((event) async {
    activo = false;
    paseoId = null;

    timer?.cancel();
    timer = null;

    // Si no hay conexión, los puntos permanecen en SQLite.
    await syncService.syncPending(maxBatches: 10);

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('doggo_tracking_activo');
    await prefs.remove('doggo_tracking_paseo_id');
    await prefs.remove('doggo_tracking_nombre_perro');
    await prefs.remove('doggo_tracking_nombre_paseador');
    await prefs.remove('doggo_tracking_ultima_latitud');
    await prefs.remove('doggo_tracking_ultima_longitud');
    await prefs.remove('doggo_tracking_ultimo_envio');
    await prefs.remove('doggo_tracking_ultima_captura');
    await prefs.remove(BackgroundTrackingService._routeStateKey);

    service.stopSelf();
  });

  service.on('stopService').listen((event) {
    timer?.cancel();
    timer = null;
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  await cargarTrackingGuardado();

  if (activo && paseoId != null) {
    await actualizarNotificacion('$nombrePerro · Enviando ubicación');
    await capturarYSincronizarUbicacion();
    iniciarTimer();
  } else {
    await actualizarNotificacion('Sin paseo activo.');
  }
}

String _hora(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.hour)}:${dos(fecha.minute)}:${dos(fecha.second)}';
}
