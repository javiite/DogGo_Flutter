import 'package:doggo_flutter/screens/home/home_state.dart';
import 'package:doggo_flutter/screens/home/models/home_pet.dart';
import 'package:doggo_flutter/screens/home/models/home_walk.dart';
import 'package:doggo_flutter/screens/home/models/home_walk_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roles del Home', () {
    test('reconoce las variantes oficiales de dueño', () {
      expect(const HomeState(role: 'Dueño').isOwner, isTrue);
      expect(const HomeState(role: 'Duenio').isOwner, isTrue);
      expect(const HomeState(role: 'Paseador').isOwner, isFalse);
    });

    test('reconoce roles administrativos y de paseador', () {
      expect(const HomeState(role: 'Paseador').isWalker, isTrue);
      expect(const HomeState(role: 'Administrador').isAdmin, isTrue);
      expect(const HomeState(role: 'SuperAdmin').isAdmin, isTrue);
    });
  });

  group('prioridad operativa', () {
    const pet = HomePet(
      id: 7,
      name: 'Luna',
      breed: 'Mestiza',
      size: 'Mediano',
      notes: '',
      imageUrl: '',
    );

    test('un paseo en curso queda por encima del próximo paseo', () {
      final inProgress = HomeWalk(
        id: 20,
        status: HomeWalkStatus.inProgress,
        pets: const [pet],
      );
      final accepted = HomeWalk(
        id: 21,
        status: HomeWalkStatus.accepted,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        pets: const [pet],
      );
      final state = HomeState(walks: [accepted, inProgress]);

      expect(state.operationalWalk?.id, 20);
      expect(state.nextScheduledWalk?.id, 21);
      expect(state.priorityWalk?.id, 20);
    });

    test('un desvío de ruta tiene la prioridad máxima', () {
      final regular = HomeWalk(
        id: 30,
        status: HomeWalkStatus.inProgress,
        pets: const [pet],
      );
      final outsideRoute = HomeWalk(
        id: 31,
        status: HomeWalkStatus.inProgress,
        hasPlannedRoute: true,
        isOutsideAllowedRoute: true,
        pets: const [pet],
      );
      final state = HomeState(walks: [regular, outsideRoute]);

      expect(state.routeAlertWalk?.id, 31);
      expect(state.operationalWalk?.id, 31);
      expect(state.priorityWalk?.id, 31);
    });

    test('relaciona la mascota con su siguiente paseo', () {
      final walk = HomeWalk(
        id: 40,
        status: HomeWalkStatus.accepted,
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        pets: const [pet],
      );
      final state = HomeState(walks: [walk]);

      expect(state.upcomingWalkForPet(pet)?.id, 40);
    });
  });
}
