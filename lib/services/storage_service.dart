import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyBaseUrl = 'doggo_base_url';
  static const String _keyToken = 'doggo_token';
  static const String _keyUsuarioId = 'doggo_usuario_id';
  static const String _keyRol = 'doggo_rol';
  static const String _keyNombre = 'doggo_nombre';
  static const String _keyEmail = 'doggo_email';

  static Future<void> guardarBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final limpia = _limpiarUrl(baseUrl);
    await prefs.setString(_keyBaseUrl, limpia);
  }

  static Future<String?> obtenerBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_keyBaseUrl);

    if (valor == null || valor.trim().isEmpty) {
      return null;
    }

    return _limpiarUrl(valor);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token;
  }

  static Future<String?> getToken() async {
    return obtenerToken();
  }

  static Future<void> limpiarToken() async {
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

  static Future<void> limpiarSesion() async {
    await limpiarToken();
    await limpiarUsuarioId();
    await limpiarRol();
    await limpiarNombre();
    await limpiarEmail();
  }

  static Future<void> limpiarTodo() async {
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