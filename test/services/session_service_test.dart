import 'package:doggo_flutter/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalización de roles', () {
    test('unifica dueño en una sola etiqueta', () {
      expect(SessionService.normalizarRol('Dueño'), 'Dueño');
      expect(SessionService.normalizarRol('duenio'), 'Dueño');
      expect(SessionService.normalizarRol('owner'), 'Dueño');
      expect(SessionService.esDuenioRol('cliente'), isTrue);
    });

    test('unifica paseador y administrador', () {
      expect(SessionService.normalizarRol('walker'), 'Paseador');
      expect(SessionService.esPaseadorRol('dogwalker'), isTrue);
      expect(SessionService.normalizarRol('admin'), 'Administrador');
      expect(SessionService.esAdminRol('administrador'), isTrue);
    });

    test('conserva un rol desconocido sin inventar permisos', () {
      expect(SessionService.normalizarRol('Soporte'), 'Soporte');
      expect(SessionService.esAdminRol('Soporte'), isFalse);
      expect(SessionService.esDuenioRol('Soporte'), isFalse);
      expect(SessionService.esPaseadorRol('Soporte'), isFalse);
    });
  });
}
