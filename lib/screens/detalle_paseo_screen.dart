import 'package:flutter/material.dart';

import '../services/paseos_service.dart';
import 'mapa_paseo_screen.dart';

class DetallePaseoScreen extends StatefulWidget {
  final int? id;
  final int? paseoId;
  final Map<String, dynamic>? paseo;
  final VoidCallback? onPaseoActualizado;

  const DetallePaseoScreen({
    super.key,
    this.id,
    this.paseoId,
    this.paseo,
    this.onPaseoActualizado,
  });

  @override
  State<DetallePaseoScreen> createState() => _DetallePaseoScreenState();
}

class _DetallePaseoScreenState extends State<DetallePaseoScreen> {
  final PaseosService _paseosService = PaseosService();

  Map<String, dynamic>? _paseo;
  bool _cargando = true;
  bool _accionando = false;

  @override
  void initState() {
    super.initState();

    if (widget.paseo != null) {
      _paseo = Map<String, dynamic>.from(widget.paseo!);
    }

    _cargarDetalle();
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
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
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

  Map<String, dynamic> _normalizarDetalle(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      datos = respuesta['data'] ??
          respuesta['paseo'] ??
          respuesta['detalle'] ??
          respuesta['resultado'] ??
          respuesta['result'] ??
          respuesta['value'] ??
          respuesta;
    }

    if (datos is Map) {
      return Map<String, dynamic>.from(datos);
    }

    throw Exception('La respuesta del detalle del paseo no tiene formato válido.');
  }

