import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../services/storage_service.dart';
import 'cambiar_password_screen.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);

  static const blue = Color(0xFF2563EB);
  static const blueSurface = Color(0xFFEFF6FF);

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

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final TextEditingController _urlController = TextEditingController();

  bool _guardandoUrl = false;
  bool _probandoConexion = false;
  bool _cargandoPermisos = true;

  PermissionStatus? _camaraStatus;
  PermissionStatus? _ubicacionStatus;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    await _cargarUrl();
    await _cargarPermisos();
  }

  Future<void> _cargarUrl() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _urlController.text = url ?? '';
    });
  }

  Future<void> _cargarPermisos() async {
    setState(() {
      _cargandoPermisos = true;
    });

    final camara = await Permission.camera.status;
    final ubicacion = await Permission.locationWhenInUse.status;

    if (!mounted) return;

    setState(() {
      _camaraStatus = camara;
      _ubicacionStatus = ubicacion;
      _cargandoPermisos = false;
    });
  }

  String _limpiarUrl(String url) {
    var limpia = url.trim();

    while (limpia.endsWith('/')) {
      limpia = limpia.substring(0, limpia.length - 1);
    }

    return limpia;
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  bool _validarUrl(String url) {
    if (url.isEmpty) {
      _mensaje('Escribe la URL del servidor.');
      return false;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _mensaje('La URL debe empezar con http:// o https://');
      return false;
    }

    if (url.endsWith('/api')) {
      _mensaje('No agregues /api al final. Guarda solo la URL base.');
      return false;
    }

    return true;
  }

  Future<void> _guardarUrl() async {
    final url = _limpiarUrl(_urlController.text);

    if (!_validarUrl(url)) return;

    setState(() {
      _guardandoUrl = true;
    });

    try {
      await StorageService.guardarBaseUrl(url);

      if (!mounted) return;

      _mensaje('Servidor actualizado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo guardar la URL: $e');
    } finally {
      if (mounted) {
        setState(() {
          _guardandoUrl = false;
        });
      }
    }
  }

  Future<void> _probarConexion() async {
    final url = _limpiarUrl(_urlController.text);

    if (!_validarUrl(url)) return;

    setState(() {
      _probandoConexion = true;
    });

    try {
      final uri = Uri.parse(url);

      final response = await http.get(uri).timeout(
            const Duration(seconds: 8),
          );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 500) {
        _mensaje('Servidor alcanzable. Código: ${response.statusCode}');
      } else {
        _mensaje('El servidor respondió con error: ${response.statusCode}');
      }
    } on TimeoutException {
      if (!mounted) return;
      _mensaje('No respondió el servidor. Revisa IP, puerto o red.');
    } catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo conectar al servidor: $e');
    } finally {
      if (mounted) {
        setState(() {
          _probandoConexion = false;
        });
      }
    }
  }

  Future<void> _pedirCamara() async {
    await Permission.camera.request();
    await _cargarPermisos();
  }

  Future<void> _pedirUbicacion() async {
    await Permission.locationWhenInUse.request();
    await _cargarPermisos();
  }

  Future<void> _abrirCambiarPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CambiarPasswordScreen(),
      ),
    );
  }

  Future<void> _abrirAjustesTelefono() async {
    await openAppSettings();
    await _cargarPermisos();
  }

  void _showAcercaDe() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Row(
          children: [
            const Text('🐾', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'DogGo',
              style: _ts(20, FontWeight.w900, _T.ink),
            ),
          ],
        ),
        content: Text(
          'DogGo móvil conecta dueños con paseadores usando la API real del proyecto. Esta pantalla solo muestra opciones que ya tienen función en la app.',
          style: _ts(13, FontWeight.w500, _T.inkSub, height: 1.35),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _textoPermiso(PermissionStatus? status) {
    if (status == null) return 'Revisando...';

    if (status.isGranted) return 'Permitido';
    if (status.isDenied) return 'Pendiente';
    if (status.isPermanentlyDenied) return 'Bloqueado';
    if (status.isRestricted) return 'Restringido';
    if (status.isLimited) return 'Limitado';

    return 'No permitido';
  }

  Color _colorPermiso(PermissionStatus? status) {
    if (status == null) return _T.inkSub;
    if (status.isGranted) return _T.emerald;
    if (status.isPermanentlyDenied) return _T.rose;
    return _T.amber;
  }

  Color _surfacePermiso(PermissionStatus? status) {
    if (status == null) return const Color(0xFFF3F4F6);
    if (status.isGranted) return _T.emeraldSurf;
    if (status.isPermanentlyDenied) return _T.roseSurf;
    return _T.amberSurf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('⚙️', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Configuración',
              style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarTodo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildServidorCard(),
              const SizedBox(height: 14),
              _buildPermisosCard(),
              const SizedBox(height: 14),
              _buildCuentaCard(),
              const SizedBox(height: 14),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EC9A0),
            Color(0xFF057A5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _T.teal.withOpacity(.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(.22),
              ),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajustes reales de DogGo',
                  style: _ts(20, FontWeight.w900, Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  'Aquí solo aparecen opciones funcionales para servidor, permisos y cuenta.',
                  style: _ts(
                    13,
                    FontWeight.w600,
                    Colors.white.withOpacity(.88),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServidorCard() {
    return _CardSeccion(
      titulo: 'Servidor',
      icono: Icons.dns_rounded,
      color: _T.teal,
      surface: _T.tealSurface,
      children: [
        Text(
          'URL base de la API',
          style: _ts(12, FontWeight.w800, _T.inkSub),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          enabled: !_guardandoUrl && !_probandoConexion,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'http://192.168.1.43:5230',
            prefixIcon: const Icon(Icons.link_rounded),
            filled: true,
            fillColor: const Color(0xFFF8F4EC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: _T.teal,
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BotonConfig(
                texto: _guardandoUrl ? 'Guardando...' : 'Guardar',
                icono: Icons.save_rounded,
                color: _T.teal,
                cargando: _guardandoUrl,
                onTap: _guardarUrl,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BotonConfig(
                texto: _probandoConexion ? 'Probando...' : 'Probar',
                icono: Icons.wifi_tethering_rounded,
                color: _T.blue,
                cargando: _probandoConexion,
                onTap: _probarConexion,
                outlined: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Nota(
          icono: Icons.info_outline_rounded,
          color: _T.amber,
          surface: _T.amberSurf,
          texto:
              'No uses localhost en el celular. Usa la IP de tu computadora o la URL de Cloudflare.',
        ),
      ],
    );
  }

  Widget _buildPermisosCard() {
    return _CardSeccion(
      titulo: 'Permisos del teléfono',
      icono: Icons.verified_user_rounded,
      color: _T.emerald,
      surface: _T.emeraldSurf,
      children: [
        if (_cargandoPermisos)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          _PermisoRow(
            icono: Icons.photo_camera_rounded,
            titulo: 'Cámara',
            descripcion: 'Para tomar fotos de perros y evidencias.',
            estado: _textoPermiso(_camaraStatus),
            color: _colorPermiso(_camaraStatus),
            surface: _surfacePermiso(_camaraStatus),
            onTap: _camaraStatus?.isGranted == true
                ? _abrirAjustesTelefono
                : _pedirCamara,
          ),
          const SizedBox(height: 10),
          _PermisoRow(
            icono: Icons.my_location_rounded,
            titulo: 'Ubicación',
            descripcion: 'Para tracking GPS durante paseos activos.',
            estado: _textoPermiso(_ubicacionStatus),
            color: _colorPermiso(_ubicacionStatus),
            surface: _surfacePermiso(_ubicacionStatus),
            onTap: _ubicacionStatus?.isGranted == true
                ? _abrirAjustesTelefono
                : _pedirUbicacion,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _abrirAjustesTelefono,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Abrir ajustes del teléfono'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.ink,
                side: const BorderSide(color: _T.stroke),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCuentaCard() {
    return _CardSeccion(
      titulo: 'Cuenta y seguridad',
      icono: Icons.lock_rounded,
      color: _T.violet,
      surface: _T.violetSurf,
      children: [
        _AccionRow(
          icono: Icons.lock_reset_rounded,
          titulo: 'Cambiar contraseña',
          descripcion: 'Actualiza tu contraseña con tu clave actual.',
          color: _T.violet,
          surface: _T.violetSurf,
          onTap: _abrirCambiarPassword,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return _CardSeccion(
      titulo: 'Información',
      icono: Icons.info_outline_rounded,
      color: _T.inkSub,
      surface: const Color(0xFFF3F4F6),
      children: [
        _AccionRow(
          icono: Icons.pets_rounded,
          titulo: 'Acerca de DogGo',
          descripcion: 'Información básica de la aplicación.',
          color: _T.teal,
          surface: _T.tealSurface,
          onTap: _showAcercaDe,
        ),
      ],
    );
  }
}

class _CardSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final Color surface;
  final List<Widget> children;

  const _CardSeccion({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.surface,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _T.shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  titulo,
                  style: _ts(16, FontWeight.w900, _T.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _PermisoRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final String estado;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _PermisoRow({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F4EC),
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
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: _ts(14, FontWeight.w900, _T.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion,
                      style: _ts(11.5, FontWeight.w600, _T.inkSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  estado,
                  style: _ts(10.5, FontWeight.w900, color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccionRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _AccionRow({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F4EC),
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
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: _ts(14, FontWeight.w900, _T.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion,
                      style: _ts(11.5, FontWeight.w600, _T.inkSub),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonConfig extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final bool cargando;
  final VoidCallback onTap;
  final bool outlined;

  const _BotonConfig({
    required this.texto,
    required this.icono,
    required this.color,
    required this.cargando,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: cargando ? null : onTap,
        icon: cargando
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icono),
        label: Text(texto),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: cargando ? null : onTap,
      icon: cargando
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icono),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  final IconData icono;
  final Color color;
  final Color surface;
  final String texto;

  const _Nota({
    required this.icono,
    required this.color,
    required this.surface,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: _ts(12, FontWeight.w700, _T.inkSub, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}