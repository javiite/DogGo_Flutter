import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/background_tracking_service.dart';
import '../services/paseos_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'calificar_paseo_screen.dart';
import 'chat_paseo_screen.dart';
import 'evidencia_paseo_screen.dart';
import 'mapa_paseo_screen.dart';
import 'tracking_paseo_screen.dart';

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
    if (idMapa is num) return idMapa.toInt();

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

  double? _doubleSeguro(dynamic valor) {
    if (valor == null) return null;

    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is num) return valor.toDouble();

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return null;

    return double.tryParse(texto);
  }

  bool _coordenadaValida(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;

    return true;
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

  bool get _puedeAbrirTrackingGps {
    return _esPaseador && _esEnCurso;
  }

  bool get _tieneFotoInicio {
    return _fotoInicio() != null;
  }

  bool get _tieneFotoFin {
    return _fotoFin() != null;
  }

  Color _colorEstado() {
    switch (_normalizarEstado()) {
      case 'pendiente':
        return DogGoTheme.orange;
      case 'aceptado':
        return DogGoTheme.purple;
      case 'encurso':
        return DogGoTheme.green;
      case 'finalizado':
        return DogGoTheme.teal;
      case 'cancelado':
        return DogGoTheme.red;
      default:
        return DogGoTheme.muted;
    }
  }

  Color _surfaceEstado() {
    switch (_normalizarEstado()) {
      case 'pendiente':
        return DogGoTheme.orangeLight;
      case 'aceptado':
        return DogGoTheme.purpleLight;
      case 'encurso':
        return DogGoTheme.greenLight;
      case 'finalizado':
        return DogGoTheme.tealLight;
      case 'cancelado':
        return DogGoTheme.redLight;
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

  String _fechaCorta(dynamic valor) {
    if (valor == null) return '--/--';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return valor.toString();

    final local = fecha.toLocal();

    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${local.day} ${meses[local.month - 1]}';
  }

  String _horaCorta(dynamic valor) {
    if (valor == null) return '--:--';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return '--:--';

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.hour)}:${dos(local.minute)}';
  }

  String _precio(dynamic valor) {
    if (valor == null) return 'No disponible';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    return '\$${numero.toStringAsFixed(2)}';
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
    final result = await PaseosService.cancelarPaseo(
      id,
      motivo: motivo,
    );

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
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _aceptarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeAceptar) return;

    await _ejecutarAccion(
      accion: () => _aceptarCompatible(id),
      mensajeExito:
          'Paseo aceptado. Ahora puedes iniciarlo cuando llegues con el perro.',
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
      mensajeExito: 'Paseo iniciado. Ahora sube la foto de inicio.',
    );
  }

  Future<void> _finalizarPaseo() async {
    final id = _idPaseo;

    if (id == null || !_puedeFinalizar) return;

    if (_fotoFin() == null) {
      final subir = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: DogGoTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Foto final requerida'),
            content: const Text(
              'Antes de finalizar el paseo, sube una foto de fin como evidencia.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.photo_camera_back_rounded),
                label: const Text('Subir foto de fin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DogGoTheme.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          );
        },
      );

      if (subir == true) {
        await _abrirEvidencia('fin');
      }

      return;
    }

    await _ejecutarAccion(
      accion: () async {
        await BackgroundTrackingService.detenerTracking();
        await _finalizarCompatible(id);
      },
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
          backgroundColor: DogGoTheme.card,
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
              fillColor: DogGoTheme.cream,
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
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
                elevation: 0,
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
      accion: () async {
        await BackgroundTrackingService.detenerTracking();
        await _cancelarCompatible(id, motivo);
      },
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

      if (tipo == 'inicio') {
        _mostrarMensaje(
          'Foto de inicio guardada. Ahora activa la ubicación en vivo.',
        );
      } else {
        _mostrarMensaje('Foto final guardada. Ya puedes finalizar el paseo.');
      }
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

  String _referenciasRecogida() {
    return _texto(
      _paseo?['referenciasRecogida'] ??
          _paseo?['ReferenciasRecogida'] ??
          _paseo?['referencias'] ??
          _paseo?['Referencias'],
      fallback: 'Sin referencias adicionales',
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
    return _coordenadaValida(_latitudRecogida(), _longitudRecogida());
  }

  String _coordenadasRecogida() {
    final latitud = _latitudRecogida();
    final longitud = _longitudRecogida();

    if (!_coordenadaValida(latitud, longitud)) {
      return 'Coordenadas no disponibles';
    }

    return '${latitud!.toStringAsFixed(6)}, ${longitud!.toStringAsFixed(6)}';
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

  String? _fotoPerro() {
    final foto = _paseo?['perroFotoUrl'] ??
        _paseo?['fotoPerroUrl'] ??
        _paseo?['PerroFotoUrl'] ??
        _paseo?['FotoPerroUrl'] ??
        _paseo?['perro']?['fotoUrl'] ??
        _paseo?['perro']?['FotoUrl'] ??
        _paseo?['perro']?['imagenUrl'] ??
        _paseo?['perro']?['ImagenUrl'] ??
        _paseo?['Perro']?['FotoUrl'] ??
        _paseo?['Perro']?['ImagenUrl'];

    return _urlPublica(foto);
  }

  String _duracionTexto() {
    final valor = _duracion();
    if (valor == null) return 'Sin duración';
    return '$valor min';
  }

  String _estadoMensaje() {
    if (_esPendiente) {
      return _esPaseador
          ? 'Solicitud pendiente de respuesta.'
          : 'El paseador todavía no confirma la solicitud.';
    }

    if (_esAceptado) {
      return _esPaseador
          ? 'Listo para iniciar cuando llegues al punto de recogida.'
          : 'El paseador ya aceptó el servicio.';
    }

    if (_esEnCurso) {
      return _tieneFotoInicio
          ? 'Paseo activo. Revisa mapa, evidencias y ubicación en vivo.'
          : 'Paseo activo. Falta subir la foto de inicio.';
    }

    if (_esFinalizado) {
      return _esDuenio
          ? 'Servicio terminado. Puedes calificar la experiencia.'
          : 'Servicio terminado correctamente.';
    }

    if (_esCancelado) {
      return 'Este paseo fue cancelado.';
    }

    return 'Consulta los datos principales del paseo.';
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorEstado();
    final surfaceEstado = _surfaceEstado();

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _paseo == null
                ? _buildSinDatos()
                : RefreshIndicator(
                    onRefresh: _cargarDetalle,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildTopBar()),
                        SliverToBoxAdapter(
                          child: _buildHero(colorEstado, surfaceEstado),
                        ),
                        if (_accionando)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                              child: LinearProgressIndicator(),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Column(
                              children: [
                                _buildSiguientePasoCard(),
                                const SizedBox(height: 12),
                                _buildBotonesPrincipales(),
                                const SizedBox(height: 12),
                                _buildTrackingBanner(),
                                const SizedBox(height: 12),
                                _buildResumenOperativo(),
                                const SizedBox(height: 12),
                                _buildUbicacionCard(),
                                const SizedBox(height: 12),
                                _buildEvidenciasCard(),
                                const SizedBox(height: 12),
                                _buildParticipantesCard(),
                                const SizedBox(height: 12),
                                _buildTimelineCard(),
                                if (_esCancelado) ...[
                                  const SizedBox(height: 12),
                                  _buildCancelacionCard(),
                                ],
                                const SizedBox(height: 12),
                                _buildAccionesSecundarias(),
                                const SizedBox(height: 34),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        border: Border(
          bottom: BorderSide(
            color: DogGoTheme.border.withOpacity(.8),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: DogGoTheme.ink,
            ),
          ),
          const DogGoLogo(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Detalle del paseo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.body(
                size: 15,
                color: DogGoTheme.ink,
                weight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarDetalle,
            icon: const Icon(
              Icons.refresh_rounded,
              color: DogGoTheme.ink,
            ),
          ),
        ],
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
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: DogGoTheme.border),
            boxShadow: DogGoTheme.softShadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 64,
                color: DogGoTheme.muted,
              ),
              const SizedBox(height: 12),
              Text(
                'No se encontró información del paseo.',
                textAlign: TextAlign.center,
                style: DogGoTheme.title(size: 20),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver'),
                style: DogGoTheme.primaryButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(Color colorEstado, Color surfaceEstado) {
    final foto = _fotoPerro();
    final tieneFoto =
        foto != null && (foto.startsWith('http://') || foto.startsWith('https://'));

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: BoxDecoration(
        color: DogGoTheme.ink,
        borderRadius: BorderRadius.circular(30),
        boxShadow: DogGoTheme.softShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -42,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: surfaceEstado,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(.18),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: tieneFoto
                          ? Image.network(
                              foto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.pets_rounded,
                                color: colorEstado,
                                size: 40,
                              ),
                            )
                          : Icon(
                              Icons.pets_rounded,
                              color: colorEstado,
                              size: 40,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusPill(
                            text: _estado(),
                            color: colorEstado,
                            background: surfaceEstado,
                            icon: _iconoEstado(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nombrePerro(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.title(
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _esPaseador
                                ? 'Dueño: ${_nombreDuenio()}'
                                : 'Paseador: ${_nombrePaseador()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.subtitle(
                              size: 13.5,
                              color: Colors.white.withOpacity(.80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          label: 'Fecha',
                          value: _fechaCorta(_fechaProgramada()),
                        ),
                      ),
                      const _HeroDivider(),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Hora',
                          value: _horaCorta(_fechaProgramada()),
                        ),
                      ),
                      const _HeroDivider(),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Total',
                          value: _precio(_precioPaseo()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _estadoMensaje(),
                  style: DogGoTheme.subtitle(
                    size: 13.5,
                    color: Colors.white.withOpacity(.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiguientePasoCard() {
    String paso = 'Estado del paseo';
    String titulo = 'Consulta el detalle del servicio';
    String descripcion = 'Revisa datos, ubicación, evidencias, chat y seguimiento.';
    IconData icono = Icons.info_outline_rounded;
    Color color = DogGoTheme.teal;
    Color surface = DogGoTheme.tealLight;
    List<Widget> botones = [];

    if (_esPendiente) {
      paso = _esPaseador ? 'Acción pendiente' : 'Solicitud enviada';
      titulo = _esPaseador ? 'Aceptar o rechazar solicitud' : 'Esperando respuesta';
      descripcion = _esPaseador
          ? 'Antes de aceptar, revisa horario, precio, perro y punto de recogida.'
          : 'El paseador todavía no confirma si puede realizar este paseo.';
      icono = Icons.schedule_rounded;
      color = DogGoTheme.orange;
      surface = DogGoTheme.orangeLight;

      if (_esPaseador) {
        botones = [
          _BotonAccion(
            texto: 'Aceptar paseo',
            icono: Icons.check_rounded,
            color: DogGoTheme.green,
            cargando: _accionando,
            onPressed: _aceptarPaseo,
          ),
          const SizedBox(height: 10),
          _BotonAccion(
            texto: 'Rechazar paseo',
            icono: Icons.close_rounded,
            color: DogGoTheme.red,
            cargando: _accionando,
            onPressed: _rechazarPaseo,
            outlined: true,
          ),
        ];
      }
    } else if (_esAceptado) {
      paso = _esPaseador ? 'Listo para iniciar' : 'Confirmado';
      titulo = _esPaseador ? 'Iniciar cuando llegues' : 'Paseo aceptado';
      descripcion = _esPaseador
          ? 'Cuando estés con el perro, inicia el paseo para activar el flujo de evidencia y tracking.'
          : 'El paseador iniciará el servicio al llegar al punto de recogida.';
      icono = Icons.play_circle_rounded;
      color = DogGoTheme.purple;
      surface = DogGoTheme.purpleLight;

      if (_puedeIniciar) {
        botones = [
          _BotonAccion(
            texto: 'Iniciar paseo',
            icono: Icons.play_arrow_rounded,
            color: DogGoTheme.green,
            cargando: _accionando,
            onPressed: _iniciarPaseo,
          ),
        ];
      }
    } else if (_esEnCurso && !_tieneFotoInicio) {
      paso = 'Evidencia inicial';
      titulo = 'Subir foto de inicio';
      descripcion =
          'La foto inicial deja evidencia de que el perro fue recogido correctamente.';
      icono = Icons.add_a_photo_rounded;
      color = DogGoTheme.green;
      surface = DogGoTheme.greenLight;

      if (_esPaseador) {
        botones = [
          _BotonAccion(
            texto: 'Subir foto de inicio',
            icono: Icons.add_a_photo_rounded,
            color: DogGoTheme.green,
            cargando: false,
            onPressed: () => _abrirEvidencia('inicio'),
          ),
        ];
      }
    } else if (_esEnCurso && _tieneFotoInicio && !_tieneFotoFin) {
      paso = 'Tracking y cierre';
      titulo = 'Seguimiento activo';
      descripcion =
          'Mantén la ubicación activa y sube la foto final cuando termine el paseo.';
      icono = Icons.my_location_rounded;
      color = DogGoTheme.green;
      surface = DogGoTheme.greenLight;

      if (_esPaseador) {
        botones = [
          _BotonAccion(
            texto: 'Ubicación en vivo',
            icono: Icons.my_location_rounded,
            color: DogGoTheme.green,
            cargando: false,
            onPressed: _abrirTrackingGps,
          ),
          const SizedBox(height: 10),
          _BotonAccion(
            texto: 'Subir foto de fin',
            icono: Icons.photo_camera_back_rounded,
            color: DogGoTheme.teal,
            cargando: false,
            onPressed: () => _abrirEvidencia('fin'),
          ),
        ];
      }
    } else if (_esEnCurso && _tieneFotoInicio && _tieneFotoFin) {
      paso = 'Listo para finalizar';
      titulo = 'Cerrar el servicio';
      descripcion =
          'Las evidencias ya están completas. Finaliza para guardar el cierre del paseo.';
      icono = Icons.flag_rounded;
      color = DogGoTheme.teal;
      surface = DogGoTheme.tealLight;

      if (_puedeFinalizar) {
        botones = [
          _BotonAccion(
            texto: 'Finalizar paseo',
            icono: Icons.flag_rounded,
            color: DogGoTheme.teal,
            cargando: _accionando,
            onPressed: _finalizarPaseo,
          ),
        ];
      }
    } else if (_esFinalizado) {
      paso = 'Servicio completado';
      titulo = _esDuenio ? 'Calificar experiencia' : 'Paseo finalizado';
      descripcion = _esDuenio
          ? 'Puedes calificar al paseador y dejar un comentario para cerrar el flujo.'
          : 'El servicio quedó finalizado con sus datos y evidencias.';
      icono = Icons.check_circle_rounded;
      color = DogGoTheme.teal;
      surface = DogGoTheme.tealLight;

      if (_puedeCalificar) {
        botones = [
          _BotonAccion(
            texto: 'Calificar paseo',
            icono: Icons.star_rounded,
            color: DogGoTheme.orange,
            cargando: _accionando,
            onPressed: _abrirCalificarPaseo,
          ),
        ];
      }
    } else if (_esCancelado) {
      paso = 'Cancelado';
      titulo = 'Paseo sin actividad';
      descripcion = 'Puedes revisar quién canceló el paseo y el motivo registrado.';
      icono = Icons.cancel_rounded;
      color = DogGoTheme.red;
      surface = DogGoTheme.redLight;
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: icono,
                color: color,
                background: surface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SmallPill(
                      text: paso.toUpperCase(),
                      color: color,
                      background: surface,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      titulo,
                      style: DogGoTheme.title(size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            style: DogGoTheme.subtitle(size: 13.5),
          ),
          if (botones.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...botones,
          ],
        ],
      ),
    );
  }

  Widget _buildBotonesPrincipales() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _paseo == null ? null : _abrirMapaPaseo,
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Mapa'),
              style: DogGoTheme.primaryButton(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _abrirChatPaseo,
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('Chat'),
              style: DogGoTheme.secondaryButton(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingBanner() {
    if (!_esEnCurso) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.greenLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DogGoTheme.green.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DogGoTheme.green,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paseo en curso',
                  style: DogGoTheme.body(
                    size: 15,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _esPaseador
                      ? 'Mantén el tracking activo durante el servicio.'
                      : 'Puedes revisar el seguimiento del paseo en el mapa.',
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _esPaseador ? _abrirTrackingGps : _abrirMapaPaseo,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: DogGoTheme.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenOperativo() {
    return _SectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _MiniMetric(
              icon: Icons.timer_rounded,
              label: 'Duración',
              value: _duracionTexto(),
              color: DogGoTheme.orange,
              background: DogGoTheme.orangeLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniMetric(
              icon: Icons.attach_money_rounded,
              label: 'Precio',
              value: _precio(_precioPaseo()),
              color: DogGoTheme.teal,
              background: DogGoTheme.tealLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionCard() {
    final latitud = _latitudRecogida();
    final longitud = _longitudRecogida();
    final tieneCoordenadas = _coordenadaValida(latitud, longitud);

    return _CardSeccion(
      titulo: 'Ubicación de recogida',
      icono: Icons.location_on_rounded,
      color: DogGoTheme.teal,
      surface: DogGoTheme.tealLight,
      children: [
        if (tieneCoordenadas)
          _PickupMapPreview(
            punto: LatLng(latitud!, longitud!),
            direccion: _direccionRecogida(),
            referencia: _referenciasRecogida(),
            coordenadas: _coordenadasRecogida(),
            onTap: _abrirMapaPaseo,
          )
        else
          _NoMapLocationCard(
            direccion: _direccionRecogida(),
            referencia: _referenciasRecogida(),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _abrirMapaPaseo,
            icon: const Icon(Icons.map_rounded, size: 18),
            label: const Text('Abrir mapa completo'),
            style: DogGoTheme.primaryButton(),
          ),
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
      color: DogGoTheme.orange,
      surface: DogGoTheme.orangeLight,
      children: [
        Row(
          children: [
            Expanded(
              child: _EvidenciaEstado(
                titulo: 'Inicio',
                completo: fotoInicio != null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EvidenciaEstado(
                titulo: 'Fin',
                completo: fotoFin != null,
              ),
            ),
          ],
        ),
        if (_esPaseador && _esEnCurso) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TinyActionButton(
                  text: 'Foto inicio',
                  icon: Icons.add_a_photo_rounded,
                  color: DogGoTheme.green,
                  onTap: () => _abrirEvidencia('inicio'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TinyActionButton(
                  text: 'Foto fin',
                  icon: Icons.photo_camera_back_rounded,
                  color: DogGoTheme.teal,
                  onTap: () => _abrirEvidencia('fin'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (fotoInicio == null && fotoFin == null)
          const _EmptyInline(
            icon: Icons.photo_library_outlined,
            text: 'Todavía no hay fotos registradas para este paseo.',
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
      ],
    );
  }

  Widget _buildParticipantesCard() {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _DarkCardHeader(
            icon: Icons.groups_rounded,
            title: 'Participantes',
            subtitle: 'Mascota, dueño y paseador del servicio.',
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _ParticipantTile(
                  label: 'Mascota',
                  name: _nombrePerro(),
                  description: 'Perro registrado para este paseo',
                  icon: Icons.pets_rounded,
                  color: DogGoTheme.teal,
                  background: DogGoTheme.tealLight,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ParticipantSmallTile(
                        label: 'Dueño',
                        name: _nombreDuenio(),
                        icon: Icons.person_rounded,
                        color: DogGoTheme.purple,
                        background: DogGoTheme.purpleLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ParticipantSmallTile(
                        label: 'Paseador',
                        name: _nombrePaseador(),
                        icon: Icons.directions_walk_rounded,
                        color: DogGoTheme.green,
                        background: DogGoTheme.greenLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _LightCardHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Línea de tiempo',
            subtitle: 'Programación, inicio real y cierre del paseo.',
            color: DogGoTheme.teal,
            background: DogGoTheme.tealLight,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                _PremiumTimelineItem(
                  title: 'Programado',
                  value: _fechaBonita(_fechaProgramada()),
                  chipText: 'Reserva',
                  icon: Icons.event_available_rounded,
                  color: DogGoTheme.purple,
                  background: DogGoTheme.purpleLight,
                  first: true,
                ),
                _PremiumTimelineItem(
                  title: 'Inicio real',
                  value: _fechaBonita(_fechaInicio()),
                  chipText: _fechaInicio() == null ? 'Pendiente' : 'Registrado',
                  icon: Icons.play_circle_rounded,
                  color: DogGoTheme.green,
                  background: DogGoTheme.greenLight,
                ),
                _PremiumTimelineItem(
                  title: 'Fin del paseo',
                  value: _fechaBonita(_fechaFin()),
                  chipText: _fechaFin() == null ? 'Pendiente' : 'Cerrado',
                  icon: Icons.flag_circle_rounded,
                  color: _fechaFin() == null ? DogGoTheme.orange : DogGoTheme.teal,
                  background:
                      _fechaFin() == null ? DogGoTheme.orangeLight : DogGoTheme.tealLight,
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelacionCard() {
    return _CardSeccion(
      titulo: 'Cancelación',
      icono: Icons.cancel_rounded,
      color: DogGoTheme.red,
      surface: DogGoTheme.redLight,
      children: [
        _InfoRow(
          icono: Icons.person_off_rounded,
          titulo: 'Cancelado por',
          valor: _canceladoPor() ?? 'No disponible',
          color: DogGoTheme.red,
          surface: DogGoTheme.redLight,
        ),
        _InfoRow(
          icono: Icons.calendar_today_rounded,
          titulo: 'Fecha de cancelación',
          valor: _fechaBonita(_fechaCancelacion()),
          color: DogGoTheme.orange,
          surface: DogGoTheme.orangeLight,
        ),
        _InfoRow(
          icono: Icons.notes_rounded,
          titulo: 'Motivo',
          valor: _motivoCancelacion() ?? 'Sin motivo registrado',
          color: DogGoTheme.purple,
          surface: DogGoTheme.purpleLight,
          showBottomPadding: false,
        ),
      ],
    );
  }

  Widget _buildAccionesSecundarias() {
    if (!_puedeCancelar) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DogGoTheme.red.withOpacity(.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: Icons.admin_panel_settings_rounded,
                color: DogGoTheme.red,
                background: DogGoTheme.redLight,
                size: 42,
                radius: 14,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión del paseo',
                      style: DogGoTheme.title(size: 18),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Acción disponible mientras el servicio sigue activo.',
                      style: DogGoTheme.subtitle(size: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _BotonAccion(
            texto: 'Cancelar paseo',
            icono: Icons.cancel_rounded,
            color: DogGoTheme.red,
            cargando: _accionando,
            onPressed: _cancelarPaseo,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionCard({
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DogGoTheme.border.withOpacity(.92),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: icono,
                color: color,
                background: surface,
                size: 42,
                radius: 14,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  titulo,
                  style: DogGoTheme.title(size: 18),
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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double radius;

  const _IconBox({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 52,
    this.radius = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * .52,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final IconData icon;

  const _StatusPill({
    required this.text,
    required this.color,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: DogGoTheme.body(
              size: 11.5,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: DogGoTheme.subtitle(
            size: 11,
            color: Colors.white.withOpacity(.62),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.body(
            size: 14,
            color: Colors.white,
            weight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withOpacity(.12),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background.withOpacity(.80),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DogGoTheme.subtitle(size: 11.2),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.body(
                    size: 13.5,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w900,
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

class _EvidenciaEstado extends StatelessWidget {
  final String titulo;
  final bool completo;

  const _EvidenciaEstado({
    required this.titulo,
    required this.completo,
  });

  @override
  Widget build(BuildContext context) {
    final color = completo ? DogGoTheme.green : DogGoTheme.orange;
    final surface = completo ? DogGoTheme.greenLight : DogGoTheme.orangeLight;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            completo ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$titulo: ${completo ? 'lista' : 'pendiente'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.body(
                size: 11.5,
                color: color,
                weight: FontWeight.w900,
              ),
            ),
          ),
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
  final bool showBottomPadding;

  const _InfoRow({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
    required this.surface,
    this.showBottomPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: showBottomPadding ? 13 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
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
                  style: DogGoTheme.subtitle(size: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
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
          color: DogGoTheme.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DogGoTheme.border),
        ),
        child: Text(
          '$titulo: imagen registrada, pero falta URL pública.',
          style: DogGoTheme.subtitle(size: 12.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: DogGoTheme.body(
            size: 13,
            color: DogGoTheme.ink,
            weight: FontWeight.w900,
          ),
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
                color: DogGoTheme.cream,
                alignment: Alignment.center,
                child: Text(
                  'No se pudo cargar la imagen',
                  style: DogGoTheme.subtitle(size: 12.5),
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
        height: 48,
        child: OutlinedButton.icon(
          onPressed: cargando ? null : onPressed,
          icon: cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icono, size: 18),
          label: Text(texto),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(
              color: color,
              width: 1.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
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
            : Icon(icono, size: 18),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TinyActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
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
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DogGoTheme.body(
          size: 10,
          color: color,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyInline({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DogGoTheme.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: DogGoTheme.muted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: DogGoTheme.subtitle(size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupMapPreview extends StatelessWidget {
  final LatLng punto;
  final String direccion;
  final String referencia;
  final String coordenadas;
  final VoidCallback onTap;

  const _PickupMapPreview({
    required this.punto,
    required this.direccion,
    required this.referencia,
    required this.coordenadas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DogGoTheme.border.withOpacity(.9),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: punto,
                        initialZoom: 16,
                        minZoom: 4,
                        maxZoom: 19,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.doggo_flutter',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: punto,
                              width: 86,
                              height: 86,
                              child: const _PickupMarker(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _MapFloatingPill(
                      text: 'Punto de recogida',
                      icon: Icons.home_rounded,
                      color: DogGoTheme.teal,
                      background: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: DogGoTheme.teal,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: DogGoTheme.teal.withOpacity(.28),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ver mapa',
                              style: DogGoTheme.body(
                                size: 11.5,
                                color: Colors.white,
                                weight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            color: DogGoTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  direccion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.body(
                    size: 15,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      color: DogGoTheme.muted,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        referencia,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(size: 12.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pin_drop_rounded,
                        color: DogGoTheme.teal,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          coordenadas,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DogGoTheme.body(
                            size: 11.5,
                            color: DogGoTheme.teal,
                            weight: FontWeight.w900,
                          ),
                        ),
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
}

class _NoMapLocationCard extends StatelessWidget {
  final String direccion;
  final String referencia;

  const _NoMapLocationCard({
    required this.direccion,
    required this.referencia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DogGoTheme.orange.withOpacity(.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DogGoTheme.orange.withOpacity(.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: DogGoTheme.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin coordenadas registradas',
                  style: DogGoTheme.body(
                    size: 14,
                    color: DogGoTheme.orange,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  direccion,
                  style: DogGoTheme.body(
                    size: 13.5,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  referencia,
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFloatingPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color background;

  const _MapFloatingPill({
    required this.text,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background.withOpacity(.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: DogGoTheme.body(
              size: 11.5,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupMarker extends StatelessWidget {
  const _PickupMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DogGoTheme.teal,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.24),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            'Recogida',
            style: DogGoTheme.body(
              size: 9.5,
              color: DogGoTheme.teal,
              weight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DarkCardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: DogGoTheme.ink,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
                  style: DogGoTheme.title(
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: DogGoTheme.subtitle(
                    size: 12.5,
                    color: Colors.white.withOpacity(.70),
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

class _LightCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;

  const _LightCardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: color.withOpacity(.10),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
                  style: DogGoTheme.title(size: 18),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String label;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;

  const _ParticipantTile({
    required this.label,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: DogGoTheme.body(
                    size: 10.5,
                    color: color,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.title(size: 19),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantSmallTile extends StatelessWidget {
  final String label;
  final String name;
  final IconData icon;
  final Color color;
  final Color background;

  const _ParticipantSmallTile({
    required this.label,
    required this.name,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 132,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background.withOpacity(.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: DogGoTheme.body(
              size: 10,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 14,
              color: DogGoTheme.ink,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTimelineItem extends StatelessWidget {
  final String title;
  final String value;
  final String chipText;
  final IconData icon;
  final Color color;
  final Color background;
  final bool first;
  final bool last;

  const _PremiumTimelineItem({
    required this.title,
    required this.value,
    required this.chipText,
    required this.icon,
    required this.color,
    required this.background,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: first ? Colors.transparent : DogGoTheme.border,
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(.14),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: last ? Colors.transparent : DogGoTheme.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: last ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DogGoTheme.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DogGoTheme.border.withOpacity(.75),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: DogGoTheme.body(
                            size: 14,
                            color: DogGoTheme.ink,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          chipText,
                          style: DogGoTheme.body(
                            size: 10.5,
                            color: color,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: DogGoTheme.subtitle(size: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}