  Future<Map<String, dynamic>> _obtenerDetalleCompatible(int id) async {
    final dynamic service = _paseosService;
    dynamic respuesta;

    try {
      respuesta = await service.obtenerDetallePaseo(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.obtenerDetalle(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.detallePaseo(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.detalle(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.getDetallePaseo(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.getPaseoById(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.obtenerPaseoPorId(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.obtenerPaseo(id);
      return _normalizarDetalle(respuesta);
    } on NoSuchMethodError catch (_) {}

    throw Exception(
      'No encontré método compatible para obtener detalle del paseo.',
    );
  }

  Future<void> _aceptarCompatible(int id) async {
    final dynamic service = _paseosService;

    try {
      await service.aceptarPaseo(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.aceptar(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.aceptarSolicitud(id);
      return;
    } on NoSuchMethodError catch (_) {}

    throw Exception('No encontré método compatible para aceptar paseo.');
  }

  Future<void> _rechazarCompatible(int id) async {
    final dynamic service = _paseosService;

    try {
      await service.rechazarPaseo(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.rechazar(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.rechazarSolicitud(id);
      return;
    } on NoSuchMethodError catch (_) {}

    throw Exception('No encontré método compatible para rechazar paseo.');
  }

  Future<void> _iniciarCompatible(int id) async {
    final dynamic service = _paseosService;

    try {
      await service.iniciarPaseo(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.iniciar(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.iniciarTracking(id);
      return;
    } on NoSuchMethodError catch (_) {}

    throw Exception('No encontré método compatible para iniciar paseo.');
  }

  Future<void> _finalizarCompatible(int id) async {
    final dynamic service = _paseosService;

    try {
      await service.finalizarPaseo(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.finalizar(id);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.terminarPaseo(id);
      return;
    } on NoSuchMethodError catch (_) {}

    throw Exception('No encontré método compatible para finalizar paseo.');
  }

  Future<void> _cancelarCompatible(int id, String motivo) async {
    final dynamic service = _paseosService;

    try {
      await service.cancelarPaseo(id, motivo);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.cancelar(id, motivo);
      return;
    } on NoSuchMethodError catch (_) {}

    try {
      await service.cancelarPaseoConMotivo(id, motivo);
      return;
    } on NoSuchMethodError catch (_) {}

    throw Exception('No encontré método compatible para cancelar paseo.');
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
    if (id == null) return;

    await _ejecutarAccion(
      accion: () => _aceptarCompatible(id),
      mensajeExito: 'Paseo aceptado correctamente.',
    );
  }

  Future<void> _rechazarPaseo() async {
    final id = _idPaseo;
    if (id == null) return;

    await _ejecutarAccion(
      accion: () => _rechazarCompatible(id),
      mensajeExito: 'Paseo rechazado correctamente.',
    );
  }

  Future<void> _iniciarPaseo() async {
    final id = _idPaseo;
    if (id == null) return;

    await _ejecutarAccion(
      accion: () => _iniciarCompatible(id),
      mensajeExito: 'Paseo iniciado correctamente.',
    );
  }

  Future<void> _finalizarPaseo() async {
    final id = _idPaseo;
    if (id == null) return;

    await _ejecutarAccion(
      accion: () => _finalizarCompatible(id),
      mensajeExito: 'Paseo finalizado correctamente.',
    );
  }

  Future<void> _cancelarPaseo() async {
    final id = _idPaseo;
    if (id == null) return;

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
          _paseo?['UbicacionTexto'] ??
          _paseo?['DireccionRecogida'],
      fallback: 'Ubicación de recogida no definida',
    );
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
                      const SizedBox(height: 16),
                      _buildInfoPrincipal(),
                      const SizedBox(height: 16),
                      _buildMapaButton(),
                      const SizedBox(height: 16),
                      _buildUbicacionCard(),
                      const SizedBox(height: 16),
                      _buildFechasCard(),
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
          valor: _duracion() == null ? 'No disponible' : '${_duracion()} minutos',
        ),
        _InfoRow(
          icono: Icons.attach_money_rounded,
          titulo: 'Precio',
          valor: _precio(_precioPaseo()),
        ),
      ],
    );
  }

  Widget _buildMapaButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _paseo == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapaPaseoScreen(
                      paseo: _paseo!,
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.map_rounded),
        label: const Text(
          'Ver mapa del paseo',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
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
    );
  }

  Widget _buildUbicacionCard() {
    return _CardSeccion(
      titulo: 'Ubicación',
      icono: Icons.location_on_rounded,
      children: [
        _InfoRow(
          icono: Icons.home_rounded,
          titulo: 'Punto de recogida',
          valor: _direccionRecogida(),
        ),
        _InfoRow(
          icono: Icons.my_location_rounded,
          titulo: 'Tracking',
          valor: _esEnCurso
              ? 'El paseo está en curso. Puedes revisar el mapa.'
              : _esFinalizado
                  ? 'El paseo ya finalizó. Puedes revisar la última ubicación.'
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
      ],
    );
  }

  Widget _buildAcciones() {
    final acciones = <Widget>[];

    if (_esPendiente) {
      acciones.addAll([
        _BotonAccion(
          texto: 'Aceptar paseo',
          icono: Icons.check_rounded,
          color: Colors.green,
          cargando: _accionando,
          onPressed: _aceptarPaseo,
        ),
        const SizedBox(height: 10),
        _BotonAccion(
          texto: 'Rechazar paseo',
          icono: Icons.close_rounded,
          color: Colors.red,
          cargando: _accionando,
          onPressed: _rechazarPaseo,
        ),
      ]);
    }

    if (_esAceptado) {
      acciones.add(
        _BotonAccion(
          texto: 'Iniciar paseo',
          icono: Icons.play_arrow_rounded,
          color: Colors.green,
          cargando: _accionando,
          onPressed: _iniciarPaseo,
        ),
      );
    }

    if (_esEnCurso) {
      acciones.add(
        _BotonAccion(
          texto: 'Finalizar paseo',
          icono: Icons.flag_rounded,
          color: Colors.purple,
          cargando: _accionando,
          onPressed: _finalizarPaseo,
        ),
      );
    }

    if (!_esFinalizado && !_esCancelado) {
      if (acciones.isNotEmpty) acciones.add(const SizedBox(height: 10));

      acciones.add(
        _BotonAccion(
          texto: 'Cancelar paseo',
          icono: Icons.cancel_rounded,
          color: Colors.red,
          cargando: _accionando,
          onPressed: _cancelarPaseo,
          outlined: true,
        ),
      );
    }

    if (acciones.isEmpty) {
      acciones.add(
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _esFinalizado
                ? 'Este paseo ya fue finalizado.'
                : 'Este paseo fue cancelado.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
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
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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