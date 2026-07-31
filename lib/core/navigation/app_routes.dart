import 'package:flutter/material.dart';

import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/mis_perros_screen.dart';
import '../../screens/mis_paseos_screen.dart';
import '../../screens/notificaciones_screen.dart';
import '../../screens/paseadores_screen.dart';
import '../../screens/perfil_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String pets = '/pets';
  static const String walks = '/walks';
  static const String walkers = '/walkers';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case login:
        return _route(
          settings,
          const LoginScreen(),
        );

      case home:
        return _route(
          settings,
          const HomeScreen(),
        );

      case pets:
        return _route(
          settings,
          const MisPerrosScreen(),
        );

      case walks:
        return _route(
          settings,
          const MisPaseosScreen(),
        );

      case walkers:
        return _route(
          settings,
          const PaseadoresScreen(),
        );

      case notifications:
        return _route(
          settings,
          const NotificacionesScreen(),
        );

      case profile:
        return _route(
          settings,
          const PerfilScreen(),
        );

      default:
        return _route(
          settings,
          const _RouteNotFoundScreen(),
        );
    }
  }

  static MaterialPageRoute<dynamic> _route(
    RouteSettings settings,
    Widget screen,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => screen,
    );
  }
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DogGo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.route_outlined,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'La pantalla solicitada no existe.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (_) => false,
                  );
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}