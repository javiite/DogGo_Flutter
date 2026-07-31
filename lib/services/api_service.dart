import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/errors/api_exception.dart';
import 'storage_service.dart';

abstract final class ApiService {
  static const Duration _requestTimeout =
      Duration(seconds: 25);

  static const Duration _uploadTimeout =
      Duration(seconds: 60);

  static Future<String> obtenerBaseUrl() async {
    final value = await StorageService.obtenerBaseUrl();
    final baseUrl = value?.trim() ?? '';

    if (baseUrl.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.noServerConfigured,
        message:
            'No hay un servidor configurado. Revisa la configuración de DogGo.',
      );
    }

    final uri = Uri.tryParse(baseUrl);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const ApiException(
        type: ApiErrorType.invalidUrl,
        message:
            'La dirección del servidor no es válida.',
      );
    }

    return _cleanBaseUrl(baseUrl);
  }

  static Future<String?> obtenerToken() async {
    final token = await StorageService.obtenerToken();
    final cleanToken = token?.trim() ?? '';

    return cleanToken.isEmpty ? null : cleanToken;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return _sendJson(
      method: _HttpMethod.post,
      endpoint: endpoint,
      body: body,
      authenticated: false,
    );
  }

  static Future<Map<String, dynamic>> postAuth(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return _sendJson(
      method: _HttpMethod.post,
      endpoint: endpoint,
      body: body,
      authenticated: true,
    );
  }

  static Future<Map<String, dynamic>> getAuth(
    String endpoint,
  ) {
    return _sendJson(
      method: _HttpMethod.get,
      endpoint: endpoint,
      authenticated: true,
    );
  }

  static Future<Map<String, dynamic>> putAuth(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) {
    return _sendJson(
      method: _HttpMethod.put,
      endpoint: endpoint,
      body: body,
      authenticated: true,
    );
  }

  static Future<Map<String, dynamic>> deleteAuth(
    String endpoint,
  ) {
    return _sendJson(
      method: _HttpMethod.delete,
      endpoint: endpoint,
      authenticated: true,
    );
  }

  static Future<Map<String, dynamic>>
      postMultipartAuth(
    String endpoint, {
    required String filePath,
    String fileFieldName = 'foto',
    Map<String, String>? fields,
  }) async {
    final uri = await _buildUri(endpoint);
    final token = await _requireToken();
    final file = File(filePath);

    if (!await file.exists()) {
      throw const ApiException(
        type: ApiErrorType.invalidResponse,
        message:
            'No se encontró el archivo que intentas subir.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        fileFieldName,
        filePath,
      ),
    );

    try {
      _logRequest('POST', uri);

      final streamedResponse = await request
          .send()
          .timeout(_uploadTimeout);

      final response =
          await http.Response.fromStream(streamedResponse);

      _logResponse(
        method: 'POST',
        uri: uri,
        statusCode: response.statusCode,
      );

      return _buildResponse(response);
    } on TimeoutException catch (error) {
      throw ApiException(
        type: ApiErrorType.timeout,
        message:
            'La imagen tardó demasiado en subir. Inténtalo nuevamente.',
        originalError: error,
      );
    } on SocketException catch (error) {
      throw ApiException(
        type: ApiErrorType.noConnection,
        message:
            'No se pudo conectar con el servidor. Revisa tu conexión.',
        originalError: error,
      );
    } on HttpException catch (error) {
      throw ApiException(
        type: ApiErrorType.serverUnavailable,
        message:
            'El servidor no pudo procesar la subida.',
        originalError: error,
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        type: ApiErrorType.unknown,
        message:
            'No se pudo subir el archivo. Inténtalo nuevamente.',
        originalError: error,
      );
    }
  }

  static Future<Map<String, dynamic>> _sendJson({
    required _HttpMethod method,
    required String endpoint,
    required bool authenticated,
    Map<String, dynamic>? body,
  }) async {
    final uri = await _buildUri(endpoint);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _requireToken();
      headers['Authorization'] = 'Bearer $token';
    }

    final encodedBody =
        body == null ? null : jsonEncode(body);

    try {
      _logRequest(method.name.toUpperCase(), uri);

      final response = await _performRequest(
        method: method,
        uri: uri,
        headers: headers,
        encodedBody: encodedBody,
      ).timeout(_requestTimeout);

      _logResponse(
        method: method.name.toUpperCase(),
        uri: uri,
        statusCode: response.statusCode,
      );

      return _buildResponse(response);
    } on TimeoutException catch (error) {
      throw ApiException(
        type: ApiErrorType.timeout,
        message:
            'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
        originalError: error,
      );
    } on SocketException catch (error) {
      throw ApiException(
        type: ApiErrorType.noConnection,
        message:
            'Sin conexión con el servidor. Revisa tu red o la dirección configurada.',
        originalError: error,
      );
    } on HandshakeException catch (error) {
      throw ApiException(
        type: ApiErrorType.noConnection,
        message:
            'No se pudo establecer una conexión segura con el servidor.',
        originalError: error,
      );
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiErrorType.invalidUrl,
        message:
            'La dirección del servidor no es válida.',
        originalError: error,
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        type: ApiErrorType.unknown,
        message:
            'Ocurrió un error al comunicarse con el servidor.',
        originalError: error,
      );
    }
  }

  static Future<http.Response> _performRequest({
    required _HttpMethod method,
    required Uri uri,
    required Map<String, String> headers,
    required String? encodedBody,
  }) {
    switch (method) {
      case _HttpMethod.get:
        return http.get(
          uri,
          headers: headers,
        );

      case _HttpMethod.post:
        return http.post(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case _HttpMethod.put:
        return http.put(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case _HttpMethod.delete:
        return http.delete(
          uri,
          headers: headers,
          body: encodedBody,
        );
    }
  }

  static Future<Uri> _buildUri(
    String endpoint,
  ) async {
    final baseUrl = await obtenerBaseUrl();
    final cleanEndpoint = endpoint.trim();

    if (cleanEndpoint.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.invalidUrl,
        message:
            'El endpoint solicitado no es válido.',
      );
    }

    final normalizedEndpoint =
        cleanEndpoint.startsWith('/')
            ? cleanEndpoint
            : '/$cleanEndpoint';

    final uri = Uri.tryParse(
      '$baseUrl$normalizedEndpoint',
    );

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority) {
      throw const ApiException(
        type: ApiErrorType.invalidUrl,
        message:
            'No se pudo construir la dirección de la solicitud.',
      );
    }

    return uri;
  }

  static Future<String> _requireToken() async {
    final token = await obtenerToken();

    if (token == null) {
      throw const ApiException(
        type: ApiErrorType.noSession,
        message:
            'Tu sesión no está disponible. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }

    return token;
  }

  static Map<String, dynamic> _buildResponse(
    http.Response response,
  ) {
    final responseBody = _decodeBody(response);

    return {
      'statusCode': response.statusCode,
      'body': responseBody,
    };
  }

  static dynamic _decodeBody(
    http.Response response,
  ) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    final text = utf8.decode(
      response.bodyBytes,
      allowMalformed: true,
    );

    if (text.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(text);
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': text,
      };
    }
  }

  static String _cleanBaseUrl(String value) {
    var cleanValue = value.trim();

    while (cleanValue.endsWith('/')) {
      cleanValue = cleanValue.substring(
        0,
        cleanValue.length - 1,
      );
    }

    return cleanValue;
  }

  static void _logRequest(
    String method,
    Uri uri,
  ) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[DogGo API] $method ${uri.path}');
  }

  static void _logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[DogGo API] $method ${uri.path} → $statusCode',
    );
  }
}

enum _HttpMethod {
  get,
  post,
  put,
  delete,
}