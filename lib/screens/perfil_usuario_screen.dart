import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../services/usuario_service.dart';
import 'cambiar_password_screen.dart';
import 'configuracion_screen.dart';
import 'editar_perfil_screen.dart';
import 'login_screen.dart';
import 'mis_paseos_screen.dart';
import 'mis_perros_screen.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);
  static const violet = Color(0xFF7C5CBF);
  static const violetSurf = Color(0xFFF0EBFA);
  static const amber = Color(0xFFFFAB2E);
  static const amberSurf = Color(0xFFFFF4E0);
  static const emerald = Color(0xFF22C55E);
  static const emeraldSurf = Color(0xFFE6FAF0);
  static const rose = Color(0xFFEF4444);
  static const roseSurf = Color(0xFFFEEEEE);
  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static List<BoxShadow> shadow({
    double opacity = .055,
    double blur = 16,
    Offset offset = const Offset(0, 5),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }
}

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double spacing = 0,
  double height = 1.2,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen>
    with SingleTickerProviderStateMixin {
  final UsuarioService _usuarioService = UsuarioService();

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
  );

  Map<String, dynamic>? _perfil;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController.forward();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final perfil = await _usuarioService.obtenerPerfil();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  dynamic _valor(List<String> keys) {
    final perfil = _perfil;

    if (perfil == null) return null;

    for (final key in keys) {
      if (perfil.containsKey(key) && perfil[key] != null) {
        return perfil[key];
      }
    }

    return null;
  }

  String get _nombre {
    return _texto(
      _valor(['nombre', 'Nombre']),
      fallback: '',
    );
  }

  String get _apellido {
    return _texto(
      _valor(['apellido', 'Apellido']),
      fallback: '',
    );
  }

  String get _nombreCompleto {
    final completo = '$_nombre $_apellido'.trim();
    return completo.isEmpty ? 'Usuario DogGo' : completo;
  }

  String get _email {
    return _texto(
      _valor(['email', 'Email', 'correo', 'Correo']),
      fallback: 'Correo no disponible',
    );
  }

  String get _telefono {
    return _texto(
      _valor(['telefono', 'Telefono', 'teléfono', 'Teléfono']),
      fallback: 'Teléfono no disponible',
    );
  }

  String get _rol {
    return _texto(
      _valor(['rol', 'Rol', 'tipoUsuario', 'TipoUsuario']),
      fallback: 'Usuario',
    );
  }

  bool get _esPaseador {
    return _rol.toLowerCase().contains('paseador');
  }

  bool get _esDuenio {
    final rol = _rol.toLowerCase();
    return rol.contains('duenio') || rol.contains('dueño') || rol.contains('cliente');
  }

  bool get _emailConfirmado {
    final valor = _valor(['emailConfirmado', 'EmailConfirmado']);

    if (valor is bool) return valor;

    return valor?.toString().toLowerCase() == 'true';
  }

  Color get _colorRol {
    if (_esPaseador) return _T.violet;
    if (_esDuenio) return _T.teal;
    return _T.inkSub;
  }

  Color get _surfaceRol {
    if (_esPaseador) return _T.violetSurf;
    if (_esDuenio) return _T.tealSurface;
    return const Color(0xFFF3F4F6);
  }

  String get _rolBonito {
    if (_esPaseador) return 'Paseador';
    if (_esDuenio) return 'Dueño';
    return _rol;
  }

  String get _iniciales {
    final partes = _nombreCompleto
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (partes.isEmpty) return 'DG';

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return '${partes[0].substring(0, 1)}${partes[1].substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _abrirEditarPerfil() async {
    if (_perfil == null) return;

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPerfilScreen(
          perfil: _perfil!,
        ),
      ),
    );

    if (actualizado == true) {
      await _cargarPerfil();
    }
  }

  Future<void> _abrirCambiarPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CambiarPasswordScreen(),
      ),
    );
  }

  Future<void> _abrir(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );

    if (mounted) {
      await _cargarPerfil();
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Seguro que quieres cerrar sesión? La URL del servidor se conservará.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.rose,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await StorageService.limpiarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _esPaseador ? _T.violet : _T.tealDeep,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _esPaseador ? '👟' : '🐾',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mi perfil',
              style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _cargarPerfil,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : FadeTransition(
                  opacity: _fade,
                  child: RefreshIndicator(
                    onRefresh: _cargarPerfil,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.zero,
                      children: [
                        _buildHeader(),
                        _buildStats(),
                        _buildDatosPersonales(),
                        _buildPanelRol(),
                        _buildAccionesPrincipales(),
                        _buildCuenta(),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 68,
              color: _T.rose.withOpacity(.85),
            ),
            const SizedBox(height: 14),
            Text(
              'No se pudo cargar tu perfil',
              style: _ts(20, FontWeight.w900, _T.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: _ts(13, FontWeight.w500, _T.inkSub, height: 1.3),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _cargarPerfil,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.rose,
                side: const BorderSide(color: _T.rose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _esPaseador ? _T.violet : _T.tealDeep,
            _T.bg,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _esPaseador
                          ? const [Color(0xFF7C5CBF), Color(0xFF5B3FA8)]
                          : const [Color(0xFF0EC9A0), Color(0xFF089B7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _colorRol.withOpacity(.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(.7),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _iniciales,
                      style: _ts(32, FontWeight.w900, Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _emailConfirmado ? _T.emerald : _T.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _emailConfirmado
                          ? Icons.verified_rounded
                          : Icons.mark_email_unread_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _nombreCompleto,
              textAlign: TextAlign.center,
              style: _ts(23, FontWeight.w900, Colors.white, spacing: -.4),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              textAlign: TextAlign.center,
              style: _ts(13, FontWeight.w500, Colors.white.withOpacity(.88)),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderChip(
                  texto: _rolBonito,
                  icono: _esPaseador
                      ? Icons.directions_walk_rounded
                      : Icons.pets_rounded,
                ),
                _HeaderChip(
                  texto: _emailConfirmado
                      ? 'Correo confirmado'
                      : 'Correo pendiente',
                  icono: _emailConfirmado
                      ? Icons.verified_rounded
                      : Icons.warning_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _abrirEditarPerfil,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Editar perfil',
                  style: _ts(
                    12.5,
                    FontWeight.w900,
                    _esPaseador ? _T.violet : _T.tealDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _T.shadow(
          opacity: .06,
          blur: 20,
          offset: const Offset(0, 6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            value: _rolBonito,
            label: 'Rol',
            emoji: _esPaseador ? '👟' : '🐾',
          ),
          _DividerSmall(),
          _StatItem(
            value: _emailConfirmado ? 'OK' : 'Pend.',
            label: 'Correo',
            emoji: _emailConfirmado ? '✅' : '⚠️',
          ),
          _DividerSmall(),
          const _StatItem(
            value: 'JWT',
            label: 'Sesión',
            emoji: '🔐',
          ),
          _DividerSmall(),
          const _StatItem(
            value: 'API',
            label: 'Perfil',
            emoji: '🌐',
          ),
        ],
      ),
    );
  }

  Widget _buildDatosPersonales() {
    return _SectionCard(
      title: '👤 Información personal',
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      children: [
        _InfoRow(
          icon: Icons.person_rounded,
          title: 'Nombre',
          value: _nombreCompleto,
          color: _T.teal,
          surface: _T.tealSurface,
        ),
        _InfoRow(
          icon: Icons.email_rounded,
          title: 'Correo',
          value: _email,
          color: _T.violet,
          surface: _T.violetSurf,
        ),
        _InfoRow(
          icon: Icons.phone_rounded,
          title: 'Teléfono',
          value: _telefono,
          color: _T.emerald,
          surface: _T.emeraldSurf,
        ),
      ],
    );
  }

  Widget _buildPanelRol() {
    return _SectionCard(
      title: _esPaseador ? '👟 Panel de paseador' : '🐾 Panel de dueño',
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      children: [
        _ActionRow(
          icon: _esPaseador
              ? Icons.route_rounded
              : Icons.directions_walk_rounded,
          title: _esPaseador ? 'Mis paseos asignados' : 'Mis paseos',
          subtitle: _esPaseador
              ? 'Acepta, inicia, finaliza y envía ubicación.'
              : 'Consulta tus reservas, mapa y tracking.',
          color: _T.amber,
          surface: _T.amberSurf,
          onTap: () => _abrir(const MisPaseosScreen()),
        ),
        _ActionRow(
          icon: Icons.pets_rounded,
          title: 'Mis perros',
          subtitle: 'Administra mascotas registradas.',
          color: _T.violet,
          surface: _T.violetSurf,
          onTap: () => _abrir(const MisPerrosScreen()),
        ),
      ],
    );
  }

  Widget _buildAccionesPrincipales() {
    return _SectionCard(
      title: '⚡ Acciones rápidas',
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      children: [
        _ActionRow(
          icon: Icons.edit_rounded,
          title: 'Editar perfil',
          subtitle: 'Actualiza nombre, apellido y teléfono.',
          color: _T.teal,
          surface: _T.tealSurface,
          onTap: _abrirEditarPerfil,
        ),
        _ActionRow(
          icon: Icons.lock_reset_rounded,
          title: 'Cambiar contraseña',
          subtitle: 'Mantén segura tu cuenta DogGo.',
          color: _T.emerald,
          surface: _T.emeraldSurf,
          onTap: _abrirCambiarPassword,
        ),
        _ActionRow(
          icon: Icons.settings_rounded,
          title: 'Configuración',
          subtitle: 'Servidor, preferencias y opciones de la app.',
          color: _T.inkSub,
          surface: const Color(0xFFF3F4F6),
          onTap: () => _abrir(const ConfiguracionScreen()),
        ),
      ],
    );
  }

  Widget _buildCuenta() {
    return _SectionCard(
      title: '⚙️ Cuenta',
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      children: [
        _ActionRow(
          icon: Icons.logout_rounded,
          title: 'Cerrar sesión',
          subtitle: 'Salir de tu cuenta en este dispositivo.',
          color: _T.rose,
          surface: _T.roseSurf,
          onTap: _cerrarSesion,
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String texto;
  final IconData icono;

  const _HeaderChip({
    required this.texto,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: _ts(12, FontWeight.w800, Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;

  const _StatItem({
    required this.value,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 3),
        Text(
          value,
          style: _ts(13.5, FontWeight.w900, _T.ink, spacing: -.3),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: _ts(9.5, FontWeight.w500, _T.inkSub),
        ),
      ],
    );
  }
}

class _DividerSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: _T.stroke,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final EdgeInsets margin;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.margin,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _T.shadow(
          opacity: .05,
          blur: 16,
          offset: const Offset(0, 4),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: _ts(14, FontWeight.w900, _T.ink, spacing: -.2),
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color surface;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _ts(10.5, FontWeight.w700, _T.inkSub),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: _ts(14, FontWeight.w700, _T.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _ts(14, FontWeight.w800, _T.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _ts(11.5, FontWeight.w400, _T.inkSub, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD1D5DB),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}