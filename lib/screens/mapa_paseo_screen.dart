import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/session_service.dart';
import '../services/tracking_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
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
  List<Map<String, dynamic>> _historialUbicaciones = [];

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
    if (_debeConsultarTracking) await _cargarRuta();
  }

  Future<void> _cargarRol() async {
    try {
      final rol = await SessionService.obtenerRol();
      if (!mounted) return;
      setState(() => _rolReal = rol);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rolReal = null);
    }
  }

  Future<void> _cargarRuta() async {
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
        _historialUbicaciones = [];
      });
      return;
    }

    setState(() {
      _cargandoUbicacion = true;
      _errorUbicacion = null;
    });

    try {
      final historial = await _trackingService.obtenerHistorialUbicaciones(id);
      Map<String, dynamic>? ultima;
      if (historial.isNotEmpty) {
        ultima = historial.last;
      } else {
        ultima = await _trackingService.obtenerUltimaUbicacion(id);
      }
      if (!mounted) return;
      setState(() {
        _historialUbicaciones = historial;
        _ultimaUbicacion = ultima;
        _cargandoUbicacion = false;
      });
    } catch (_) {
      try {
        final ultima = await _trackingService.obtenerUltimaUbicacion(id);
        if (!mounted) return;
        setState(() {
          _ultimaUbicacion = ultima;
          _historialUbicaciones = [];
          _errorUbicacion = null;
          _cargandoUbicacion = false;
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _errorUbicacion = e2.toString().replaceFirst('Exception: ', '');
          _cargandoUbicacion = false;
        });
      }
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
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
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

  String _estado() => _texto(widget.paseo['estado'] ?? widget.paseo['Estado'], fallback: 'Pendiente');
  String _estadoNormalizado() => _estado().replaceAll(' ', '').toLowerCase();

  bool get _esPendiente => _estadoNormalizado() == 'pendiente';
  bool get _esAceptado => _estadoNormalizado() == 'aceptado';
  bool get _esEnCurso => _estadoNormalizado() == 'encurso';
  bool get _esFinalizado => _estadoNormalizado() == 'finalizado';
  bool get _esCancelado => _estadoNormalizado() == 'cancelado';
  bool get _debeConsultarTracking => _esEnCurso || _esFinalizado;
  bool get _esPaseador => SessionService.esPaseadorRol(_rolReal);
  bool get _puedeAbrirTracking => _esPaseador && _esEnCurso;

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
    final completo = '${_texto(nombre, fallback: '')} ${_texto(apellido, fallback: '')}'.trim();
    return completo.isEmpty ? 'Paseador no asignado' : completo;
  }

  double? _latitudActual() => _doubleSeguro(
        _ultimaUbicacion?['latitud'] ??
            _ultimaUbicacion?['Latitud'] ??
            _ultimaUbicacion?['latitudActual'] ??
            _ultimaUbicacion?['LatitudActual'] ??
            widget.paseo['latitudActual'] ??
            widget.paseo['LatitudActual'],
      );

  double? _longitudActual() => _doubleSeguro(
        _ultimaUbicacion?['longitud'] ??
            _ultimaUbicacion?['Longitud'] ??
            _ultimaUbicacion?['longitudActual'] ??
            _ultimaUbicacion?['LongitudActual'] ??
            widget.paseo['longitudActual'] ??
            widget.paseo['LongitudActual'],
      );

  double? _latitudRecogida() => _doubleSeguro(
        widget.paseo['latitudRecogida'] ??
            widget.paseo['latRecogida'] ??
            widget.paseo['ubicacionLatitud'] ??
            widget.paseo['latitud'] ??
            widget.paseo['LatitudRecogida'] ??
            widget.paseo['Latitud'],
      );

  double? _longitudRecogida() => _doubleSeguro(
        widget.paseo['longitudRecogida'] ??
            widget.paseo['lngRecogida'] ??
            widget.paseo['lonRecogida'] ??
            widget.paseo['ubicacionLongitud'] ??
            widget.paseo['longitud'] ??
            widget.paseo['LongitudRecogida'] ??
            widget.paseo['Longitud'],
      );

  String _direccionRecogida() => _texto(
        widget.paseo['ubicacionTexto'] ??
            widget.paseo['ubicacionRecogidaTexto'] ??
            widget.paseo['direccionRecogida'] ??
            widget.paseo['direccion'] ??
            widget.paseo['DireccionRecogida'] ??
            widget.paseo['Direccion'],
        fallback: 'Ubicación de recogida no definida',
      );

  String _fechaBonita(dynamic valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? '');
    if (fecha == null) return 'No disponible';
    final local = fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  dynamic _fechaUbicacion() => _ultimaUbicacion?['fecha'] ??
      _ultimaUbicacion?['Fecha'] ??
      _ultimaUbicacion?['timestamp'] ??
      _ultimaUbicacion?['Timestamp'] ??
      _ultimaUbicacion?['fechaRegistro'] ??
      _ultimaUbicacion?['FechaRegistro'];

  Color _colorEstado() {
    switch (_estadoNormalizado()) {
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
    switch (_estadoNormalizado()) {
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
    if (!_coordenadaValida(lat, lng)) return null;
    return LatLng(lat!, lng!);
  }

  LatLng? _puntoRecogida() {
    final lat = _latitudRecogida();
    final lng = _longitudRecogida();
    if (!_coordenadaValida(lat, lng)) return null;
    return LatLng(lat!, lng!);
  }

  List<LatLng> _puntosRutaGps() {
    final puntos = <LatLng>[];
    for (final item in _historialUbicaciones) {
      final lat = _doubleSeguro(item['latitud'] ?? item['Latitud'] ?? item['latitudActual']);
      final lng = _doubleSeguro(item['longitud'] ?? item['Longitud'] ?? item['longitudActual']);
      if (_coordenadaValida(lat, lng)) puntos.add(LatLng(lat!, lng!));
    }
    if (puntos.isEmpty) {
      final actual = _puntoActual();
      if (actual != null) puntos.add(actual);
    }
    return puntos;
  }

  LatLng _centroMapa() {
    final actual = _puntoActual();
    final recogida = _puntoRecogida();
    final ruta = _puntosRutaGps();
    if (ruta.isNotEmpty) return ruta.last;
    if (actual != null && recogida != null) {
      return LatLng((actual.latitude + recogida.latitude) / 2, (actual.longitude + recogida.longitude) / 2);
    }
    if (actual != null) return actual;
    if (recogida != null) return recogida;
    return const LatLng(25.6866, -100.3161);
  }

  String _mensajeEstado() {
    if (_esPendiente) return 'El mapa estará disponible cuando el paseo sea aceptado e iniciado.';
    if (_esAceptado) return 'El GPS se activará cuando el paseador inicie el servicio.';
    if (_esCancelado) return 'Este paseo fue cancelado. El seguimiento no está activo.';
    if (_esFinalizado) return _puntosRutaGps().isEmpty ? 'Paseo finalizado sin ruta registrada.' : 'Paseo finalizado. Se muestra la ruta registrada.';
    if (_esEnCurso) return _puntosRutaGps().isEmpty ? 'Activa la ubicación en vivo para mostrar la ruta.' : 'Mostrando avance del paseo en tiempo real.';
    return 'Seguimiento no disponible.';
  }

  String _resumenRuta() {
    final puntos = _puntosRutaGps().length;
    if (puntos == 0) return 'Sin puntos de ruta';
    if (puntos == 1) return '1 punto registrado';
    return '$puntos puntos registrados';
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
    if (actualizado == true) await _cargarRuta();
  }

  Future<void> _refrescar() async {
    if (_debeConsultarTracking) {
      await _cargarRuta();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_mensajeEstado())));
  }

  @override
  Widget build(BuildContext context) {
    final puntoActual = _puntoActual();
    final puntoRecogida = _puntoRecogida();
    final rutaGps = _puntosRutaGps();

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refrescar,
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  children: [
                    _buildHero(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                      child: Column(
                        children: [
                          _buildMapaCard(puntoActual: puntoActual, puntoRecogida: puntoRecogida, rutaGps: rutaGps),
                          const SizedBox(height: 14),
                          _buildAccionesRapidas(),
                          const SizedBox(height: 14),
                          _buildEstadoCard(),
                          const SizedBox(height: 14),
                          _buildPuntosCard(puntoActual: puntoActual, puntoRecogida: puntoRecogida, rutaGps: rutaGps),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        border: Border(bottom: BorderSide(color: DogGoTheme.border.withOpacity(.75))),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: DogGoTheme.ink)),
          const DogGoLogo(size: 38),
          const SizedBox(width: 8),
          Expanded(child: Text('Mapa del paseo', style: DogGoTheme.title(size: 18))),
          IconButton(onPressed: _refrescar, icon: const Icon(Icons.refresh_rounded, color: DogGoTheme.ink)),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [DogGoTheme.teal, DogGoTheme.green], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: DogGoTheme.teal.withOpacity(.24), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Stack(
          children: [
            Positioned(right: -32, top: -36, child: Container(width: 130, height: 130, decoration: BoxDecoration(color: Colors.white.withOpacity(.10), shape: BoxShape.circle))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Pill(text: _estado(), icono: _iconoEstado(), color: _colorEstado(), background: Colors.white),
              const SizedBox(height: 12),
              Text(_nombrePerro(), style: DogGoTheme.title(size: 30, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Paseador: ${_nombrePaseador()}', maxLines: 2, overflow: TextOverflow.ellipsis, style: DogGoTheme.body(size: 13.5, color: Colors.white.withOpacity(.88), weight: FontWeight.w700)),
              const SizedBox(height: 14),
              Text(_mensajeEstado(), style: DogGoTheme.body(size: 13.2, color: Colors.white.withOpacity(.94), weight: FontWeight.w800).copyWith(height: 1.3)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMapaCard({required LatLng? puntoActual, required LatLng? puntoRecogida, required List<LatLng> rutaGps}) {
    final markers = <Marker>[];
    if (puntoRecogida != null) {
      markers.add(Marker(point: puntoRecogida, width: 82, height: 82, child: const _MapaMarker(icono: Icons.home_rounded, color: DogGoTheme.purple, label: 'Recogida')));
    }
    for (int i = 0; i < rutaGps.length; i++) {
      final punto = rutaGps[i];
      if (i == rutaGps.length - 1) continue;
      markers.add(Marker(point: punto, width: 20, height: 20, child: Container(decoration: BoxDecoration(color: DogGoTheme.teal.withOpacity(.85), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))));
    }
    if (puntoActual != null) {
      markers.add(Marker(point: puntoActual, width: 86, height: 86, child: _MapaMarker(icono: Icons.my_location_rounded, color: _colorEstado(), label: 'Paseador')));
    }

    return Container(
      height: 490,
      decoration: BoxDecoration(color: DogGoTheme.card, borderRadius: BorderRadius.circular(30), border: Border.all(color: DogGoTheme.border), boxShadow: DogGoTheme.softShadow()),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        FlutterMap(
          options: MapOptions(initialCenter: _centroMapa(), initialZoom: rutaGps.length >= 2 ? 16 : 15, minZoom: 3, maxZoom: 19),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.doggo_flutter'),
            if (rutaGps.length >= 2)
              PolylineLayer(polylines: [
                Polyline(points: rutaGps, strokeWidth: 8, color: Colors.white.withOpacity(.90)),
                Polyline(points: rutaGps, strokeWidth: 5, color: DogGoTheme.teal),
              ]),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(left: 12, top: 12, child: _FloatingMapLabel(text: rutaGps.isNotEmpty ? _resumenRuta() : 'Sin ruta GPS', color: rutaGps.isNotEmpty ? DogGoTheme.green : DogGoTheme.orange, icono: rutaGps.isNotEmpty ? Icons.route_rounded : Icons.info_outline_rounded)),
        if (_cargandoUbicacion)
          Positioned(right: 12, top: 12, child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withOpacity(.95), borderRadius: BorderRadius.circular(14)), child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
        if (markers.isEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(.82),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: DogGoTheme.card, borderRadius: BorderRadius.circular(24), boxShadow: DogGoTheme.softShadow()),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_esEnCurso ? Icons.my_location_rounded : Icons.map_outlined, color: _esEnCurso ? DogGoTheme.green : DogGoTheme.muted, size: 48),
                    const SizedBox(height: 10),
                    Text(_esEnCurso ? 'Aún no hay ruta registrada' : 'Mapa sin coordenadas', textAlign: TextAlign.center, style: DogGoTheme.title(size: 18)),
                    const SizedBox(height: 6),
                    Text(_esEnCurso ? 'Activa la ubicación en vivo para empezar a registrar la ruta.' : 'Cuando haya punto de recogida o GPS, aparecerá aquí.', textAlign: TextAlign.center, style: DogGoTheme.subtitle(size: 12.8)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildAccionesRapidas() {
    return Row(children: [
      if (_puedeAbrirTracking) ...[
        Expanded(child: _ActionButton(label: 'Ubicación en vivo', icono: Icons.my_location_rounded, color: DogGoTheme.green, filled: true, onTap: _abrirTracking)),
        const SizedBox(width: 10),
      ],
      Expanded(child: _ActionButton(label: 'Actualizar', icono: Icons.refresh_rounded, color: DogGoTheme.teal, filled: !_puedeAbrirTracking, onTap: _refrescar)),
    ]);
  }

  Widget _buildEstadoCard() {
    return _InfoCard(
      title: 'Estado del seguimiento',
      icon: _iconoEstado(),
      color: _colorEstado(),
      surface: _surfaceEstado(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_cargandoUbicacion ? 'Actualizando la ruta del paseo...' : _mensajeEstado(), style: DogGoTheme.subtitle(size: 13.2)),
        if (_errorUbicacion != null && _puntoActual() == null) ...[
          const SizedBox(height: 8),
          Text('Todavía no hay ubicación registrada para mostrar.', style: DogGoTheme.body(size: 12.5, color: DogGoTheme.orange, weight: FontWeight.w800)),
        ],
      ]),
    );
  }

  Widget _buildPuntosCard({required LatLng? puntoActual, required LatLng? puntoRecogida, required List<LatLng> rutaGps}) {
    return _InfoCard(
      title: 'Datos de ruta',
      icon: Icons.route_rounded,
      color: DogGoTheme.teal,
      surface: DogGoTheme.tealLight,
      child: Column(children: [
        _InfoItem(icono: Icons.route_rounded, titulo: 'Puntos registrados', valor: _resumenRuta(), color: DogGoTheme.teal, surface: DogGoTheme.tealLight),
        _InfoItem(icono: Icons.home_rounded, titulo: 'Punto de recogida', valor: _direccionRecogida(), color: DogGoTheme.purple, surface: DogGoTheme.purpleLight),
        _InfoItem(icono: Icons.pin_drop_rounded, titulo: 'Coordenadas de recogida', valor: puntoRecogida != null ? '${puntoRecogida.latitude.toStringAsFixed(6)}, ${puntoRecogida.longitude.toStringAsFixed(6)}' : 'No disponibles', color: DogGoTheme.orange, surface: DogGoTheme.orangeLight),
        _InfoItem(icono: Icons.my_location_rounded, titulo: 'Última ubicación del paseador', valor: puntoActual != null ? '${puntoActual.latitude.toStringAsFixed(6)}, ${puntoActual.longitude.toStringAsFixed(6)}' : _debeConsultarTracking ? 'Todavía no hay ubicación enviada' : 'El GPS todavía no está activo', color: DogGoTheme.green, surface: DogGoTheme.greenLight),
        _InfoItem(icono: Icons.access_time_rounded, titulo: 'Última actualización', valor: puntoActual != null ? _fechaBonita(_fechaUbicacion()) : 'No disponible', color: DogGoTheme.orange, surface: DogGoTheme.orangeLight, ultimo: true),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color surface;
  final Widget child;

  const _InfoCard({required this.title, required this.icon, required this.color, required this.surface, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: DogGoTheme.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: DogGoTheme.border), boxShadow: DogGoTheme.softShadow()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: DogGoTheme.title(size: 20))),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _MapaMarker extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String label;

  const _MapaMarker({required this.icono, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.22), blurRadius: 9, offset: const Offset(0, 4))]), child: Icon(icono, color: Colors.white, size: 24)),
      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 6, offset: const Offset(0, 2))]), child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900))),
    ]);
  }
}

