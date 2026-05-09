import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/session_service.dart';
import '../services/tracking_service.dart';
import 'tracking_paseo_screen.dart';

class MapaPaseoScreen extends StatefulWidget {
  final Map<String, dynamic> paseo;

  const MapaPaseoScreen({
    super.key,
    required this.paseo,
  });

  @override
  State<MapaPaseoScreen> createState() => _MapaPaseoScreenState();
}

class _MapaPaseoScreenState extends State<MapaPaseoScreen> {
  final TrackingService _trackingService = TrackingService();

  Map<String, dynamic>? _ultimaUbicacion;
  bool _cargandoUbicacion = false;
  String? _errorUbicacion;
  String? _rolReal;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarRol();

    if (_debeConsultarTracking) {
      await _cargarUltimaUbicacion();
    }
  }

  Future<void> _cargarRol() async {
    try {
      final rol = await SessionService.obtenerRol();

      if (!mounted) return;

      setState(() {
        _rolReal = rol;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _rolReal = null;
      });
    }
  }

  Future<void> _cargarUltimaUbicacion() async {
    final id = _idPaseo();

    if (id == null) {
      if (!mounted) return;

      setState(() {
        _cargandoUbicacion = false;
        _errorUbicacion = 'No se encontró el ID del paseo.';
      });
      return;
    }

    if (!_debeConsultarTracking) {
      if (!mounted) return;

      setState(() {
        _cargandoUbicacion = false;
        _errorUbicacion = null;
      });
      return;
    }

    setState(() {
      _cargandoUbicacion = true;
      _errorUbicacion = null;
    });

    try {
      final ubicacion = await _trackingService.obtenerUltimaUbicacion(id);

      if (!mounted) return;

      setState(() {
        _ultimaUbicacion = ubicacion;
        _cargandoUbicacion = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorUbicacion = e.toString();
        _cargandoUbicacion = false;
      });
    }
  }

  int? _idPaseo() {
    final valor = widget.paseo['id'] ??
        widget.paseo['Id'] ??
        widget.paseo['paseoId'] ??
        widget.paseo['PaseoId'];

    if (valor is int) return valor;
    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '');
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

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return double.tryParse(texto);
  }

  String _estado() {
    return _texto(
      widget.paseo['estado'] ?? widget.paseo['Estado'],
      fallback: 'Pendiente',
    );
  }

  String _estadoNormalizado() {
    return _estado().replaceAll(' ', '').toLowerCase();
  }

  bool get _esPendiente {
    return _estadoNormalizado() == 'pendiente';
  }

  bool get _esAceptado {
    return _estadoNormalizado() == 'aceptado';
  }

  bool get _esEnCurso {
    return _estadoNormalizado() == 'encurso';
  }

  bool get _esFinalizado {
    return _estadoNormalizado() == 'finalizado';
  }

  bool get _esCancelado {
    return _estadoNormalizado() == 'cancelado';
  }

  bool get _debeConsultarTracking {
    return _esEnCurso || _esFinalizado;
  }

  bool get _esPaseador {
    return SessionService.esPaseadorRol(_rolReal);
  }

  bool get _puedeAbrirTracking {
    return _esPaseador && _esEnCurso;
  }

  String _nombrePerro() {
    return _texto(
      widget.paseo['perroNombre'] ??
          widget.paseo['nombrePerro'] ??
          widget.paseo['perro']?['nombre'] ??
          widget.paseo['Perro']?['Nombre'],
      fallback: 'Perro',
    );
  }

  String _nombrePaseador() {
    final nombre = widget.paseo['paseadorNombre'] ??
        widget.paseo['nombrePaseador'] ??
        widget.paseo['paseador']?['nombre'] ??
        widget.paseo['paseador']?['usuario']?['nombre'] ??
        widget.paseo['Paseador']?['Usuario']?['Nombre'];

    final apellido = widget.paseo['paseadorApellido'] ??
        widget.paseo['apellidoPaseador'] ??
        widget.paseo['paseador']?['usuario']?['apellido'] ??
        widget.paseo['Paseador']?['Usuario']?['Apellido'];

    final n = _texto(nombre, fallback: '');
    final a = _texto(apellido, fallback: '');

    final completo = '$n $a'.trim();

    return completo.isEmpty ? 'Paseador no asignado' : completo;
  }

  double? _latitudActual() {
    return _doubleSeguro(
      _ultimaUbicacion?['latitud'] ??
          _ultimaUbicacion?['Latitud'] ??
          _ultimaUbicacion?['latitudActual'] ??
          _ultimaUbicacion?['LatitudActual'] ??
          widget.paseo['latitudActual'] ??
          widget.paseo['LatitudActual'],
    );
  }

  double? _longitudActual() {
    return _doubleSeguro(
      _ultimaUbicacion?['longitud'] ??
          _ultimaUbicacion?['Longitud'] ??
          _ultimaUbicacion?['longitudActual'] ??
          _ultimaUbicacion?['LongitudActual'] ??
          widget.paseo['longitudActual'] ??
          widget.paseo['LongitudActual'],
    );
  }

  double? _latitudRecogida() {
    return _doubleSeguro(
      widget.paseo['latitudRecogida'] ??
          widget.paseo['latRecogida'] ??
          widget.paseo['ubicacionLatitud'] ??
          widget.paseo['latitud'] ??
          widget.paseo['LatitudRecogida'] ??
          widget.paseo['LatRecogida'] ??
          widget.paseo['UbicacionLatitud'] ??
          widget.paseo['Latitud'],
    );
  }

  double? _longitudRecogida() {
    return _doubleSeguro(
      widget.paseo['longitudRecogida'] ??
          widget.paseo['lngRecogida'] ??
          widget.paseo['lonRecogida'] ??
          widget.paseo['ubicacionLongitud'] ??
          widget.paseo['longitud'] ??
          widget.paseo['LongitudRecogida'] ??
          widget.paseo['LngRecogida'] ??
          widget.paseo['LonRecogida'] ??
          widget.paseo['UbicacionLongitud'] ??
          widget.paseo['Longitud'],
    );
  }

  String _direccionRecogida() {
    return _texto(
      widget.paseo['ubicacionTexto'] ??
          widget.paseo['ubicacionRecogidaTexto'] ??
          widget.paseo['direccionRecogida'] ??
          widget.paseo['direccion'] ??
          widget.paseo['UbicacionTexto'] ??
          widget.paseo['UbicacionRecogidaTexto'] ??
          widget.paseo['DireccionRecogida'] ??
          widget.paseo['Direccion'],
      fallback: 'Ubicación de recogida no definida',
    );
  }

  String _fechaBonita(dynamic valor) {
    if (valor == null) return 'No disponible';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return valor.toString();

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  dynamic _fechaUbicacion() {
    return _ultimaUbicacion?['fecha'] ??
        _ultimaUbicacion?['Fecha'] ??
        _ultimaUbicacion?['timestamp'] ??
        _ultimaUbicacion?['Timestamp'] ??
        _ultimaUbicacion?['fechaRegistro'] ??
        _ultimaUbicacion?['FechaRegistro'];
  }

  Future<void> _abrirTracking() async {
    final id = _idPaseo();

    if (id == null) return;

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
      await _cargarUltimaUbicacion();
    }
  }

  Color _colorEstado() {
    switch (_estadoNormalizado()) {
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

  IconData _iconoEstado() {
    switch (_estadoNormalizado()) {
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

  LatLng? _puntoActual() {
    final lat = _latitudActual();
    final lng = _longitudActual();

    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  LatLng? _puntoRecogida() {
    final lat = _latitudRecogida();
    final lng = _longitudRecogida();

    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  LatLng _centroMapa() {
    final actual = _puntoActual();
    final recogida = _puntoRecogida();

    if (actual != null && recogida != null) {
      return LatLng(
        (actual.latitude + recogida.latitude) / 2,
        (actual.longitude + recogida.longitude) / 2,
      );
    }

    if (actual != null) return actual;
    if (recogida != null) return recogida;

    return const LatLng(25.6866, -100.3161);
  }

  Future<void> _refrescar() async {
    if (_debeConsultarTracking) {
      await _cargarUltimaUbicacion();
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_mensajeTracking()),
      ),
    );
  }

  String _mensajeTracking() {
    if (_esPendiente) {
      return 'El GPS se activará cuando el paseo sea aceptado e iniciado.';
    }

    if (_esAceptado) {
      return 'El GPS todavía no inicia. El paseador debe iniciar el paseo.';
    }

    if (_esCancelado) {
      return 'Este paseo fue cancelado. El tracking no está activo.';
    }

    if (_esFinalizado) {
      return 'El paseo ya finalizó. Se muestra la última ubicación disponible.';
    }

    if (_esEnCurso) {
      return 'El paseo está en curso. El tracking GPS está disponible.';
    }

    return 'Tracking no disponible para este estado.';
  }

  @override
  Widget build(BuildContext context) {
    final puntoActual = _puntoActual();
    final puntoRecogida = _puntoRecogida();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Mapa del paseo'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildAvisoEstado(),
            const SizedBox(height: 16),
            _buildMapaReal(
              puntoActual: puntoActual,
              puntoRecogida: puntoRecogida,
            ),
            const SizedBox(height: 16),
            _buildLeyenda(),
            const SizedBox(height: 16),
            _buildUbicacionInfo(
              puntoActual: puntoActual,
              puntoRecogida: puntoRecogida,
            ),
            const SizedBox(height: 16),
            if (_puedeAbrirTracking) _buildBotonTracking(),
            if (_puedeAbrirTracking) const SizedBox(height: 16),
            _buildEstadoTracking(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final color = _colorEstado();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F8A70),
            Color(0xFF35A98A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.map_rounded,
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
                  _nombrePerro(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paseador: ${_nombrePaseador()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconoEstado(),
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _estado(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 4,
                            ),
                          ],
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

  Widget _buildAvisoEstado() {
    final color = _colorEstado();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconoEstado(),
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _mensajeTracking(),
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaReal({
    required LatLng? puntoActual,
    required LatLng? puntoRecogida,
  }) {
    final markers = <Marker>[];

    if (puntoRecogida != null) {
      markers.add(
        Marker(
          point: puntoRecogida,
          width: 70,
          height: 70,
          child: const _MarkerIcon(
            icono: Icons.home_rounded,
            color: Colors.blue,
            texto: 'Recogida',
          ),
        ),
      );
    }

    if (puntoActual != null) {
      markers.add(
        Marker(
          point: puntoActual,
          width: 70,
          height: 70,
          child: _MarkerIcon(
            icono: Icons.pets_rounded,
            color: _colorEstado(),
            texto: 'GPS',
          ),
        ),
      );
    }

    final puntosRuta = <LatLng>[];

    if (puntoRecogida != null) puntosRuta.add(puntoRecogida);
    if (puntoActual != null) puntosRuta.add(puntoActual);

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _centroMapa(),
              initialZoom: puntosRuta.length >= 2 ? 14 : 16,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.doggo_flutter',
              ),
              if (puntosRuta.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: puntosRuta,
                      strokeWidth: 5,
                      color: const Color(0xFF1F8A70),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),
          if (markers.isEmpty)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.03),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      _esPendiente || _esAceptado
                          ? 'Todavía no hay coordenadas GPS del paseo. Se mostrarán cuando el paseo esté en curso.'
                          : 'Todavía no hay coordenadas para mostrar en el mapa.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeyenda() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          _LeyendaItem(
            color: Colors.blue,
            texto: 'Recogida',
            icono: Icons.home_rounded,
          ),
          SizedBox(width: 14),
          _LeyendaItem(
            color: Color(0xFF1F8A70),
            texto: 'GPS del paseo',
            icono: Icons.pets_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionInfo({
    required LatLng? puntoActual,
    required LatLng? puntoRecogida,
  }) {
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
        children: [
          _InfoMapaRow(
            icono: Icons.home_rounded,
            titulo: 'Punto de recogida',
            valor: _direccionRecogida(),
          ),
          _InfoMapaRow(
            icono: Icons.pin_drop_rounded,
            titulo: 'Coordenadas de recogida',
            valor: puntoRecogida != null
                ? '${puntoRecogida.latitude.toStringAsFixed(6)}, ${puntoRecogida.longitude.toStringAsFixed(6)}'
                : 'No disponibles',
          ),
          _InfoMapaRow(
            icono: Icons.my_location_rounded,
            titulo: 'Última ubicación GPS',
            valor: puntoActual != null
                ? '${puntoActual.latitude.toStringAsFixed(6)}, ${puntoActual.longitude.toStringAsFixed(6)}'
                : _debeConsultarTracking
                    ? 'Todavía no hay ubicación GPS registrada'
                    : 'El GPS todavía no está activo',
          ),
          _InfoMapaRow(
            icono: Icons.access_time_rounded,
            titulo: 'Última actualización',
            valor: _debeConsultarTracking
                ? _fechaBonita(_fechaUbicacion())
                : 'No aplica todavía',
          ),
        ],
      ),
    );
  }

  Widget _buildBotonTracking() {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _abrirTracking,
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
    );
  }

  Widget _buildEstadoTracking() {
    if (!_debeConsultarTracking) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.orange,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _mensajeTracking(),
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_cargandoUbicacion) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando última ubicación GPS...',
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

    if (_errorUbicacion != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.orange,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No se pudo cargar ubicación GPS. Puede que todavía no exista tracking registrado.',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mapa actualizado con la información disponible del paseo.',
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
}

class _MarkerIcon extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;

  const _MarkerIcon({
    required this.icono,
    required this.color,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icono,
            color: Colors.white,
            size: 23,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String texto;
  final IconData icono;

  const _LeyendaItem({
    required this.color,
    required this.texto,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icono,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMapaRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _InfoMapaRow({
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
            color: Colors.grey.shade700,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
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