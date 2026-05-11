import 'package:flutter/material.dart';

import '../services/paseadores_service.dart';
import '../services/storage_service.dart';
import '../services/usuario_service.dart';
import '../widgets/doggo_logo.dart';
import '../widgets/doggo_map_preview.dart';
import '../widgets/doggo_pattern_background.dart';
import 'editar_perfil_paseador_screen.dart';
import 'editar_perfil_screen.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final UsuarioService _usuarioService = UsuarioService();

  bool _cargando = true;
  String? _error;
  String? _baseUrl;

  Map<String, dynamic> _perfil = {};
  Map<String, dynamic>? _perfilPaseador;
  Map<String, dynamic>? _perfilDuenio;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final baseUrl = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = baseUrl;
    });

    await _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final perfil = await _usuarioService.obtenerPerfil();

      Map<String, dynamic>? perfilPaseador;
      Map<String, dynamic>? perfilDuenio;

      final rolDetectado = _rolDesdeMapa(perfil);

      if (_esPaseador(rolDetectado)) {
        try {
          perfilPaseador = await PaseadoresService.obtenerMiPerfilPaseador();
        } catch (_) {
          perfilPaseador = null;
        }
      }

      if (_esDuenio(rolDetectado)) {
        try {
          perfilDuenio = await _usuarioService.obtenerPerfilDuenio();
        } catch (_) {
          perfilDuenio = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _perfilPaseador = perfilPaseador;
        _perfilDuenio = perfilDuenio;
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

  dynamic _valor(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) {
        return mapa[key];
      }
    }

    return null;
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  double? _doubleSeguro(dynamic valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();

    return double.tryParse(valor.toString());
  }

  String _nombre() {
    return _texto(
      _valor(_perfil, ['nombre', 'Nombre', 'name', 'Name']),
      fallback: '',
    );
  }

  String _apellido() {
    return _texto(
      _valor(_perfil, ['apellido', 'Apellido', 'lastName', 'LastName']),
      fallback: '',
    );
  }

  String _nombreCompleto() {
    final completo = '${_nombre()} ${_apellido()}'.trim();
    return completo.isEmpty ? 'Usuario DogGo' : completo;
  }

  String _email() {
    return _texto(
      _valor(_perfil, ['email', 'Email', 'correo', 'Correo']),
      fallback: 'Correo no disponible',
    );
  }

  String _telefono() {
    return _texto(
      _valor(_perfil, ['telefono', 'Telefono', 'phone', 'Phone']),
      fallback: 'No registrado',
    );
  }

  String _rolDesdeMapa(Map<String, dynamic> mapa) {
    return _texto(
      _valor(mapa, ['rol', 'Rol', 'role', 'Role']),
      fallback: '',
    );
  }

  String _rol() {
    final rol = _rolDesdeMapa(_perfil);
    return rol.isNotEmpty ? rol : 'Usuario';
  }

  bool _esPaseador(String rol) {
    final normalizado = rol.trim().toLowerCase();

    return normalizado == 'paseador' ||
        normalizado.contains('paseador') ||
        normalizado == 'walker';
  }

  bool _esDuenio(String rol) {
    final normalizado = rol.trim().toLowerCase();

    return normalizado == 'dueño' ||
        normalizado == 'duenio' ||
        normalizado == 'dueno' ||
        normalizado.contains('dueño') ||
        normalizado.contains('duenio') ||
        normalizado.contains('dueno') ||
        normalizado == 'cliente' ||
        normalizado == 'owner';
  }

  bool _esAdmin(String rol) {
    final normalizado = rol.trim().toLowerCase();
    return normalizado == 'admin' || normalizado.contains('admin');
  }

  String _rolBonito() {
    final rol = _rol();

    if (_esPaseador(rol)) return 'Paseador';
    if (_esDuenio(rol)) return 'Dueño';
    if (_esAdmin(rol)) return 'Administrador';

    return rol.isEmpty ? 'Usuario' : rol;
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

  String? _fotoPerfil() {
    final fotoUsuario = _valor(
      _perfil,
      [
        'fotoUrl',
        'FotoUrl',
        'fotoPerfilUrl',
        'FotoPerfilUrl',
        'imagenUrl',
        'ImagenUrl',
        'foto',
        'Foto',
      ],
    );

    final fotoPaseador = _perfilPaseador == null
        ? null
        : _valor(
            _perfilPaseador!,
            [
              'fotoUrl',
              'FotoUrl',
              'imagenUrl',
              'ImagenUrl',
              'fotoPerfilUrl',
              'FotoPerfilUrl',
            ],
          );

    final fotoDuenio = _perfilDuenio == null
        ? null
        : _valor(
            _perfilDuenio!,
            [
              'fotoUrl',
              'FotoUrl',
              'imagenUrl',
              'ImagenUrl',
              'fotoPerfilUrl',
              'FotoPerfilUrl',
            ],
          );

    return _urlPublica(fotoPaseador ?? fotoDuenio ?? fotoUsuario);
  }

  String _direccionDuenio() {
    if (_perfilDuenio == null) return '';

    return _texto(
      _valor(_perfilDuenio!, ['direccion', 'Direccion']),
      fallback: '',
    );
  }

  String _zonaDuenio() {
    if (_perfilDuenio == null) return '';

    return _texto(
      _valor(_perfilDuenio!, ['zona', 'Zona']),
      fallback: '',
    );
  }

  String _referenciasDuenio() {
    if (_perfilDuenio == null) return '';

    return _texto(
      _valor(
        _perfilDuenio!,
        [
          'referenciasDireccion',
          'ReferenciasDireccion',
          'referencias',
          'Referencias',
        ],
      ),
      fallback: '',
    );
  }

  String _descripcionDuenio() {
    if (_perfilDuenio == null) return '';

    return _texto(
      _valor(_perfilDuenio!, ['descripcion', 'Descripcion']),
      fallback: '',
    );
  }

  String _preferenciasDuenio() {
    if (_perfilDuenio == null) return '';

    return _texto(
      _valor(
        _perfilDuenio!,
        ['preferenciasPaseo', 'PreferenciasPaseo'],
      ),
      fallback: '',
    );
  }

  double? _latitudDuenio() {
    if (_perfilDuenio == null) return null;

    return _doubleSeguro(
      _valor(_perfilDuenio!, ['latitud', 'Latitud']),
    );
  }

  double? _longitudDuenio() {
    if (_perfilDuenio == null) return null;

    return _doubleSeguro(
      _valor(_perfilDuenio!, ['longitud', 'Longitud']),
    );
  }

  String _descripcionPaseador() {
    if (_perfilPaseador == null) return '';

    return _texto(
      _valor(
        _perfilPaseador!,
        ['descripcion', 'Descripcion', 'descripción', 'bio', 'Bio'],
      ),
      fallback: '',
    );
  }

  String _zonaPaseador() {
    if (_perfilPaseador == null) return '';

    return _texto(
      _valor(
        _perfilPaseador!,
        ['zonaServicio', 'ZonaServicio', 'zona', 'Zona'],
      ),
      fallback: '',
    );
  }

  String _tarifaPaseador() {
    if (_perfilPaseador == null) return '';

    final valor = _valor(
      _perfilPaseador!,
      ['tarifaPorHora', 'TarifaPorHora', 'tarifa', 'Tarifa'],
    );

    if (valor == null) return '';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return '\$${valor.toString()} / hora';

    return '\$${numero.toStringAsFixed(2)} / hora';
  }

  String _experienciaPaseador() {
    if (_perfilPaseador == null) return '';

    final valor = _valor(
      _perfilPaseador!,
      [
        'experienciaAnios',
        'ExperienciaAnios',
        'experiencia',
        'Experiencia',
      ],
    );

    if (valor == null) return '';

    final numero = int.tryParse(valor.toString());

    if (numero == null) return '${valor.toString()} años';
    if (numero == 1) return '1 año';

    return '$numero años';
  }

  bool _disponiblePaseador() {
    if (_perfilPaseador == null) return false;

    final valor = _valor(_perfilPaseador!, ['disponible', 'Disponible']);

    if (valor is bool) return valor;

    final texto = valor?.toString().trim().toLowerCase();

    if (texto == null || texto.isEmpty || texto == 'null') return true;

    return texto == 'true' || texto == '1' || texto == 'si' || texto == 'sí';
  }

  bool _perfilPaseadorCompleto() {
    if (_perfilPaseador == null) return false;

    final foto = _fotoPerfil();
    final descripcion = _descripcionPaseador();
    final zona = _zonaPaseador();
    final tarifa = _tarifaPaseador();
    final experiencia = _experienciaPaseador();

    return foto != null &&
        foto.isNotEmpty &&
        descripcion.isNotEmpty &&
        zona.isNotEmpty &&
        tarifa.isNotEmpty &&
        experiencia.isNotEmpty;
  }

  Future<void> _abrirEditarPerfil() async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPerfilScreen(
          perfil: _perfil,
        ),
      ),
    );

    if (!mounted) return;

    if (actualizado == true) {
      await _cargarPerfil();
    }
  }

  Future<void> _abrirPerfilPaseador() async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditarPerfilPaseadorScreen(),
      ),
    );

    if (!mounted) return;

    if (actualizado == true) {
      await _cargarPerfil();
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _DogGoWeb.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Cerrar sesión',
            style: _DogGoWeb.title(22),
          ),
          content: Text(
            '¿Seguro que quieres cerrar sesión en DogGo?',
            style: _DogGoWeb.subtitle(14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: _DogGoWeb.rose,
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
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rol = _rol();
    final esDuenio = _esDuenio(rol);
    final esPaseador = _esPaseador(rol);

    return Scaffold(
      backgroundColor: _DogGoWeb.cream,
      body: SafeArea(
        child: DogGoPatternBackground(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                      onRefresh: _cargarPerfil,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(child: _buildTopBar()),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 24, 20, 30),
                              child: Column(
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 18),
                                  if (esDuenio)
                                    _buildDuenioProfile()
                                  else if (esPaseador)
                                    _buildPaseadorProfile()
                                  else
                                    _buildCuentaGenerica(),
                                  const SizedBox(height: 16),
                                  _buildDatosCuentaCompactos(),
                                  const SizedBox(height: 16),
                                  _buildAccionesFinales(),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: _FooterDogGo(),
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
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(.06),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _DogGoWeb.ink,
            ),
          ),
          const DogGoLogo(size: 52),
          const Spacer(),
          IconButton(
            onPressed: _cargarPerfil,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _DogGoWeb.ink,
            ),
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
            color: _DogGoWeb.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _DogGoWeb.stroke),
            boxShadow: _DogGoWeb.shadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 68,
                color: _DogGoWeb.rose,
              ),
              const SizedBox(height: 14),
              Text(
                'No se pudo cargar el perfil',
                textAlign: TextAlign.center,
                style: _DogGoWeb.title(21),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Error desconocido.',
                textAlign: TextAlign.center,
                style: _DogGoWeb.subtitle(13),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: _cargarPerfil,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _DogGoWeb.teal,
                    foregroundColor: Colors.white,
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
    final foto = _fotoPerfil();
    final tieneFoto = foto != null &&
        (foto.startsWith('http://') || foto.startsWith('https://'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _DogGoWeb.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _DogGoWeb.teal,
                  _DogGoWeb.tealDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'MI PERFIL DOGGO',
                  style: _DogGoWeb.label(color: Colors.white),
                ),
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: tieneFoto
                          ? Image.network(
                              foto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Colors.white,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _DogGoWeb.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _esPaseador(_rol())
                            ? Icons.directions_walk_rounded
                            : Icons.pets_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _nombreCompleto(),
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.title(
                    30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _email(),
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(
                    13,
                    color: Colors.white.withOpacity(.9),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(.28),
                    ),
                  ),
                  child: Text(
                    _rolBonito(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Text(
              _esDuenio(_rol())
                  ? 'Tu información de contacto, recolección y preferencias para los paseos.'
                  : _esPaseador(_rol())
                      ? 'Tu información personal y profesional como paseador.'
                      : 'Información principal de tu cuenta DogGo.',
              textAlign: TextAlign.center,
              style: _DogGoWeb.subtitle(13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuenioProfile() {
    final direccion = _direccionDuenio();
    final referencias = _referenciasDuenio();
    final zona = _zonaDuenio();
    final descripcion = _descripcionDuenio();
    final preferencias = _preferenciasDuenio();

    return _MainProfileCard(
      title: 'Perfil de dueño',
      subtitle: 'Información para coordinar la recolección',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionMiniHeader(
            icon: Icons.home_rounded,
            title: 'Datos de recolección',
            color: _DogGoWeb.teal,
          ),
          const SizedBox(height: 12),
          _CleanInfoItem(
            title: 'Dirección',
            value: direccion.isEmpty ? 'Sin dirección registrada' : direccion,
          ),
          _CleanInfoItem(
            title: 'Referencias',
            value: referencias.isEmpty
                ? 'Sin referencias registradas'
                : referencias,
          ),
          _CleanInfoItem(
            title: 'Zona',
            value: zona.isEmpty ? 'Sin zona registrada' : zona,
            last: true,
          ),
          const SizedBox(height: 18),
          _SectionMiniHeader(
            icon: Icons.location_on_rounded,
            title: 'Ubicación predeterminada',
            color: _DogGoWeb.orange,
          ),
          const SizedBox(height: 10),
          DogGoMapPreview(
            latitud: _latitudDuenio(),
            longitud: _longitudDuenio(),
            height: 230,
            emptyText: 'Sin ubicación predeterminada',
            onTap: _abrirEditarPerfil,
          ),
          const SizedBox(height: 18),
          _SectionMiniHeader(
            icon: Icons.notes_rounded,
            title: 'Notas para el paseador',
            color: _DogGoWeb.purple,
          ),
          const SizedBox(height: 12),
          _SoftTextBlock(
            title: 'Descripción',
            value:
                descripcion.isEmpty ? 'Sin descripción registrada' : descripcion,
          ),
          const SizedBox(height: 10),
          _SoftTextBlock(
            title: 'Preferencias de paseo',
            value: preferencias.isEmpty
                ? 'Sin preferencias registradas'
                : preferencias,
          ),
          const SizedBox(height: 20),
          _PrimarySmallButton(
            icon: Icons.edit_rounded,
            text: 'Editar perfil',
            onTap: _abrirEditarPerfil,
          ),
        ],
      ),
    );
  }

  Widget _buildPaseadorProfile() {
    final completo = _perfilPaseadorCompleto();

    return _MainProfileCard(
      title: 'Perfil de paseador',
      subtitle: completo
          ? 'Tu perfil profesional ya tiene la información principal.'
          : 'Completa tu información para verte mejor ante los dueños.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactStatusPill(
            text: completo
                ? _disponiblePaseador()
                    ? 'Perfil completo y disponible'
                    : 'Perfil completo, no disponible'
                : 'Perfil profesional pendiente',
            ok: completo,
          ),
          const SizedBox(height: 18),
          _SectionMiniHeader(
            icon: Icons.directions_walk_rounded,
            title: 'Información profesional',
            color: _DogGoWeb.purple,
          ),
          const SizedBox(height: 12),
          _CleanInfoItem(
            title: 'Descripción',
            value: _descripcionPaseador().isEmpty
                ? 'Sin descripción'
                : _descripcionPaseador(),
          ),
          _CleanInfoItem(
            title: 'Zona',
            value: _zonaPaseador().isEmpty ? 'Sin zona' : _zonaPaseador(),
          ),
          _CleanInfoItem(
            title: 'Tarifa',
            value:
                _tarifaPaseador().isEmpty ? 'Sin tarifa' : _tarifaPaseador(),
          ),
          _CleanInfoItem(
            title: 'Experiencia',
            value: _experienciaPaseador().isEmpty
                ? 'Sin experiencia'
                : _experienciaPaseador(),
            last: true,
          ),
          const SizedBox(height: 20),
          _PrimarySmallButton(
            icon: Icons.assignment_ind_rounded,
            text: completo ? 'Editar perfil profesional' : 'Completar perfil',
            onTap: _abrirPerfilPaseador,
            color: _DogGoWeb.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCuentaGenerica() {
    return _MainProfileCard(
      title: 'Cuenta DogGo',
      subtitle: 'Información principal de tu cuenta.',
      child: Column(
        children: [
          _CleanInfoItem(
            title: 'Nombre',
            value: _nombreCompleto(),
          ),
          _CleanInfoItem(
            title: 'Correo',
            value: _email(),
          ),
          _CleanInfoItem(
            title: 'Rol',
            value: _rolBonito(),
            last: true,
          ),
          const SizedBox(height: 20),
          _PrimarySmallButton(
            icon: Icons.edit_rounded,
            text: 'Editar cuenta',
            onTap: _abrirEditarPerfil,
          ),
        ],
      ),
    );
  }

  Widget _buildDatosCuentaCompactos() {
    return _MainProfileCard(
      title: 'Datos de cuenta',
      subtitle: 'Información básica registrada',
      compact: true,
      child: Column(
        children: [
          _CleanInfoItem(
            title: 'Nombre completo',
            value: _nombreCompleto(),
          ),
          _CleanInfoItem(
            title: 'Teléfono',
            value: _telefono(),
          ),
          _CleanInfoItem(
            title: 'Correo',
            value: _email(),
          ),
          _CleanInfoItem(
            title: 'Rol',
            value: _rolBonito(),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesFinales() {
    return Row(
      children: [
        Expanded(
          child: _SoftActionButton(
            icon: Icons.refresh_rounded,
            text: 'Recargar',
            onTap: _cargarPerfil,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SoftActionButton(
            icon: Icons.logout_rounded,
            text: 'Salir',
            danger: true,
            onTap: _cerrarSesion,
          ),
        ),
      ],
    );
  }
}

class _MainProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool compact;

  const _MainProfileCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        color: _DogGoWeb.card.withOpacity(.97),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _DogGoWeb.title(23),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: _DogGoWeb.subtitle(13),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SectionMiniHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionMiniHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: _DogGoWeb.body(
            15,
            color: _DogGoWeb.ink,
            weight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CleanInfoItem extends StatelessWidget {
  final String title;
  final String value;
  final bool last;

  const _CleanInfoItem({
    required this.title,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        bottom: last ? 0 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(
                  color: _DogGoWeb.stroke.withOpacity(.8),
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: _DogGoWeb.subtitle(12.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _DogGoWeb.body(
                13.3,
                color: _DogGoWeb.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftTextBlock extends StatelessWidget {
  final String title;
  final String value;

  const _SoftTextBlock({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _DogGoWeb.warm.withOpacity(.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _DogGoWeb.stroke.withOpacity(.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _DogGoWeb.subtitle(12.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: _DogGoWeb.body(
              13.5,
              color: _DogGoWeb.ink,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatusPill extends StatelessWidget {
  final String text;
  final bool ok;

  const _CompactStatusPill({
    required this.text,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? _DogGoWeb.green : _DogGoWeb.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: _DogGoWeb.body(
                13,
                color: _DogGoWeb.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimarySmallButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color color;

  const _PrimarySmallButton({
    required this.icon,
    required this.text,
    required this.onTap,
    this.color = _DogGoWeb.teal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(text),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SoftActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;
  final VoidCallback onTap;

  const _SoftActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _DogGoWeb.rose : _DogGoWeb.teal;
    final bg = danger ? _DogGoWeb.roseLight : _DogGoWeb.tealLight;

    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: bg.withOpacity(.75),
          side: BorderSide(
            color: color.withOpacity(.18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FooterDogGo extends StatelessWidget {
  const _FooterDogGo();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DogGoWeb.tealLight.withOpacity(.42),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
      child: Column(
        children: [
          const DogGoLogo(size: 40),
          const SizedBox(height: 10),
          Text(
            'DogGo © 2026 — Proyecto universitario',
            style: _DogGoWeb.subtitle(12.5),
          ),
        ],
      ),
    );
  }
}

class _DogGoWeb {
  static const teal = Color(0xFF0F9B8E);
  static const tealDeep = Color(0xFF0D8A7E);
  static const tealLight = Color(0xFFE0F5F3);

  static const purple = Color(0xFF7156C8);
  static const purpleLight = Color(0xFFEDE7FA);

  static const orange = Color(0xFFF5A623);
  static const orangeLight = Color(0xFFFFF3DC);

  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFE5F8ED);

  static const rose = Color(0xFFEF4444);
  static const roseLight = Color(0xFFFEEEEE);

  static const cream = Color(0xFFFFFBF5);
  static const warm = Color(0xFFFFF6ED);
  static const card = Colors.white;
  static const ink = Color(0xFF2D3142);
  static const muted = Color(0xFF7B8194);
  static const stroke = Color(0xFFEDE8E0);

  static TextStyle title(
    double size, {
    Color color = ink,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -.45,
      height: 1.08,
    );
  }

  static TextStyle subtitle(
    double size, {
    Color color = muted,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle label({
    Color color = tealDeep,
  }) {
    return TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: 1.5,
    );
  }

  static TextStyle body(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.25,
    );
  }

  static List<BoxShadow> shadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(.055),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}