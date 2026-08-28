import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_environment.dart';

class StorageService {
  static const String _keyBaseUrl = 'doggo_base_url';
  static const String _keyToken = 'doggo_token';
  static const String _keyUsuarioId = 'doggo_usuario_id';
  static const String _keyRol = 'doggo_rol';
  static const String _keyNombre = 'doggo_nombre';
  static const String _keyEmail = 'doggo_email';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(),
  );

  static const String _keyTrackingActivo = 'doggo_tracking_activo';
  static const String _keyTrackingPaseoId = 'doggo_tracking_paseo_id';
  static const String _keyTrackingNombrePerro = 'doggo_tracking_nombre_perro';
  static const String _keyTrackingNombrePaseador =
      'doggo_tracking_nombre_paseador';
  static const String _keyTrackingUltimaLatitud =
      'doggo_tracking_ultima_latitud';
  static const String _keyTrackingUltimaLongitud =
      'doggo_tracking_ultima_longitud';
  static const String _keyTrackingUltimoEnvio = 'doggo_tracking_ultimo_envio';

  static Future<void> guardarBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final limpia = _limpiarUrl(baseUrl);
    await prefs.setString(_keyBaseUrl, limpia);
  }

  static Future<String?> obtenerBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_keyBaseUrl);
    return AppEnvironment.resolveApiBaseUrl(valor);
  }

  static Future<String?> getBaseUrl() async {
    return obtenerBaseUrl();
  }

  static Future<void> limpiarBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
  }

  static Future<void> eliminarBaseUrl() async {
    await limpiarBaseUrl();
  }

  static Future<void> guardarToken(String token) async {
    final limpio = token.trim();
    if (limpio.isEmpty) {
      await limpiarToken();
      return;
    }

    await _secureStorage.write(key: _keyToken, value: limpio);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  static Future<String?> obtenerToken() async {
    final seguro = (await _secureStorage.read(key: _keyToken))?.trim();
    if (seguro != null && seguro.isNotEmpty) return seguro;

    final prefs = await SharedPreferences.getInstance();
    final tokenAnterior = prefs.getString(_keyToken)?.trim();

    if (tokenAnterior == null || tokenAnterior.isEmpty) {
      return null;
    }

    try {
      await _secureStorage.write(key: _keyToken, value: tokenAnterior);
      await prefs.remove(_keyToken);
    } catch (_) {
      // Conserva temporalmente la sesión existente y vuelve a intentar la
      // migración en la siguiente lectura si el Keychain/Keystore no responde.
    }

    return tokenAnterior;
  }

  static Future<String?> getToken() async {
    return obtenerToken();
  }

  static Future<void> limpiarToken() async {
    await _secureStorage.delete(key: _keyToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  static Future<void> eliminarToken() async {
    await limpiarToken();
  }

  static Future<void> guardarUsuarioId(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUsuarioId, usuarioId);
  }

  static Future<int?> obtenerUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUsuarioId);
  }

  static Future<void> limpiarUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsuarioId);
  }

  static Future<void> guardarRol(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRol, rol);
  }

  static Future<String?> obtenerRol() async {
    final prefs = await SharedPreferences.getInstance();
    final rol = prefs.getString(_keyRol);

    if (rol == null || rol.trim().isEmpty) {
      return null;
    }

    return rol;
  }

  static Future<void> limpiarRol() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRol);
  }

  static Future<void> guardarNombre(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNombre, nombre);
  }

  static Future<String?> obtenerNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString(_keyNombre);

    if (nombre == null || nombre.trim().isEmpty) {
      return null;
    }

    return nombre;
  }

  static Future<void> limpiarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNombre);
  }

  static Future<void> guardarEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  static Future<String?> obtenerEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);

    if (email == null || email.trim().isEmpty) {
      return null;
    }

    return email;
  }

  static Future<void> limpiarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
  }

  static Future<void> guardarTrackingActivo({
    required int paseoId,
    required String nombrePerro,
    required String nombrePaseador,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyTrackingActivo, true);
    await prefs.setInt(_keyTrackingPaseoId, paseoId);
    await prefs.setString(_keyTrackingNombrePerro, nombrePerro);
    await prefs.setString(_keyTrackingNombrePaseador, nombrePaseador);
  }

  static Future<void> guardarUltimaUbicacionTracking({
    required double latitud,
    required double longitud,
    required DateTime fecha,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_keyTrackingUltimaLatitud, latitud);
    await prefs.setDouble(_keyTrackingUltimaLongitud, longitud);
    await prefs.setString(_keyTrackingUltimoEnvio, fecha.toIso8601String());
  }

  static Future<Map<String, dynamic>?> obtenerTrackingActivo() async {
    final prefs = await SharedPreferences.getInstance();

    final activo = prefs.getBool(_keyTrackingActivo) ?? false;
    final paseoId = prefs.getInt(_keyTrackingPaseoId);

    if (!activo || paseoId == null) {
      return null;
    }

    return {
      'activo': activo,
      'paseoId': paseoId,
      'nombrePerro': prefs.getString(_keyTrackingNombrePerro) ?? 'Perro',
      'nombrePaseador':
          prefs.getString(_keyTrackingNombrePaseador) ?? 'Paseador',
      'latitud': prefs.getDouble(_keyTrackingUltimaLatitud),
      'longitud': prefs.getDouble(_keyTrackingUltimaLongitud),
      'ultimoEnvio': prefs.getString(_keyTrackingUltimoEnvio),
    };
  }

  static Future<bool> hayTrackingActivo() async {
    final tracking = await obtenerTrackingActivo();
    return tracking != null;
  }

  static Future<void> limpiarTrackingActivo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyTrackingActivo);
    await prefs.remove(_keyTrackingPaseoId);
    await prefs.remove(_keyTrackingNombrePerro);
    await prefs.remove(_keyTrackingNombrePaseador);
    await prefs.remove(_keyTrackingUltimaLatitud);
    await prefs.remove(_keyTrackingUltimaLongitud);
    await prefs.remove(_keyTrackingUltimoEnvio);
  }

  static Future<void> limpiarSesion() async {
    await limpiarToken();
    await limpiarUsuarioId();
    await limpiarRol();
    await limpiarNombre();
    await limpiarEmail();
    await limpiarTrackingActivo();
  }

  static Future<void> limpiarTodo() async {
    await _secureStorage.delete(key: _keyToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static String _limpiarUrl(String url) {
    var limpia = url.trim();

    while (limpia.endsWith('/')) {
      limpia = limpia.substring(0, limpia.length - 1);
    }

    return limpia;
  }
}
