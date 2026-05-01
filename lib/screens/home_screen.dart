import 'package:flutter/material.dart';

import 'perfil_usuario_screen.dart';
import 'paseadores_screen.dart';
import 'mis_perros_screen.dart';
import 'crear_paseo_screen.dart';
import 'mis_paseos_screen.dart';
import 'configuracion_screen.dart';
import 'notificaciones_screen.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic>? usuario;
  final int? usuarioId;
  final String? nombre;
  final String? rol;

  const HomeScreen({
    super.key,
    this.usuario,
    this.usuarioId,
    this.nombre,
    this.rol,
  });

  String _texto(dynamic valor, {String fallback = ''}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String get _nombreUsuario {
    final nombreMapa = usuario?['nombre'] ?? usuario?['Nombre'];
    final apellidoMapa = usuario?['apellido'] ?? usuario?['Apellido'];

    final n = _texto(nombre ?? nombreMapa, fallback: '');
    final a = _texto(apellidoMapa, fallback: '');

    final completo = '$n $a'.trim();
    return completo.isEmpty ? 'Usuario' : completo;
  }

  String get _rolUsuario {
    return _texto(
      rol ?? usuario?['rol'] ?? usuario?['Rol'],
      fallback: 'DogGo',
    );
  }

  bool get _esPaseador {
    return _rolUsuario.toLowerCase().contains('paseador');
  }

  bool get _esDuenio {
    final r = _rolUsuario.toLowerCase();
    return r.contains('duenio') || r.contains('dueño');
  }

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => pantalla,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opciones = <_HomeOption>[
      _HomeOption(
        titulo: 'Mi perfil',
        subtitulo: 'Ver y editar tus datos',
        icono: Icons.person_rounded,
        color: const Color(0xFF1F8A70),
        pantalla: const PerfilUsuarioScreen(),
        destacado: true,
      ),
      _HomeOption(
        titulo: 'Notificaciones',
        subtitulo: 'Actividad reciente de paseos y mensajes',
        icono: Icons.notifications_rounded,
        color: Colors.deepOrange,
        pantalla: const NotificacionesScreen(),
        destacado: true,
      ),
      _HomeOption(
        titulo: 'Mis paseos',
        subtitulo: 'Revisa estados, detalle, mapa y chat',
        icono: Icons.route_rounded,
        color: Colors.green,
        pantalla: MisPaseosScreen(
          usuarioId: usuarioId,
          rol: _rolUsuario,
        ),
      ),
      if (_esDuenio || !_esPaseador)
        _HomeOption(
          titulo: 'Crear paseo',
          subtitulo: 'Agenda un nuevo paseo',
          icono: Icons.add_location_alt_rounded,
          color: Colors.blue,
          pantalla: const CrearPaseoScreen(),
        ),
      if (_esDuenio || !_esPaseador)
        _HomeOption(
          titulo: 'Mis perros',
          subtitulo: 'Administra tus mascotas',
          icono: Icons.pets_rounded,
          color: Colors.orange,
          pantalla: const MisPerrosScreen(),
        ),
      _HomeOption(
        titulo: 'Paseadores',
        subtitulo: 'Busca paseadores disponibles',
        icono: Icons.directions_walk_rounded,
        color: Colors.purple,
        pantalla: const PaseadoresScreen(),
      ),
      _HomeOption(
        titulo: 'Configuración',
        subtitulo: 'URL del servidor y conexión',
        icono: Icons.settings_rounded,
        color: Colors.grey,
        pantalla: const ConfiguracionScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('DogGo'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              _abrir(
                context,
                const NotificacionesScreen(),
              );
            },
            icon: const Icon(Icons.notifications_rounded),
          ),
          IconButton(
            tooltip: 'Mi perfil',
            onPressed: () {
              _abrir(
                context,
                const PerfilUsuarioScreen(),
              );
            },
            icon: const Icon(Icons.person_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildAccesosDestacados(context),
            const SizedBox(height: 16),
            const Text(
              'Accesos rápidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...opciones.map(
              (opcion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HomeOptionCard(
                  opcion: opcion,
                  onTap: () => _abrir(context, opcion.pantalla),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F8A70),
            Color(0xFF35A98A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $_nombreUsuario',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _esPaseador
                      ? 'Gestiona solicitudes, chats y paseos activos.'
                      : 'Agenda paseos, revisa chats y cuida a tus mascotas.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _rolUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccesosDestacados(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniAcceso(
            titulo: 'Perfil',
            subtitulo: 'Tus datos',
            icono: Icons.person_rounded,
            color: const Color(0xFF1F8A70),
            onTap: () {
              _abrir(
                context,
                const PerfilUsuarioScreen(),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniAcceso(
            titulo: 'Avisos',
            subtitulo: 'Actividad',
            icono: Icons.notifications_rounded,
            color: Colors.deepOrange,
            onTap: () {
              _abrir(
                context,
                const NotificacionesScreen(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeOption {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final Widget pantalla;
  final bool destacado;

  const _HomeOption({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.pantalla,
    this.destacado = false,
  });
}

class _HomeOptionCard extends StatelessWidget {
  final _HomeOption opcion;
  final VoidCallback onTap;

  const _HomeOptionCard({
    required this.opcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: opcion.destacado
              ? opcion.color.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: opcion.destacado
                ? opcion.color.withOpacity(0.18)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: opcion.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                opcion.icono,
                color: opcion.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opcion.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    opcion.subtitulo,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade500,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAcceso extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _MiniAcceso({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icono,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}