class _FloatingMapLabel extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icono;

  const _FloatingMapLabel({required this.text, required this.color, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.96), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, color: color, size: 16), const SizedBox(width: 6), Text(text, style: DogGoTheme.body(size: 11.5, color: color, weight: FontWeight.w900))]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icono, required this.color, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(height: 52, child: ElevatedButton.icon(onPressed: onTap, icon: Icon(icono, size: 19), label: Text(label), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))));
    }
    return SizedBox(height: 52, child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icono, size: 19), label: Text(label), style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color, width: 1.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))));
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final Color surface;
  final bool ultimo;

  const _InfoItem({required this.icono, required this.titulo, required this.valor, required this.color, required this.surface, this.ultimo = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 39, height: 39, decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)), child: Icon(icono, color: color, size: 21)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: DogGoTheme.subtitle(size: 12)), const SizedBox(height: 2), Text(valor, style: DogGoTheme.body(size: 13.5, color: DogGoTheme.ink, weight: FontWeight.w800).copyWith(height: 1.3))])),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icono;
  final Color color;
  final Color background;

  const _Pill({required this.text, required this.icono, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, color: color, size: 15), const SizedBox(width: 5), Text(text, style: DogGoTheme.body(size: 11.5, color: color, weight: FontWeight.w900))]),
    );
  }
}
