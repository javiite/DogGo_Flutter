import 'package:doggo_flutter/screens/pets/models/pet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('perfil de mascota', () {
    test('detecta un perfil esencial completo', () {
      final pet = Pet.fromMap({
        'id': 12,
        'nombre': 'Luna',
        'raza': 'Mestiza',
        'edad': 4,
        'tamanio': 'Mediano',
        'peso': 18.5,
        'sexo': 'Hembra',
        'temperamento': 'Tranquila',
        'nivelEnergia': 'Medio',
        'comportamientoCorrea': 'Tranquilo',
        'sociableConPerros': true,
        'sociableConPersonas': true,
        'reactivo': false,
        'riesgoEscape': false,
        'fotoUrl': '/uploads/luna.jpg',
      });

      expect(pet.profileMissingItems, isEmpty);
      expect(pet.profileCompletion, 100);
      expect(pet.isProfileComplete, isTrue);
      expect(pet.profileStatusLabel, 'Perfil completo');
    });

    test('explica los datos esenciales que faltan', () {
      final pet = Pet.fromMap({
        'id': 3,
        'nombre': 'Max',
        'raza': 'Criollo',
        'tamanio': 'Grande',
      });

      expect(pet.profileMissingItems, contains('fotografía'));
      expect(pet.profileMissingItems, contains('edad'));
      expect(pet.profileMissingItems, contains('seguridad'));
      expect(pet.profileCompletion, lessThan(100));
      expect(pet.isProfileComplete, isFalse);
    });
  });

  group('fotografías públicas', () {
    test('resuelve una ruta relativa usando el servidor', () {
      final pet = Pet.fromMap({
        'id': 8,
        'nombre': 'Toby',
        'raza': 'Beagle',
        'edad': 2,
        'tamanio': 'Mediano',
        'fotoUrl': '/media/toby.png',
      });

      expect(
        pet.publicPhotoUrl('http://192.168.1.12:5230/'),
        'http://192.168.1.12:5230/media/toby.png',
      );
    });
  });
}
