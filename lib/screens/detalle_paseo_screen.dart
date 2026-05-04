import 'package:flutter/material.dart';

import '../services/paseos_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import 'calificar_paseo_screen.dart';
import 'chat_paseo_screen.dart';
import 'evidencia_paseo_screen.dart';
import 'mapa_paseo_screen.dart';
import 'tracking_paseo_screen.dart';

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

  static const blue = Color(0xFF2563EB);
  static const blueSurf = Color(0xFFEFF6FF);

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

class DetallePaseoScreen extends StatefulWidget {
  final int? id;
  final int? paseoId;
  final Map<String, dynamic>? paseo;
  final String? rol;
  final VoidCallback? onPaseoActualizado;

  const DetallePaseoScreen({
    super.key,
    this.id,
    this.paseoId,
    this.paseo,
    this.rol,
    this.onPaseoActualizado,
  });

  @override
  State<DetallePaseoScreen> createState() => _DetallePaseoScreenState();
}

class _DetallePaseoScreenState extends State<DetallePaseoScreen> {
  Map<String, dynamic>? _paseo;
  bool _cargando = true;
  bool _accionando = false;
  String? _rolReal;
  String? _baseUrl;

  @override
  void initState() {
    super.initState();

    if (widget.paseo != null) {
      _paseo = Map<String, dynamic>.from(widget.paseo!);
    }

    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarBaseUrl();
    await _cargarRol();
    await _cargarDetalle();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = url;
    });
  }

  Future<void> _cargarRol() async {
    try {
      final rol = await SessionService.obtenerRol();

      if (!mounted) return;

      setState(() {
        _rolReal = rol ?? widget.rol;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _rolReal = widget.rol;
      });
    }
  }

  String get _rolUsuario {
    return _rolReal ?? widget.rol ?? '';
  }

  bool get _esPaseador {
    return SessionService.esPaseadorRol(_rolUsuario);
  }

  bool get _esDuenio {
    return SessionService.esDuenioRol(_rolUsuario);
  }

  int? get _idPaseo {
    final idDirecto = widget.paseoId ?? widget.id;

    if (idDirecto != null) return idDirecto;

    final idMapa = _paseo?['id'] ??
        _paseo?['Id'] ??
        widget.paseo?['id'] ??
        widget.paseo?['Id'] ??
        widget.paseo?['paseoId'] ??
        widget.paseo?['PaseoId'];

    if (idMapa is int) return idMapa;

    return int.tryParse(idMapa?.toString() ?? '');
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _estado() {
    return _texto(
      _paseo?['estado'] ?? _paseo?['Estado'],
      fallback: 'Pendiente',
    );
  }

  String _normalizarEstado() {
    return _estado().replaceAll(' ', '').toLowerCase();
  }

  bool get _esPendiente => _normalizarEstado() == 'pendiente';
  bool get _esAceptado => _normalizarEstado() == 'aceptado';
  bool get _esEnCurso => _normalizarEstado() == 'encurso';
  bool get _esFinalizado => _normalizarEstado() == 'finalizado';
  bool get _esCancelado => _normalizarEstado() == 'cancelado';

  bool get _puedeAceptar => _esPaseador && _esPendiente;
  bool get _puedeRechazar => _esPaseador && _esPendiente;
  bool get _puedeIniciar => _esPaseador && _esAceptado;
  bool get _puedeFinalizar => _esPaseador && _esEnCurso;

  bool get _puedeCancelar {
    if (_esFinalizado || _esCancelado) return false;
    return _esPaseador || _esDuenio;
  }

  bool get _puedeCalificar {
    return _esDuenio && _esFinalizado;
  }

  bool get _puedeSubirFotoInicio {
    if (!_esPaseador) return false;
    if (_esCancelado || _esFinalizado) return false;
    return _fotoInicio() == null;
  }

  bool get _puedeSubirFotoFin {
    if (!_esPaseador) return false;
    if (!_esEnCurso && !_esFinalizado) return false;
    return _fotoFin() == null;
  }

  bool get _puedeAbrirTrackingGps {
    return _esPaseador && _esEnCurso;
  }

  Color _colorEstado() {
    switch (_normalizarEstado()) {
      case 'pendiente':
        return _T.amber;
      case 'aceptado':
        return _T.blue;
      case 'encurso':
        return _T.emerald;
      case 'finalizado':
        return _T.violet;
      case 'cancelado':
        return _T.rose;
      default:
        return _T.inkSub;
    }
  }

  Color _surfaceEstado() {
    switch (_normalizarEstado()) {
      case 'pendiente':
        return _T.amberSurf;
      case 'aceptado':
        return _T.blueSurf;
      case 'encurso':
        return _T.emeraldSurf;
      case 'finalizado':
        return _T.violetSurf;
      case 'cancelado':
        return _T.roseSurf;
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData _iconoEstado() {
    switch (_normalizarEstado()) {
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'aceptado':
        return Icons.verified_rounded;
      case 'encurso':
        return Icons.directions_walk_rounded;
      case 'finalizado':
        return Icons.flag_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _fechaBonita(dynamic valor) {
    if (valor == null) return 'No disponible';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return valor.toString();

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  String _precio(dynamic valor) {
    if (valor == null) return 'No disponible';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    return '\$${numero.toStringAsFixed(2)}';
  }

  double? _doubleSeguro(dynamic valor) {
    if (valor == null) return null;

    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is num) return valor.toDouble();

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return null;

    return double.tryParse(texto);
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

  Map<String, dynamic> _normalizarDetalle(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      if (respuesta.containsKey('statusCode') && respuesta.containsKey('body')) {
        datos = respuesta['body'];
      } else {
        datos = respuesta;
      }
    }

    if (datos is Map) {
      datos = datos['data'] ??
          datos['paseo'] ??
          datos['detalle'] ??
          datos['resultado'] ??
          datos['result'] ??
          datos['value'] ??
          datos;
    }

    if (datos is Map) {
      return Map<String, dynamic>.from(datos);
    }

    throw Exception('La respuesta del detalle del paseo no tiene formato válido.');
  }

  Future<Map<String, dynamic>> _obtenerDetalleCompatible(int id) async {
    final respuesta = await PaseosService.obtenerPaseoPorId(id);
    return _normalizarDetalle(respuesta);
  }

  Future<void> _aceptarCompatible(int id) async {
    final result = await PaseosService.aceptarPaseo(id);

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'No se pudo aceptar el paseo.');
    }
  }

  Future<void> _rechazarCompatible(int id) async {
    final result = await PaseosService.rechazarPaseo(id);

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'No se pudo rechazar el paseo.');
    }
  }

  Future<void> _iniciarCompatible(int id) async {
    final result = await PaseosService.iniciarPaseo(id);

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'No se pudo iniciar el paseo.');
    }
  }

  Future<void> _finalizarCompatible(int id) async {
    final result = await PaseosService.finalizarPaseo(id);

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'No se pudo finalizar el paseo.');
    }
  }

  Future<void> _cancelarCompatible(int id, String motivo) async {
    final result = await PaseosService.cancelarPaseo(id);

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'No se pudo cancelar el paseo.');
    }
  }

  Future<void> _cargarDetalle() async {
    final id = _idPaseo;

    if (id == null) {
      setState(() {
        _cargando = false;
      });
      return;
    }

    try {
      final detalle = await _obtenerDetalleCompatible(id);

      if (!mounted) return;

      setState(() {
        _paseo = detalle;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      if (_paseo == null) {
        _mostrarMensaje('No se pudo cargar el detalle del paseo: $e');
      }
    }
  }

  Future<void> _ejecutarAccion({
    required Future<void> Function() accion,
    required String mensajeExito,
  }) async {
    if (_accionando) return;

    setState(() {
      _accionando = true;
    });

    try {
      await accion();

      if (!mounted) return;

      _mostrarMensaje(mensajeExito);
      widget.onPaseoActualizado?.call();

      await _cargarDetalle();
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Ocurrió un error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _accionando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  Future<void> _aceptarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeAceptar) return;

    await _ejecutarAccion(
      accion: () => _aceptarCompatible(id),
      mensajeExito: 'Paseo aceptado correctamente.',
    );
  }

  Future<void> _rechazarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeRechazar) return;

    await _ejecutarAccion(
      accion: () => _rechazarCompatible(id),
      mensajeExito: 'Paseo rechazado correctamente.',
    );
  }

  Future<void> _iniciarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeIniciar) return;

    await _ejecutarAccion(
      accion: () => _iniciarCompatible(id),
      mensajeExito: 'Paseo iniciado correctamente.',
    );
  }

  Future<void> _finalizarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeFinalizar) return;

    await _ejecutarAccion(
      accion: () => _finalizarCompatible(id),
      mensajeExito: 'Paseo finalizado correctamente.',
    );
  }

  Future<void> _cancelarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeCancelar) return;

    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Cancelar paseo'),
          content: TextField(
            controller: motivoController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Motivo de cancelación',
              hintText: 'Ej. Cambio de horario, lluvia, emergencia...',
              filled: true,
              fillColor: const Color(0xFFF8F4EC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.cancel_rounded),
              label: const Text('Cancelar paseo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.rose,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      motivoController.dispose();
      return;
    }

    final motivo = motivoController.text.trim();
    motivoController.dispose();

    if (motivo.isEmpty) {
      _mostrarMensaje('Escribe el motivo de cancelación.');
      return;
    }

    await _ejecutarAccion(
      accion: () => _cancelarCompatible(id, motivo),
      mensajeExito: 'Paseo cancelado correctamente.',
    );
  }

  Future<void> _abrirCalificarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeCalificar) return;

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CalificarPaseoScreen(
          paseoId: id,
          nombrePerro: _nombrePerro(),
          nombrePaseador: _nombrePaseador(),
        ),
      ),
    );

    if (actualizado == true) {
      await _cargarDetalle();
      widget.onPaseoActualizado?.call();
    }
  }

  Future<void> _abrirChatPaseo() async {
    final id = _idPaseo;

    if (id == null) return;

    final nombreOtroUsuario = _esPaseador ? _nombreDuenio() : _nombrePaseador();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPaseoScreen(
          paseoId: id,
          nombrePerro: _nombrePerro(),
          nombreOtroUsuario: nombreOtroUsuario,
        ),
      ),
    );
  }

  Future<void> _abrirEvidencia(String tipo) async {
    final id = _idPaseo;

    if (id == null) return;

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenciaPaseoScreen(
          paseoId: id,
          tipo: tipo,
          nombrePerro: _nombrePerro(),
          nombrePaseador: _nombrePaseador(),
        ),
      ),
    );

    if (actualizado == true) {
      await _cargarDetalle();
      widget.onPaseoActualizado?.call();
    }
  }

  Future<void> _abrirTrackingGps() async {
    final id = _idPaseo;

    if (id == null || !_puedeAbrirTrackingGps) return;

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingPaseoScreen(
          paseoId: id,
          nombrePerro: _nombrePerro(),
          nombrePaseador: _nombrePaseador(),
        ),
      ),
    );

    if (actualizado == true) {
      await _cargarDetalle();
      widget.onPaseoActualizado?.call();
    }
  }

  Future<void> _abrirMapaPaseo() async {
    if (_paseo == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaPaseoScreen(
          paseo: _paseo!,
        ),
      ),
    );
  }

  String _nombrePerro() {
    return _texto(
      _paseo?['perroNombre'] ??
          _paseo?['nombrePerro'] ??
          _paseo?['perro']?['nombre'] ??
          _paseo?['Perro']?['Nombre'],
      fallback: 'Perro',
    );
  }

  String _nombrePaseador() {
    final nombre = _paseo?['paseadorNombre'] ??
        _paseo?['nombrePaseador'] ??
        _paseo?['paseador']?['nombre'] ??
        _paseo?['paseador']?['usuario']?['nombre'] ??
        _paseo?['Paseador']?['Usuario']?['Nombre'];

    final apellido = _paseo?['paseadorApellido'] ??
        _paseo?['apellidoPaseador'] ??
        _paseo?['paseador']?['usuario']?['apellido'] ??
        _paseo?['Paseador']?['Usuario']?['Apellido'];

    final textoNombre = _texto(nombre, fallback: '');
    final textoApellido = _texto(apellido, fallback: '');

    final completo = '$textoNombre $textoApellido'.trim();

    return completo.isEmpty ? 'Paseador no asignado' : completo;
  }

  String _nombreDuenio() {
    final nombre = _paseo?['duenioNombre'] ??
        _paseo?['nombreDuenio'] ??
        _paseo?['dueñoNombre'] ??
        _paseo?['perro']?['duenio']?['nombre'] ??
        _paseo?['perro']?['usuario']?['nombre'];

    final apellido = _paseo?['duenioApellido'] ??
        _paseo?['apellidoDuenio'] ??
        _paseo?['dueñoApellido'] ??
        _paseo?['perro']?['duenio']?['apellido'] ??
        _paseo?['perro']?['usuario']?['apellido'];

    final textoNombre = _texto(nombre, fallback: '');
    final textoApellido = _texto(apellido, fallback: '');

    final completo = '$textoNombre $textoApellido'.trim();

    return completo.isEmpty ? 'Dueño no disponible' : completo;
  }

  String _direccionRecogida() {
    return _texto(
      _paseo?['ubicacionTexto'] ??
          _paseo?['ubicacionRecogidaTexto'] ??
          _paseo?['direccionRecogida'] ??
          _paseo?['direccion'] ??
          _paseo?['UbicacionTexto'] ??
          _paseo?['UbicacionRecogidaTexto'] ??
          _paseo?['DireccionRecogida'] ??
          _paseo?['Direccion'],
      fallback: 'Ubicación de recogida no definida',
    );
  }

  double? _latitudRecogida() {
    return _doubleSeguro(
      _paseo?['latitudRecogida'] ??
          _paseo?['latRecogida'] ??
          _paseo?['ubicacionLatitud'] ??
          _paseo?['latitud'] ??
          _paseo?['LatitudRecogida'] ??
          _paseo?['LatRecogida'] ??
          _paseo?['UbicacionLatitud'] ??
          _paseo?['Latitud'],
    );
  }

  double? _longitudRecogida() {
    return _doubleSeguro(
      _paseo?['longitudRecogida'] ??
          _paseo?['lngRecogida'] ??
          _paseo?['lonRecogida'] ??
          _paseo?['ubicacionLongitud'] ??
          _paseo?['longitud'] ??
          _paseo?['LongitudRecogida'] ??
          _paseo?['LngRecogida'] ??
          _paseo?['LonRecogida'] ??
          _paseo?['UbicacionLongitud'] ??
          _paseo?['Longitud'],
    );
  }

  bool _tieneCoordenadasRecogida() {
    return _latitudRecogida() != null && _longitudRecogida() != null;
  }

  String _coordenadasRecogida() {
    final latitud = _latitudRecogida();
    final longitud = _longitudRecogida();

    if (latitud == null || longitud == null) {
      return 'Coordenadas no disponibles';
    }

    return '${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
  }

  dynamic _fechaProgramada() {
    return _paseo?['fechaProgramada'] ??
        _paseo?['FechaProgramada'] ??
        _paseo?['fechaInicio'] ??
        _paseo?['FechaInicio'];
  }

  dynamic _fechaInicio() {
    return _paseo?['fechaInicio'] ?? _paseo?['FechaInicio'];
  }

  dynamic _fechaFin() {
    return _paseo?['fechaFin'] ?? _paseo?['FechaFin'];
  }

  dynamic _duracion() {
    return _paseo?['duracionMinutos'] ?? _paseo?['DuracionMinutos'];
  }

  dynamic _precioPaseo() {
    return _paseo?['precio'] ?? _paseo?['Precio'];
  }

  String? _motivoCancelacion() {
    final valor = _paseo?['motivoCancelacion'] ?? _paseo?['MotivoCancelacion'];
    final texto = valor?.toString().trim();

    if (texto == null || texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  String? _canceladoPor() {
    final valor = _paseo?['canceladoPor'] ?? _paseo?['CanceladoPor'];
    final texto = valor?.toString().trim();

    if (texto == null || texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  dynamic _fechaCancelacion() {
    return _paseo?['fechaCancelacion'] ?? _paseo?['FechaCancelacion'];
  }

  String? _fotoInicio() {
    final foto = _paseo?['fotoInicioUrl'] ?? _paseo?['FotoInicioUrl'];
    return _urlPublica(foto);
  }

  String? _fotoFin() {
    final foto = _paseo?['fotoFinUrl'] ?? _paseo?['FotoFinUrl'];
    return _urlPublica(foto);
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorEstado();
    final surfaceEstado = _surfaceEstado();

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                child: Text(
                  '🦮',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Detalle del paseo',
              style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarDetalle,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _paseo == null
              ? _buildSinDatos()
              : RefreshIndicator(
                  onRefresh: _cargarDetalle,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.zero,
                    children: [
                      _buildHeader(colorEstado, surfaceEstado),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          children: [
                            _buildRolCard(),
                            const SizedBox(height: 14),
                            _buildBotonesPrincipales(),
                            const SizedBox(height: 14),
                            _buildInfoPrincipal(),
                            const SizedBox(height: 14),
                            _buildUbicacionCard(),
                            const SizedBox(height: 14),
                            _buildFechasCard(),
                            if (_esCancelado) ...[
                              const SizedBox(height: 14),
                              _buildCancelacionCard(),
                            ],
                            const SizedBox(height: 14),
                            _buildEvidenciasCard(),
                            const SizedBox(height: 14),
                            _buildAcciones(),
                            const SizedBox(height: 34),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSinDatos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _T.shadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 64,
                color: _T.inkSub.withOpacity(.75),
              ),
              const SizedBox(height: 12),
              Text(
                'No se encontró información del paseo.',
                textAlign: TextAlign.center,
                style: _ts(18, FontWeight.w900, _T.ink),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color colorEstado, Color surfaceEstado) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF089B7A),
            Color(0xFFF4F0E8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0EC9A0),
                Color(0xFF057A5F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _T.teal.withOpacity(.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -38,
                right: -35,
                child: Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SmallPill(
                    text: 'DETALLE DOGGO',
                    color: Colors.white,
                    background: Colors.white.withOpacity(.18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nombrePerro(),
                    style: _ts(
                      31,
                      FontWeight.w900,
                      Colors.white,
                      spacing: -.8,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paseador: ${_nombrePaseador()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(
                      14,
                      FontWeight.w500,
                      Colors.white.withOpacity(.82),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _EstadoBadgeGrande(
                        estado: _estado(),
                        color: colorEstado,
                        surface: surfaceEstado,
                        icono: _iconoEstado(),
                      ),
                      _HeaderTag(
                        texto: _fechaBonita(_fechaProgramada()),
                        icono: Icons.calendar_month_rounded,
                      ),
                      _HeaderTag(
                        texto: _precio(_precioPaseo()),
                        icono: Icons.attach_money_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolCard() {
    final rolTexto = SessionService.normalizarRol(_rolUsuario);

    final color = _esPaseador
        ? _T.emerald
        : _esDuenio
            ? _T.blue
            : _T.amber;

    final surface = _esPaseador
        ? _T.emeraldSurf
        : _esDuenio
            ? _T.blueSurf
            : _T.amberSurf;

    final descripcion = _esPaseador
        ? 'Puedes gestionar este paseo, subir evidencias, usar chat y activar GPS.'
        : _esDuenio
            ? 'Puedes consultar el paseo, ver mapa, usar chat y calificar al finalizar.'
            : 'No se detectó un rol claro. Algunas acciones estarán ocultas.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _T.shadow(opacity: .045),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.badge_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$rolTexto: $descripcion',
              style: _ts(12.5, FontWeight.w700, _T.ink, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPrincipal() {
    return _CardSeccion(
      titulo: 'Información del paseo',
      icono: Icons.assignment_rounded,
      color: _T.teal,
      surface: _T.tealSurface,
      children: [
        _InfoRow(
          icono: Icons.pets_rounded,
          titulo: 'Perro',
          valor: _nombrePerro(),
          color: _T.teal,
          surface: _T.tealSurface,
        ),
        _InfoRow(
          icono: Icons.person_rounded,
          titulo: 'Dueño',
          valor: _nombreDuenio(),
          color: _T.violet,
          surface: _T.violetSurf,
        ),
        _InfoRow(
          icono: Icons.directions_walk_rounded,
          titulo: 'Paseador',
          valor: _nombrePaseador(),
          color: _T.emerald,
          surface: _T.emeraldSurf,
        ),
        _InfoRow(
          icono: Icons.timer_rounded,
          titulo: 'Duración',
          valor:
              _duracion() == null ? 'No disponible' : '${_duracion()} minutos',
          color: _T.amber,
          surface: _T.amberSurf,
        ),
        _InfoRow(
          icono: Icons.attach_money_rounded,
          titulo: 'Precio',
          valor: _precio(_precioPaseo()),
          color: _T.blue,
          surface: _T.blueSurf,
        ),
      ],
    );
  }

  Widget _buildBotonesPrincipales() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _paseo == null ? null : _abrirMapaPaseo,
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _abrirChatPaseo,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.blue,
                    side: const BorderSide(
                      color: _T.blue,
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_puedeAbrirTrackingGps) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _abrirTrackingGps,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Abrir tracking GPS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.emerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUbicacionCard() {
    final tieneCoordenadas = _tieneCoordenadasRecogida();

    return _CardSeccion(
      titulo: 'Ubicación',
      icono: Icons.location_on_rounded,
      color: _T.teal,
      surface: _T.tealSurface,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tieneCoordenadas ? _T.tealSurface : _T.amberSurf,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tieneCoordenadas
                  ? _T.teal.withOpacity(.18)
                  : _T.amber.withOpacity(.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.75),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  tieneCoordenadas
                      ? Icons.home_rounded
                      : Icons.location_off_rounded,
                  color: tieneCoordenadas ? _T.tealDeep : _T.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tieneCoordenadas
                          ? 'Punto de recogida'
                          : 'Sin coordenadas',
                      style: _ts(
                        13,
                        FontWeight.w900,
                        tieneCoordenadas ? _T.tealDeep : _T.amber,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _direccionRecogida(),
                      style: _ts(14, FontWeight.w800, _T.ink, height: 1.3),
                    ),
                    if (tieneCoordenadas) ...[
                      const SizedBox(height: 6),
                      Text(
                        _coordenadasRecogida(),
                        style: _ts(12.5, FontWeight.w600, _T.inkSub),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (tieneCoordenadas)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _abrirMapaPaseo,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Ver punto de recogida en mapa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.tealDeep,
                side: const BorderSide(
                  color: _T.tealDeep,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.amberSurf,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _T.amber.withOpacity(.25),
              ),
            ),
            child: Text(
              'Este paseo todavía no tiene coordenadas de recogida registradas.',
              style: _ts(12.5, FontWeight.w700, const Color(0xFF8A6A1F)),
            ),
          ),
        const SizedBox(height: 13),
        _InfoRow(
          icono: Icons.my_location_rounded,
          titulo: 'Tracking',
          valor: _esEnCurso
              ? 'El paseo está en curso. Puedes revisar el mapa y activar GPS.'
              : _esFinalizado
                  ? 'El paseo ya finalizó. Puedes revisar la última ubicación.'
                  : _esCancelado
                      ? 'El paseo fue cancelado. El tracking no está activo.'
                      : 'El tracking se activa cuando inicia el paseo.',
          color: _T.emerald,
          surface: _T.emeraldSurf,
        ),
      ],
    );
  }

  Widget _buildFechasCard() {
    return _CardSeccion(
      titulo: 'Fechas',
      icono: Icons.calendar_month_rounded,
      color: _T.violet,
      surface: _T.violetSurf,
      children: [
        _InfoRow(
          icono: Icons.event_rounded,
          titulo: 'Fecha programada',
          valor: _fechaBonita(_fechaProgramada()),
          color: _T.violet,
          surface: _T.violetSurf,
        ),
        _InfoRow(
          icono: Icons.play_circle_rounded,
          titulo: 'Inicio',
          valor: _fechaBonita(_fechaInicio()),
          color: _T.emerald,
          surface: _T.emeraldSurf,
        ),
        _InfoRow(
          icono: Icons.flag_circle_rounded,
          titulo: 'Fin',
          valor: _fechaBonita(_fechaFin()),
          color: _T.amber,
          surface: _T.amberSurf,
        ),
      ],
    );
  }

  Widget _buildCancelacionCard() {
    return _CardSeccion(
      titulo: 'Cancelación',
      icono: Icons.cancel_rounded,
      color: _T.rose,
      surface: _T.roseSurf,
      children: [
        _InfoRow(
          icono: Icons.person_off_rounded,
          titulo: 'Cancelado por',
          valor: _canceladoPor() ?? 'No disponible',
          color: _T.rose,
          surface: _T.roseSurf,
        ),
        _InfoRow(
          icono: Icons.calendar_today_rounded,
          titulo: 'Fecha de cancelación',
          valor: _fechaBonita(_fechaCancelacion()),
          color: _T.amber,
          surface: _T.amberSurf,
        ),
        _InfoRow(
          icono: Icons.notes_rounded,
          titulo: 'Motivo',
          valor: _motivoCancelacion() ?? 'Sin motivo registrado',
          color: _T.violet,
          surface: _T.violetSurf,
        ),
      ],
    );
  }

  Widget _buildEvidenciasCard() {
    final fotoInicio = _fotoInicio();
    final fotoFin = _fotoFin();

    return _CardSeccion(
      titulo: 'Evidencias',
      icono: Icons.photo_camera_rounded,
      color: _T.amber,
      surface: _T.amberSurf,
      children: [
        if (fotoInicio == null && fotoFin == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.stroke),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  color: _T.inkSub,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Todavía no hay fotos de inicio o fin del paseo.',
                    style: _ts(12.5, FontWeight.w700, _T.inkSub, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        if (fotoInicio != null)
          _FotoEvidencia(
            titulo: 'Foto de inicio',
            url: fotoInicio,
          ),
        if (fotoInicio != null && fotoFin != null) const SizedBox(height: 12),
        if (fotoFin != null)
          _FotoEvidencia(
            titulo: 'Foto de fin',
            url: fotoFin,
          ),
        if (_puedeSubirFotoInicio || _puedeSubirFotoFin) ...[
          const SizedBox(height: 14),
          if (_puedeSubirFotoInicio)
            _BotonAccion(
              texto: 'Subir foto de inicio',
              icono: Icons.add_a_photo_rounded,
              color: _T.emerald,
              cargando: false,
              onPressed: () => _abrirEvidencia('inicio'),
            ),
          if (_puedeSubirFotoInicio && _puedeSubirFotoFin)
            const SizedBox(height: 10),
          if (_puedeSubirFotoFin)
            _BotonAccion(
              texto: 'Subir foto de fin',
              icono: Icons.photo_camera_back_rounded,
              color: _T.violet,
              cargando: false,
              onPressed: () => _abrirEvidencia('fin'),
            ),
        ],
      ],
    );
  }

  Widget _buildAcciones() {
    final acciones = <Widget>[];

    acciones.addAll([
      _BotonAccion(
        texto: 'Abrir chat del paseo',
        icono: Icons.chat_rounded,
        color: _T.blue,
        cargando: false,
        onPressed: _abrirChatPaseo,
      ),
      const SizedBox(height: 10),
    ]);

    if (_puedeAbrirTrackingGps) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Abrir tracking GPS',
          icono: Icons.my_location_rounded,
          color: _T.emerald,
          cargando: false,
          onPressed: _abrirTrackingGps,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_puedeAceptar) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Aceptar paseo',
          icono: Icons.check_rounded,
          color: _T.emerald,
          cargando: _accionando,
          onPressed: _aceptarPaseo,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_puedeRechazar) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Rechazar paseo',
          icono: Icons.close_rounded,
          color: _T.rose,
          cargando: _accionando,
          onPressed: _rechazarPaseo,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_puedeIniciar) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Iniciar paseo',
          icono: Icons.play_arrow_rounded,
          color: _T.emerald,
          cargando: _accionando,
          onPressed: _iniciarPaseo,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_puedeFinalizar) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Finalizar paseo',
          icono: Icons.flag_rounded,
          color: _T.violet,
          cargando: _accionando,
          onPressed: _finalizarPaseo,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_puedeCancelar) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Cancelar paseo',
          icono: Icons.cancel_rounded,
          color: _T.rose,
          cargando: _accionando,
          onPressed: _cancelarPaseo,
          outlined: true,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_puedeCalificar) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Calificar paseo',
          icono: Icons.star_rounded,
          color: _T.amber,
          cargando: _accionando,
          onPressed: _abrirCalificarPaseo,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (acciones.isNotEmpty && acciones.last is SizedBox) {
      acciones.removeLast();
    }

    return _CardSeccion(
      titulo: 'Acciones',
      icono: Icons.touch_app_rounded,
      color: _T.teal,
      surface: _T.tealSurface,
      children: acciones,
    );
  }
}

class _EstadoBadgeGrande extends StatelessWidget {
  final String estado;
  final Color color;
  final Color surface;
  final IconData icono;

  const _EstadoBadgeGrande({
    required this.estado,
    required this.color,
    required this.surface,
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
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            estado,
            style: _ts(11.5, FontWeight.w900, color),
          ),
        ],
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  final String texto;
  final IconData icono;

  const _HeaderTag({
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
          color: Colors.white.withOpacity(.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: _ts(11.5, FontWeight.w800, Colors.white),
          ),
        ],
      ),
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
        boxShadow: _T.shadow(
          opacity: .05,
          blur: 16,
          offset: const Offset(0, 5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
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

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final Color surface;

  const _InfoRow({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icono,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: _ts(12, FontWeight.w700, _T.inkSub),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: _ts(14, FontWeight.w800, _T.ink, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoEvidencia extends StatelessWidget {
  final String titulo;
  final String url;

  const _FotoEvidencia({
    required this.titulo,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final esUrlAbsoluta =
        url.startsWith('http://') || url.startsWith('https://');

    if (!esUrlAbsoluta) {
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.stroke),
        ),
        child: Text(
          '$titulo: imagen registrada, pero falta URL pública.',
          style: _ts(12.5, FontWeight.w700, _T.inkSub, height: 1.3),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: _ts(13, FontWeight.w900, _T.ink),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            url,
            height: 185,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 130,
                width: double.infinity,
                color: const Color(0xFFF3F4F6),
                alignment: Alignment.center,
                child: Text(
                  'No se pudo cargar la imagen',
                  style: _ts(12.5, FontWeight.w700, _T.inkSub),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final bool cargando;
  final VoidCallback onPressed;
  final bool outlined;

  const _BotonAccion({
    required this.texto,
    required this.icono,
    required this.color,
    required this.cargando,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: cargando ? null : onPressed,
          icon: cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icono),
          label: Text(texto),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(
              color: color,
              width: 1.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: cargando ? null : onPressed,
        icon: cargando
            ? const SizedBox(
                width: 18,
                height: 18,
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
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _SmallPill({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(.20),
        ),
      ),
      child: Text(
        text,
        style: _ts(10, FontWeight.w900, color, spacing: 1.2),
      ),
    );
  }
}