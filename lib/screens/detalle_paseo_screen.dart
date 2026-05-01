import 'package:flutter/material.dart';

import '../services/paseos_service.dart';
import '../services/session_service.dart';
import 'mapa_paseo_screen.dart';
import 'calificar_paseo_screen.dart';
import 'chat_paseo_screen.dart';
import 'evidencia_paseo_screen.dart';
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

  @override
  void initState() {
    super.initState();

    if (widget.paseo != null) {
      _paseo = Map<String, dynamic>.from(widget.paseo!);
    }

    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarRol();
    await _cargarDetalle();
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
        widget.paseo?['Id'];

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
        return Colors.orange;
      case 'aceptado':
        return Colors.blue;
      case 'encurso':
        return Colors.green;
      case 'finalizado':
        return Colors.purple;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
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

    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return null;

    return double.tryParse(texto);
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
          title: const Text('Cancelar paseo'),
          content: TextField(
            controller: motivoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo de cancelación',
              hintText: 'Ej. Cambio de horario, lluvia, emergencia...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancelar paseo'),
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
    final texto = foto?.toString().trim();

    if (texto == null || texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  String? _fotoFin() {
    final foto = _paseo?['fotoFinUrl'] ?? _paseo?['FotoFinUrl'];
    final texto = foto?.toString().trim();

    if (texto == null || texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorEstado();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Detalle del paseo'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(colorEstado),
                      const SizedBox(height: 12),
                      _buildRolCard(),
                      const SizedBox(height: 16),
                      _buildInfoPrincipal(),
                      const SizedBox(height: 16),
                      _buildBotonesPrincipales(),
                      const SizedBox(height: 16),
                      _buildUbicacionCard(),
                      const SizedBox(height: 16),
                      _buildFechasCard(),
                      if (_esCancelado) ...[
                        const SizedBox(height: 16),
                        _buildCancelacionCard(),
                      ],
                      const SizedBox(height: 16),
                      _buildEvidenciasCard(),
                      const SizedBox(height: 16),
                      _buildAcciones(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSinDatos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 60,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se encontró información del paseo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color colorEstado) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF1F8A70).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Color(0xFF1F8A70),
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombrePerro(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paseador: ${_nombrePaseador()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _estado(),
              style: TextStyle(
                color: colorEstado,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolCard() {
    final rolTexto = SessionService.normalizarRol(_rolUsuario);
    final color = _esPaseador
        ? Colors.green
        : _esDuenio
            ? Colors.blue
            : Colors.orange;

    final descripcion = _esPaseador
        ? 'Puedes gestionar este paseo, subir evidencias, usar chat y activar GPS.'
        : _esDuenio
            ? 'Puedes consultar el paseo, ver mapa, usar chat y calificar al finalizar.'
            : 'No se detectó un rol claro. Algunas acciones estarán ocultas.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.badge_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$rolTexto: $descripcion',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
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
      children: [
        _InfoRow(
          icono: Icons.pets_rounded,
          titulo: 'Perro',
          valor: _nombrePerro(),
        ),
        _InfoRow(
          icono: Icons.person_rounded,
          titulo: 'Dueño',
          valor: _nombreDuenio(),
        ),
        _InfoRow(
          icono: Icons.directions_walk_rounded,
          titulo: 'Paseador',
          valor: _nombrePaseador(),
        ),
        _InfoRow(
          icono: Icons.timer_rounded,
          titulo: 'Duración',
          valor:
              _duracion() == null ? 'No disponible' : '${_duracion()} minutos',
        ),
        _InfoRow(
          icono: Icons.attach_money_rounded,
          titulo: 'Precio',
          valor: _precio(_precioPaseo()),
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
                    backgroundColor: const Color(0xFF1F8A70),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
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
                    foregroundColor: Colors.blue,
                    side: const BorderSide(
                      color: Colors.blue,
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F8A70).withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF1F8A70).withOpacity(0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F8A70).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF1F8A70),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Punto de recogida',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F8A70),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _direccionRecogida(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (tieneCoordenadas) ...[
                      const SizedBox(height: 6),
                      Text(
                        _coordenadasRecogida(),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
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
                foregroundColor: const Color(0xFF1F8A70),
                side: const BorderSide(
                  color: Color(0xFF1F8A70),
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
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'Este paseo todavía no tiene coordenadas de recogida registradas.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
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
        ),
      ],
    );
  }

  Widget _buildFechasCard() {
    return _CardSeccion(
      titulo: 'Fechas',
      icono: Icons.calendar_month_rounded,
      children: [
        _InfoRow(
          icono: Icons.event_rounded,
          titulo: 'Fecha programada',
          valor: _fechaBonita(_fechaProgramada()),
        ),
        _InfoRow(
          icono: Icons.play_circle_rounded,
          titulo: 'Inicio',
          valor: _fechaBonita(_fechaInicio()),
        ),
        _InfoRow(
          icono: Icons.flag_circle_rounded,
          titulo: 'Fin',
          valor: _fechaBonita(_fechaFin()),
        ),
      ],
    );
  }

  Widget _buildCancelacionCard() {
    return _CardSeccion(
      titulo: 'Cancelación',
      icono: Icons.cancel_rounded,
      children: [
        _InfoRow(
          icono: Icons.person_off_rounded,
          titulo: 'Cancelado por',
          valor: _canceladoPor() ?? 'No disponible',
        ),
        _InfoRow(
          icono: Icons.calendar_today_rounded,
          titulo: 'Fecha de cancelación',
          valor: _fechaBonita(_fechaCancelacion()),
        ),
        _InfoRow(
          icono: Icons.notes_rounded,
          titulo: 'Motivo',
          valor: _motivoCancelacion() ?? 'Sin motivo registrado',
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
      children: [
        if (fotoInicio == null && fotoFin == null)
          Text(
            'Todavía no hay fotos de inicio o fin del paseo.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
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
              color: Colors.green,
              cargando: false,
              onPressed: () => _abrirEvidencia('inicio'),
            ),
          if (_puedeSubirFotoInicio && _puedeSubirFotoFin)
            const SizedBox(height: 10),
          if (_puedeSubirFotoFin)
            _BotonAccion(
              texto: 'Subir foto de fin',
              icono: Icons.photo_camera_back_rounded,
              color: Colors.purple,
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
        color: Colors.blue,
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
          color: Colors.green,
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
          color: Colors.green,
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
          color: Colors.red,
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
          color: Colors.green,
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
          color: Colors.purple,
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
          color: Colors.red,
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
          color: Colors.amber.shade700,
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
      children: acciones,
    );
  }
}

class _CardSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _CardSeccion({
    required this.titulo,
    required this.icono,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F8A70).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icono,
                  color: const Color(0xFF1F8A70),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
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

  const _InfoRow({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
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
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$titulo: imagen registrada, pero falta URL absoluta.',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 130,
                width: double.infinity,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Text(
                  'No se pudo cargar la imagen',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
