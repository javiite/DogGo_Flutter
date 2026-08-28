import 'package:doggo_flutter/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('guarda el JWT solamente en almacenamiento seguro', () async {
    await StorageService.guardarToken(' token-seguro ');

    const secureStorage = FlutterSecureStorage();
    final preferences = await SharedPreferences.getInstance();

    expect(await secureStorage.read(key: 'doggo_token'), 'token-seguro');
    expect(preferences.getString('doggo_token'), isNull);
  });

  test('migra automáticamente el JWT guardado anteriormente', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'doggo_token': 'token-anterior',
    });

    expect(await StorageService.obtenerToken(), 'token-anterior');

    const secureStorage = FlutterSecureStorage();
    final preferences = await SharedPreferences.getInstance();

    expect(await secureStorage.read(key: 'doggo_token'), 'token-anterior');
    expect(preferences.getString('doggo_token'), isNull);
  });

  test('elimina el JWT de ambos almacenamientos', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'doggo_token': 'token-anterior',
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'doggo_token': 'token-seguro',
    });

    await StorageService.limpiarToken();

    const secureStorage = FlutterSecureStorage();
    final preferences = await SharedPreferences.getInstance();

    expect(await secureStorage.read(key: 'doggo_token'), isNull);
    expect(preferences.getString('doggo_token'), isNull);
  });

  test('usa la configuración local cuando no hay servidor guardado', () async {
    expect(await StorageService.obtenerBaseUrl(), 'http://127.0.0.1:5230');
  });

  test('prioriza y normaliza el servidor guardado', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'doggo_base_url': ' https://api.doggo.test/// ',
    });

    expect(await StorageService.obtenerBaseUrl(), 'https://api.doggo.test');
  });
}
