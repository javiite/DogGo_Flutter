import 'dart:convert';

import 'storage_service.dart';
import 'background_tracking_service.dart';

class SessionService {
  static Future<String?> obtenerToken() async {
    final token = await StorageService.obtenerToken();
    if (token == null || token.trim().isEmpty) return null;
    if (_tokenExpiro(token)) {
      await cerrarSesion();
      return null;
    }
    return token;
  }

  static Future<int?> obtenerUsuarioId() async {
    final idGuardado = await StorageService.obtenerUsuarioId();

    if (idGuardado != null) {
      return idGuardado;
    }

    final token = await StorageService.obtenerToken();
    final payload = _leerPayloadJwt(token);

    if (payload == null) return null;

    final valor =
        payload['nameid'] ??
        payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
        payload['sub'] ??
        payload['id'] ??
        payload['usuarioId'];

    final id = _intSeguro(valor);

    if (id != null) {
      await StorageService.guardarUsuarioId(id);
    }

    return id;
  }

  static Future<String?> obtenerRol() async {
    final rolGuardado = await StorageService.obtenerRol();

    if (rolGuardado != null && rolGuardado.trim().isNotEmpty) {
      return rolGuardado;
    }

    final token = await StorageService.obtenerToken();
    final payload = _leerPayloadJwt(token);

    if (payload == null) return null;

    final valor =
        payload['role'] ??
        payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
        payload['rol'];

    final rol = valor?.toString().trim();

    if (rol != null && rol.isNotEmpty) {
      await StorageService.guardarRol(rol);
    }

    return rol;
  }

  static Future<String?> obtenerNombre() async {
    final nombreGuardado = await StorageService.obtenerNombre();

    if (nombreGuardado != null && nombreGuardado.trim().isNotEmpty) {
      return nombreGuardado;
    }

    final token = await StorageService.obtenerToken();
    final payload = _leerPayloadJwt(token);

    if (payload == null) return null;

    final valor =
        payload['unique_name'] ??
        payload['name'] ??
        payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
        payload['nombre'];

    final nombre = valor?.toString().trim();

    if (nombre != null && nombre.isNotEmpty) {
      await StorageService.guardarNombre(nombre);
    }

    return nombre;
  }

  static Future<String?> obtenerEmail() async {
    final emailGuardado = await StorageService.obtenerEmail();

    if (emailGuardado != null && emailGuardado.trim().isNotEmpty) {
      return emailGuardado;
    }

    final token = await StorageService.obtenerToken();
    final payload = _leerPayloadJwt(token);

    if (payload == null) return null;

    final valor =
        payload['email'] ??
        payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];

    final email = valor?.toString().trim();

    if (email != null && email.isNotEmpty) {
      await StorageService.guardarEmail(email);
    }

