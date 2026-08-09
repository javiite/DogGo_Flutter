import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../services/role_switch_service.dart';
import '../services/usuario_service.dart';
import '../theme/doggo_theme.dart';
import 'editar_perfil_paseador_screen.dart';
import 'owner_profile_setup_screen.dart';

class ProfileCompletionScreen
    extends StatefulWidget {
  final DogGoRoleMode mode;

  const ProfileCompletionScreen({
    super.key,
    required this.mode,
  });

  @override
  State<ProfileCompletionScreen>
      createState() {
    return _ProfileCompletionScreenState();
  }
}

class _ProfileCompletionScreenState
    extends State<ProfileCompletionScreen> {
  final UsuarioService _usuarioService =
      UsuarioService();

  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _openProfileForm();
    });
  }

  Future<void> _openProfileForm() async {
    if (_opening) {
      return;
    }

    setState(() {
      _opening = true;
      _error = null;
    });

    try {
      Widget screen;

      if (widget.mode ==
          DogGoRoleMode.walker) {
        screen =
            const EditarPerfilPaseadorScreen();
      } else {
        final profile =
            await _usuarioService
                .obtenerPerfil();

        if (!mounted) {
          return;
        }

        screen =
            OwnerProfileSetupScreen(
          profile: profile,
        );
      }

      if (!mounted) {
        return;
      }

      await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) => screen,
        ),
      );

      if (!mounted) {
        return;
      }

      _goHome();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _opening = false;
        _error = _cleanError(error);
      });
    }
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (_) => false,
    );
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .replaceFirst(
          'ApiException: ',
          '',
        )
        .trim();

    return message.isEmpty
        ? 'No se pudo preparar tu perfil.'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final modeName =
        widget.mode ==
                DogGoRoleMode.walker
            ? 'paseador'
            : 'dueño';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            DogGoTheme.cream,
        appBar: AppBar(
          automaticallyImplyLeading:
              false,
          title: const Text(
            'Completa tu perfil',
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              28,
            ),
            child: _error == null
                ? Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration:
                            const BoxDecoration(
                          color:
                              DogGoTheme
                                  .tealLight,
                          shape:
                              BoxShape.circle,
                        ),
                        child: Icon(
                          widget.mode ==
                                  DogGoRoleMode
                                      .walker
                              ? Icons
                                  .directions_walk_rounded
                              : Icons
                                  .pets_rounded,
                          size: 38,
                          color:
                              DogGoTheme.teal,
                        ),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Text(
                        'Preparando tu perfil de $modeName',
                        textAlign:
                            TextAlign.center,
                        style:
                            DogGoTheme.title(
                          size: 22,
                        ),
                      ),
                      const SizedBox(
                        height: 9,
                      ),
                      Text(
                        'Personalizaremos la experiencia para este modo.',
                        textAlign:
                            TextAlign.center,
                        style:
                            DogGoTheme.subtitle(),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      const
                          CircularProgressIndicator(),
                    ],
                  )
                : Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons
                            .error_outline_rounded,
                        color:
                            DogGoTheme.red,
                        size: 52,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        'No pudimos abrir tu perfil',
                        textAlign:
                            TextAlign.center,
                        style:
                            DogGoTheme.title(
                          size: 21,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        _error!,
                        textAlign:
                            TextAlign.center,
                        style:
                            DogGoTheme.subtitle(),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _openProfileForm,
                          icon: const Icon(
                            Icons
                                .refresh_rounded,
                          ),
                          label: const Text(
                            'Intentar nuevamente',
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      TextButton(
                        onPressed:
                            _goHome,
                        child: const Text(
                          'Completar después',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}