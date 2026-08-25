import 'package:flutter/material.dart';

import '../services/paseadores_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../services/usuario_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'cambiar_password_screen.dart';
import 'configuracion_screen.dart';
import 'editar_perfil_screen.dart';
import 'editar_perfil_paseador_screen.dart';
import 'login_screen.dart';
import 'mis_paseos_screen.dart';
import 'mis_perros_screen.dart';
import 'verificacion_paseador_screen.dart';

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
    duration: const Duration(milliseconds: 550),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
  );

  Map<String, dynamic>? _perfil;
  Map<String, dynamic>? _perfilPaseador;

  bool _cargando = true;
  String? _error;
  String? _baseUrl;

  @override
  void initState() {
    super.initState();
    _animationController.forward();
    _cargarTodo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      _baseUrl = await StorageService.obtenerBaseUrl();

      final perfil = await _usuarioService.obtenerPerfil();

      Map<String, dynamic>? perfilPaseador;

      final rol = _texto(perfil['rol'], fallback: '');

      final esPaseador = rol.toLowerCase().contains('paseador');

      if (esPaseador) {
        try {
          perfilPaseador = await PaseadoresService.obtenerMiPerfilPaseador();
        } catch (_) {
          perfilPaseador = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _perfilPaseador = perfilPaseador;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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

  dynamic _valorUsuario(List<String> keys) {
    final perfil = _perfil;

    if (perfil == null) return null;

    for (final key in keys) {
      if (perfil.containsKey(key) && perfil[key] != null) {
        return perfil[key];
      }
    }

    return null;
  }

  dynamic _valorPaseador(List<String> keys) {
    final perfil = _perfilPaseador;

    if (perfil == null) return null;

    for (final key in keys) {
      if (perfil.containsKey(key) && perfil[key] != null) {
        return perfil[key];
      }
    }

    return null;
  }

  String? _urlPublica(dynamic valor) {
    final raw = valor?.toString().trim();

    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return raw;

    if (raw.startsWith('/')) {
      return '$base$raw';
    }

    return '$base/$raw';
  }

  String get _nombre {
    return _texto(_valorUsuario(['nombre']), fallback: '');
  }

  String get _apellido {
    return _texto(_valorUsuario(['apellido']), fallback: '');
  }

  String get _nombreCompleto {
    final completo = '$_nombre $_apellido'.trim();
    return completo.isEmpty ? 'Usuario DogGo' : completo;
  }

  String get _email {
    return _texto(_valorUsuario(['email']), fallback: 'Correo no disponible');
  }

  String get _telefono {
    return _texto(
      _valorUsuario(['telefono']),
      fallback: 'Teléfono no disponible',
    );
  }

  String get _rol {
    return _texto(_valorUsuario(['rol']), fallback: 'Usuario');
  }

  bool get _esPaseador {
    return _rol.toLowerCase().contains('paseador');
  }

  bool get _esDuenio {
    final rol = _rol.toLowerCase();

    return rol == 'duenio';
  }

  bool get _emailConfirmado {
    final valor = _valorUsuario(['emailConfirmado']);

    if (valor is bool) return valor;

    return valor?.toString().toLowerCase() == 'true';
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

  String? get _fotoPaseadorUrl {
    if (!_esPaseador) return null;

    return _urlPublica(_valorPaseador(['fotoUrl']));
  }

  String get _descripcionPaseador {
    return _texto(
      _valorPaseador(['descripcion']),
      fallback:
          'Agrega una descripción profesional para que los dueños conozcan tu experiencia.',
    );
  }

  String get _zonaServicio {
    return _texto(
      _valorPaseador(['zonaServicio']),
      fallback: 'Sin zona definida',
    );
  }

  String get _tarifaPaseador {
    final valor = _valorPaseador(['tarifaPorHora']);

    if (valor == null) return 'Sin tarifa';

    final numero = double.tryParse(valor.toString());

    if (numero == null || numero <= 0) return 'Sin tarifa';

    return '\$${numero.toStringAsFixed(2)} / hora';
  }

  String get _experienciaPaseador {
    final valor = _valorPaseador(['experienciaAnios']);

    if (valor == null) return 'Sin experiencia registrada';

    final numero = int.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    if (numero == 1) return '1 año de experiencia';

    return '$numero años de experiencia';
  }

  bool get _perfilProfesionalExiste {
    final existe = _valorPaseador(['existe']);

    if (existe is bool) return existe;

    return _perfilPaseador != null;
  }

  bool get _perfilProfesionalCompleto {
    final completo = _valorPaseador(['perfilCompleto']);

    if (completo is bool) return completo;

    if (!_esPaseador || _perfilPaseador == null) return false;

    final tieneDescripcion = _texto(
      _valorPaseador(['descripcion']),
      fallback: '',
    ).isNotEmpty;

    final tieneZona = _texto(
      _valorPaseador(['zonaServicio']),
      fallback: '',
    ).isNotEmpty;

    final tarifa =
        double.tryParse(_valorPaseador(['tarifaPorHora'])?.toString() ?? '') ??
        0;

    final tieneFoto = _fotoPaseadorUrl != null;

    return tieneDescripcion && tieneZona && tarifa > 0 && tieneFoto;
  }

  Future<void> _abrirEditarPerfil() async {
    if (_perfil == null) return;

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditarPerfilScreen(perfil: _perfil!)),
    );

    if (actualizado == true) {
      await _cargarTodo();
    }
  }

  Future<void> _abrirPerfilPaseador() async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditarPerfilPaseadorScreen()),
    );

    if (actualizado == true) {
      await _cargarTodo();
    }
  }

  Future<void> _abrirVerificacionPaseador() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerificacionPaseadorScreen()),
    );

    if (mounted) await _cargarTodo();
  }

  Future<void> _abrirCambiarPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CambiarPasswordScreen()),
    );
  }

  Future<void> _abrir(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    if (mounted) {
      await _cargarTodo();
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
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await SessionService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : FadeTransition(
                opacity: _fade,
                child: RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(child: _buildTopBar()),
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                          child: Column(
                            children: [
                              _buildEstadoCuenta(),
                              const SizedBox(height: 14),
                              if (_esPaseador) ...[
                                _buildPerfilProfesionalCard(),
                                const SizedBox(height: 14),
                              ],
                              _buildDatosPersonales(),
                              const SizedBox(height: 14),
                              _buildPanelRol(),
                              const SizedBox(height: 14),
                              _buildAccionesPrincipales(),
                              const SizedBox(height: 14),
                              _buildCuenta(),
                              const SizedBox(height: 34),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        border: Border(
          bottom: BorderSide(color: DogGoTheme.border.withOpacity(.8)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: DogGoTheme.ink),
          ),
          const SizedBox(width: 4),
          const DogGoLogo(size: 38),
          const Spacer(),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarTodo,
            icon: const Icon(Icons.refresh_rounded, color: DogGoTheme.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: DogGoTheme.border),
            boxShadow: DogGoTheme.softShadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 68,
                color: DogGoTheme.red,
              ),
              const SizedBox(height: 14),
              Text(
                'No se pudo cargar tu perfil',
                style: DogGoTheme.title(size: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: DogGoTheme.subtitle(size: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _cargarTodo,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: DogGoTheme.primaryButton(),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DogGoTheme.red,
                  side: const BorderSide(color: DogGoTheme.red),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final foto = _fotoPaseadorUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👤 PERFIL DOGGO', style: DogGoTheme.label(size: 11)),
          const SizedBox(height: 10),
          Text('Mi perfil', style: DogGoTheme.title(size: 34)),
          const SizedBox(height: 10),
          Text(
            _esPaseador
                ? 'Administra tus datos personales y tu perfil profesional de paseador.'
                : 'Administra tus datos personales, tus perros y tus paseos.',
            style: DogGoTheme.subtitle(size: 15),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _esPaseador ? DogGoTheme.purple : DogGoTheme.teal,
              borderRadius: BorderRadius.circular(26),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(.55),
                          width: 3,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: foto != null
                          ? Image.network(
                              foto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Center(
                                  child: Text(
                                    _iniciales,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 28,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                _iniciales,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _emailConfirmado
                              ? DogGoTheme.green
                              : DogGoTheme.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _emailConfirmado
                              ? Icons.verified_rounded
                              : Icons.warning_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreCompleto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.title(size: 24, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(
                          size: 13,
                          color: Colors.white.withOpacity(.88),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoCuenta() {
    return _WebCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _EstadoItem(
            value: _rolBonito,
            label: 'Rol',
            icono: _esPaseador
                ? Icons.directions_walk_rounded
                : Icons.pets_rounded,
            color: _esPaseador ? DogGoTheme.purple : DogGoTheme.teal,
            surface: _esPaseador
                ? DogGoTheme.purpleLight
                : DogGoTheme.tealLight,
          ),
          _DividerSmall(),
          _EstadoItem(
            value: _emailConfirmado ? 'Confirmado' : 'Pendiente',
            label: 'Correo',
            icono: _emailConfirmado
                ? Icons.verified_rounded
                : Icons.warning_rounded,
            color: _emailConfirmado ? DogGoTheme.green : DogGoTheme.orange,
            surface: _emailConfirmado
                ? DogGoTheme.greenLight
                : DogGoTheme.orangeLight,
          ),
          _DividerSmall(),
          _EstadoItem(
            value: 'Activa',
            label: 'Sesión',
            icono: Icons.lock_rounded,
            color: DogGoTheme.green,
            surface: DogGoTheme.greenLight,
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilProfesionalCard() {
    final completo = _perfilProfesionalCompleto;
    final foto = _fotoPaseadorUrl;

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              foto != null
                  ? Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: DogGoTheme.purpleLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.assignment_ind_rounded,
                            color: DogGoTheme.purple,
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: DogGoTheme.purpleLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: DogGoTheme.purple,
                      ),
                    ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completo
                          ? 'Perfil profesional activo'
                          : 'Completa tu perfil profesional',
                      style: DogGoTheme.title(size: 19),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      completo
                          ? 'Tu información ya puede mostrarse a los dueños.'
                          : 'Agrega foto, zona, tarifa y experiencia.',
                      style: DogGoTheme.subtitle(size: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DogGoTheme.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Text(
              _descripcionPaseador,
              style: DogGoTheme.subtitle(size: 13),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.location_on_rounded,
                text: _zonaServicio,
                color: DogGoTheme.teal,
                surface: DogGoTheme.tealLight,
              ),
              _InfoPill(
                icon: Icons.attach_money_rounded,
                text: _tarifaPaseador,
                color: DogGoTheme.green,
                surface: DogGoTheme.greenLight,
              ),
              _InfoPill(
                icon: Icons.workspace_premium_rounded,
                text: _experienciaPaseador,
                color: DogGoTheme.orange,
                surface: DogGoTheme.orangeLight,
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _abrirPerfilPaseador,
              icon: const Icon(Icons.edit_rounded),
              label: Text(
                _perfilProfesionalExiste
                    ? 'Editar perfil profesional'
                    : 'Completar perfil profesional',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DogGoTheme.purple,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosPersonales() {
    return _SectionCard(
      title: 'Información personal',
      icono: Icons.person_rounded,
      color: DogGoTheme.teal,
      surface: DogGoTheme.tealLight,
      children: [
        _InfoRow(
          icon: Icons.person_rounded,
          title: 'Nombre',
          value: _nombreCompleto,
          color: DogGoTheme.teal,
          surface: DogGoTheme.tealLight,
        ),
        _InfoRow(
          icon: Icons.email_rounded,
          title: 'Correo',
          value: _email,
          color: DogGoTheme.purple,
          surface: DogGoTheme.purpleLight,
        ),
        _InfoRow(
          icon: Icons.phone_rounded,
          title: 'Teléfono',
          value: _telefono,
          color: DogGoTheme.green,
          surface: DogGoTheme.greenLight,
        ),
      ],
    );
  }

  Widget _buildPanelRol() {
    return _SectionCard(
      title: _esPaseador ? 'Panel de paseador' : 'Panel de dueño',
      icono: _esPaseador ? Icons.directions_walk_rounded : Icons.pets_rounded,
      color: _esPaseador ? DogGoTheme.purple : DogGoTheme.teal,
      surface: _esPaseador ? DogGoTheme.purpleLight : DogGoTheme.tealLight,
      children: [
        if (_esPaseador)
          _ActionRow(
            icon: Icons.verified_user_rounded,
            title: 'Verificación profesional',
            subtitle: 'Carga tus documentos y consulta el estado de revisión.',
            color: DogGoTheme.green,
            surface: DogGoTheme.greenLight,
            onTap: _abrirVerificacionPaseador,
          ),
        _ActionRow(
          icon: _esPaseador
              ? Icons.route_rounded
              : Icons.directions_walk_rounded,
          title: _esPaseador ? 'Mis paseos asignados' : 'Mis paseos',
          subtitle: _esPaseador
              ? 'Acepta, inicia, finaliza y comparte ubicación.'
              : 'Consulta tus reservas, mapa y tracking.',
          color: DogGoTheme.orange,
          surface: DogGoTheme.orangeLight,
          onTap: () => _abrir(const MisPaseosScreen()),
        ),
        if (!_esPaseador)
          _ActionRow(
            icon: Icons.pets_rounded,
            title: 'Mis perros',
            subtitle: 'Administra tus mascotas registradas.',
            color: DogGoTheme.purple,
            surface: DogGoTheme.purpleLight,
            onTap: () => _abrir(const MisPerrosScreen()),
          ),
      ],
    );
  }

  Widget _buildAccionesPrincipales() {
    return _SectionCard(
      title: 'Acciones de cuenta',
      icono: Icons.tune_rounded,
      color: DogGoTheme.teal,
      surface: DogGoTheme.tealLight,
      children: [
        _ActionRow(
          icon: Icons.edit_rounded,
          title: 'Editar datos personales',
          subtitle: 'Actualiza nombre, apellido y teléfono.',
          color: DogGoTheme.teal,
          surface: DogGoTheme.tealLight,
          onTap: _abrirEditarPerfil,
        ),
        _ActionRow(
          icon: Icons.lock_reset_rounded,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza tu contraseña de acceso.',
          color: DogGoTheme.green,
          surface: DogGoTheme.greenLight,
          onTap: _abrirCambiarPassword,
        ),
        _ActionRow(
          icon: Icons.settings_rounded,
          title: 'Configuración',
          subtitle: 'Servidor, permisos y opciones reales de la app.',
          color: DogGoTheme.muted,
          surface: const Color(0xFFF3F4F6),
          onTap: () => _abrir(const ConfiguracionScreen()),
        ),
      ],
    );
  }

  Widget _buildCuenta() {
    return _SectionCard(
      title: 'Sesión',
      icono: Icons.logout_rounded,
      color: DogGoTheme.red,
      surface: DogGoTheme.redLight,
      children: [
        _ActionRow(
          icon: Icons.logout_rounded,
          title: 'Cerrar sesión',
          subtitle: 'Salir de tu cuenta en este dispositivo.',
          color: DogGoTheme.red,
          surface: DogGoTheme.redLight,
          onTap: _cerrarSesion,
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String texto;
  final IconData icono;

  const _HeaderChip({required this.texto, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _WebCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: child,
    );
  }
}

class _EstadoItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icono;
  final Color color;
  final Color surface;

  const _EstadoItem({
    required this.value,
    required this.label,
    required this.icono,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 19),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: DogGoTheme.body(
              size: 12,
              color: DogGoTheme.ink,
              weight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: DogGoTheme.subtitle(size: 9.5)),
        ],
      ),
    );
  }
}

class _DividerSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: DogGoTheme.border);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icono;
  final Color color;
  final Color surface;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icono,
    required this.color,
    required this.surface,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _WebCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(child: Text(title, style: DogGoTheme.title(size: 18))),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
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
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DogGoTheme.subtitle(size: 11.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: DogGoTheme.body(
                    size: 14,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w800,
                  ),
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
    return Material(
      color: DogGoTheme.cream,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.body(
                        size: 14,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: DogGoTheme.subtitle(size: 11.5)),
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
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color surface;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: DogGoTheme.body(
              size: 11,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