    return email;
  }

  static Future<bool> haySesionActiva() async {
    return await obtenerToken() != null;
  }

  static Future<bool> estaLogueado() async {
    return haySesionActiva();
  }

  static Future<void> guardarSesion({
    required String token,
    int? usuarioId,
    String? rol,
    String? nombre,
    String? email,
  }) async {
    await StorageService.guardarToken(token);

    if (usuarioId != null) {
      await StorageService.guardarUsuarioId(usuarioId);
    }

    if (rol != null && rol.trim().isNotEmpty) {
      await StorageService.guardarRol(rol);
    }

    if (nombre != null && nombre.trim().isNotEmpty) {
      await StorageService.guardarNombre(nombre);
    }

    if (email != null && email.trim().isNotEmpty) {
      await StorageService.guardarEmail(email);
    }

    await _rellenarDesdeTokenSiFalta(token);
  }

  static Future<void> guardarSesionDesdeLogin(Map<String, dynamic> data) async {
    final token = data['token'];

    if (token == null || token.toString().trim().isEmpty) {
      return;
    }

    final usuarioId = _intSeguro(data['usuarioId']);

    final rol = data['rol'];

    final nombre = data['nombre'];

    final email = data['email'];

    await guardarSesion(
      token: token.toString(),
      usuarioId: usuarioId,
      rol: rol?.toString(),
      nombre: nombre?.toString(),
      email: email?.toString(),
    );
  }

  static Future<void> limpiarSesion() async {
    await StorageService.limpiarSesion();
  }

  static Future<void> cerrarSesion() async {
    await BackgroundTrackingService.detenerTracking();
    await limpiarSesion();
  }

  static Future<void> logout() async {
    await cerrarSesion();
  }

  static String normalizarRol(String? rol) {
    final limpio = rol?.trim();

    if (limpio == null || limpio.isEmpty) {
      return 'Sin rol';
    }

    final normalizado = limpio.toLowerCase();

    if (normalizado == 'duenio' ||
        normalizado == 'dueño' ||
        normalizado == 'owner' ||
        normalizado == 'cliente') {
      return 'Dueño';
    }

    if (normalizado == 'paseador' ||
        normalizado == 'walker' ||
        normalizado == 'dogwalker') {
      return 'Paseador';
    }

    if (normalizado == 'admin' || normalizado == 'administrador') {
      return 'Administrador';
    }

    return limpio;
  }

  static bool esPaseadorRol(String? rol) {
    final normalizado = rol?.trim().toLowerCase() ?? '';

    return normalizado == 'paseador' ||
        normalizado == 'walker' ||
        normalizado == 'dogwalker';
  }

  static bool esDuenioRol(String? rol) {
    final normalizado = rol?.trim().toLowerCase() ?? '';

    return normalizado == 'duenio' ||
        normalizado == 'dueño' ||
        normalizado == 'owner' ||
        normalizado == 'cliente';
  }

  static bool esAdminRol(String? rol) {
    final normalizado = rol?.trim().toLowerCase() ?? '';

    return normalizado == 'admin' || normalizado == 'administrador';
  }

  static Future<bool> esPaseador() async {
    final rol = await obtenerRol();
    return esPaseadorRol(rol);
  }

  static Future<bool> esDuenio() async {
    final rol = await obtenerRol();
    return esDuenioRol(rol);
  }

  static Future<bool> esAdmin() async {
    final rol = await obtenerRol();
    return esAdminRol(rol);
  }

  static Future<void> _rellenarDesdeTokenSiFalta(String token) async {
    final payload = _leerPayloadJwt(token);

    if (payload == null) return;

    final usuarioIdActual = await StorageService.obtenerUsuarioId();
    if (usuarioIdActual == null) {
      final id = _intSeguro(
        payload['nameid'] ??
            payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
            payload['sub'] ??
            payload['id'] ??
            payload['usuarioId'],
      );

      if (id != null) {
        await StorageService.guardarUsuarioId(id);
      }
    }

    final rolActual = await StorageService.obtenerRol();
    if (rolActual == null || rolActual.trim().isEmpty) {
      final rol =
          payload['role'] ??
          payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
          payload['rol'];

      if (rol != null && rol.toString().trim().isNotEmpty) {
        await StorageService.guardarRol(rol.toString());
      }
    }

    final nombreActual = await StorageService.obtenerNombre();
    if (nombreActual == null || nombreActual.trim().isEmpty) {
      final nombre =
          payload['unique_name'] ??
          payload['name'] ??
          payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
          payload['nombre'];

      if (nombre != null && nombre.toString().trim().isNotEmpty) {
        await StorageService.guardarNombre(nombre.toString());
      }
    }

    final emailActual = await StorageService.obtenerEmail();
    if (emailActual == null || emailActual.trim().isEmpty) {
      final email =
          payload['email'] ??
          payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];

      if (email != null && email.toString().trim().isNotEmpty) {
        await StorageService.guardarEmail(email.toString());
      }
    }
  }

  static Map<String, dynamic>? _leerPayloadJwt(String? token) {
    if (token == null || token.trim().isEmpty) return null;

    try {
      final partes = token.split('.');

      if (partes.length < 2) return null;

      final payload = partes[1];
      final normalizado = base64Url.normalize(payload);
      final jsonTexto = utf8.decode(base64Url.decode(normalizado));
      final data = jsonDecode(jsonTexto);

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static int? _intSeguro(dynamic valor) {
    if (valor == null) return null;

    if (valor is int) return valor;

    return int.tryParse(valor.toString());
  }

  static bool _tokenExpiro(String token) {
    final payload = _leerPayloadJwt(token);
    final exp = _intSeguro(payload?['exp']);
    if (exp == null) return false;
    final expiration = DateTime.fromMillisecondsSinceEpoch(
      exp * 1000,
      isUtc: true,
    );
    return !expiration.isAfter(DateTime.now().toUtc());
  }
}
