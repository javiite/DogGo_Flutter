import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

class BackgroundTrackingService {
  static const String notificationChannelId = 'doggo_tracking_channel';
  static const String notificationChannelName = 'DogGo tracking';
  static const int notificationId = 8801;
  static const Duration intervaloEnvio = Duration(seconds: 5);

  static Future<void> inicializarServicio() async {
    final localNotifications = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'Notificación para compartir ubicación durante un paseo.',
      importance: Importance.low,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

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
        foregroundServiceTypes: const [
          AndroidForegroundType.location,
        ],
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
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  int? paseoId;
  String nombrePerro = 'Perro';
  String nombrePaseador = 'Paseador';
  bool activo = false;
  Timer? timer;

  Future<void> cargarTrackingGuardado() async {
    final prefs = await SharedPreferences.getInstance();

    final activoPrefs = prefs.getBool('doggo_tracking_activo') ?? false;
    final paseoIdPrefs = prefs.getInt('doggo_tracking_paseo_id');

    if (activoPrefs && paseoIdPrefs != null) {
      activo = true;
      paseoId = paseoIdPrefs;
      nombrePerro = prefs.getString('doggo_tracking_nombre_perro') ?? 'Perro';
      nombrePaseador =
          prefs.getString('doggo_tracking_nombre_paseador') ?? 'Paseador';
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

  Future<bool> enviarUbicacion() async {
    if (!activo || paseoId == null) return false;

    final prefs = await SharedPreferences.getInstance();

    final baseUrl = prefs.getString('doggo_base_url');
    final token = prefs.getString('doggo_token');

    if (baseUrl == null || baseUrl.trim().isEmpty) {
      await actualizarNotificacion('Falta configurar servidor.');
      return false;
    }

    if (token == null || token.trim().isEmpty) {
      await actualizarNotificacion('Sesión no disponible.');
      return false;
    }

    final permisoCorrecto = await permisosOk();

    if (!permisoCorrecto) {
      await actualizarNotificacion('Permiso de ubicación pendiente.');
      return false;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      final body = {
        'paseoId': paseoId,
        'PaseoId': paseoId,
        'latitud': pos.latitude,
        'Latitud': pos.latitude,
        'longitud': pos.longitude,
        'Longitud': pos.longitude,
        'latitudActual': pos.latitude,
        'LatitudActual': pos.latitude,
        'longitudActual': pos.longitude,
        'LongitudActual': pos.longitude,
      };

      final endpoint = Uri.parse('$baseUrl/api/paseos/$paseoId/ubicacion');

      final response = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final ok = response.statusCode >= 200 && response.statusCode < 300;

      if (!ok) {
        await actualizarNotificacion(
          '$nombrePerro · Error al enviar ubicación',
        );
        return false;
      }

      final fecha = DateTime.now();

      await prefs.setDouble('doggo_tracking_ultima_latitud', pos.latitude);
      await prefs.setDouble('doggo_tracking_ultima_longitud', pos.longitude);
      await prefs.setString(
        'doggo_tracking_ultimo_envio',
        fecha.toIso8601String(),
      );

      await actualizarNotificacion(
        '$nombrePerro · GPS actualizado ${_hora(fecha)}',
      );

      service.invoke('ubicacionEnviada', {
        'paseoId': paseoId,
        'latitud': pos.latitude,
        'longitud': pos.longitude,
        'fecha': fecha.toIso8601String(),
      });

      return true;
    } catch (_) {
      await actualizarNotificacion(
        '$nombrePerro · No se pudo obtener GPS',
      );

      return false;
    }
  }

  void iniciarTimer() {
    timer?.cancel();

    timer = Timer.periodic(BackgroundTrackingService.intervaloEnvio, (_) async {
      await enviarUbicacion();
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
    nombrePaseador = data['nombrePaseador']?.toString() ?? 'Paseador';
    activo = paseoId != null;

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    if (activo) {
      await actualizarNotificacion('$nombrePerro · Enviando ubicación');

      await enviarUbicacion();

      iniciarTimer();
    }
  });

  service.on('detenerTracking').listen((event) async {
    activo = false;
    paseoId = null;

    timer?.cancel();
    timer = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('doggo_tracking_activo');
    await prefs.remove('doggo_tracking_paseo_id');
    await prefs.remove('doggo_tracking_nombre_perro');
    await prefs.remove('doggo_tracking_nombre_paseador');
    await prefs.remove('doggo_tracking_ultima_latitud');
    await prefs.remove('doggo_tracking_ultima_longitud');
    await prefs.remove('doggo_tracking_ultimo_envio');

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
    await enviarUbicacion();
    iniciarTimer();
  } else {
    await actualizarNotificacion('Sin paseo activo.');
  }
}

String _hora(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.hour)}:${dos(fecha.minute)}:${dos(fecha.second)}';
}