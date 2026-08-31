import 'package:flutter/material.dart';

import '../services/paseadores_service.dart';
import '../services/role_switch_service.dart';
import '../services/session_service.dart';
import '../services/usuario_service.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../theme/doggo_theme.dart';
import 'home/home_screen.dart';
import 'profile_completion_screen.dart';

class AuthenticatedEntryScreen extends StatefulWidget {
  const AuthenticatedEntryScreen({super.key});

  @override
  State<AuthenticatedEntryScreen> createState() {
    return _AuthenticatedEntryScreenState();
  }
}

class _AuthenticatedEntryScreenState extends State<AuthenticatedEntryScreen> {
  final UsuarioService _usuarioService = UsuarioService();

  bool _loading = true;
  bool _skipCheck = false;
  String? _error;
  DogGoRoleMode? _incompleteMode;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    setState(() {
      _loading = true;
      _error = null;
      _incompleteMode = null;
    });

    try {
      final role = await SessionService.obtenerRol();

      if (!mounted) {
        return;
      }

      if (SessionService.esDuenioRol(role)) {
        final profile = await _usuarioService.obtenerPerfilDuenio();

        if (!mounted) {
          return;
        }

        if (!_ownerProfileComplete(profile)) {
          setState(() {
            _loading = false;
            _incompleteMode = DogGoRoleMode.owner;
          });

          return;
        }
      } else if (SessionService.esPaseadorRol(role)) {
        final profile = await PaseadoresService.obtenerMiPerfilPaseador();

        if (!mounted) {
          return;
        }

        if (!_walkerProfileComplete(profile)) {
          setState(() {
            _loading = false;
            _incompleteMode = DogGoRoleMode.walker;
          });

          return;
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _cleanError(error);
      });
    }
  }

  bool _ownerProfileComplete(Map<String, dynamic> profile) {
    final address = _firstText([profile['direccion']]);

    final latitude = _toDouble(profile['latitud']);

    final longitude = _toDouble(profile['longitud']);

    return address != null && latitude != null && longitude != null;
  }

  bool _walkerProfileComplete(Map<String, dynamic> profile) {
    final description = _firstText([profile['descripcion']]);

    final zone = _firstText([profile['zonaServicio']]);

    final hourlyRate = _toDouble(profile['tarifaPorHora']);

    return description != null &&
        zone != null &&
        hourlyRate != null &&
        hourlyRate > 0;
  }

  String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();

      if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().trim().replaceAll(',', '.');

    return double.tryParse(text);
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty ? 'No se pudo revisar tu perfil.' : message;
  }

  @override
  Widget build(BuildContext context) {
    if (_skipCheck) {
      return const HomeScreen();
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: DogGoTheme.cream,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Revisando tu perfil...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: DogGoTheme.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DogGoErrorView(
                    title: 'No pudimos revisar tu perfil',
                    message: _error!,
                    onRetry: _checkProfile,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _skipCheck = true;
                      });
                    },
                    child: const Text('Entrar de todas formas'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final incompleteMode = _incompleteMode;

    if (incompleteMode != null) {
      return ProfileCompletionScreen(mode: incompleteMode);
    }

    return const HomeScreen();
  }
}
