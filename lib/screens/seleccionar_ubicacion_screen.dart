import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class G {
  static const brand = Color(0xFF0D9E7E);
  static const brandPale = Color(0xFFE8F8F3);
  static const brandDark = Color(0xFF0A7A62);
  static const clay = Color(0xFFD4694A);
  static const ink0 = Color(0xFFFAF7F2);
  static const ink2 = Color(0xFFE8E2D9);
  static const ink3 = Color(0xFFC8C0B4);
  static const ink4 = Color(0xFF8C8278);
  static const ink5 = Color(0xFF4A4540);
  static const ink6 = Color(0xFF1E1A16);
  static const white = Color(0xFFFFFFFF);

  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r24 = BorderRadius.all(Radius.circular(24));
  static const r99 = BorderRadius.all(Radius.circular(999));

  static const shadow1 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static TextStyle h3(Color c) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: c,
        letterSpacing: -.2,
      );

  static TextStyle body(Color c, {double size = 13.5}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w400, color: c);

  static TextStyle label(Color c, {double size = 12}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: c,
        letterSpacing: .3,
      );
}

class SeleccionarUbicacionScreen extends StatefulWidget {
  final LatLng? ubicacionInicial;
  final String? textoInicial;

  const SeleccionarUbicacionScreen({
    super.key,
    this.ubicacionInicial,
    this.textoInicial,
  });

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  LatLng? _ubicacionSeleccionada;

  late final TextEditingController _descripcionController;

  final TextEditingController _buscarController = TextEditingController();
  final MapController _mapController = MapController();

  bool _buscandoGPS = false;
  bool _buscandoTexto = false;

  @override
  void initState() {
    super.initState();

    _ubicacionSeleccionada = widget.ubicacionInicial;

    _descripcionController = TextEditingController(
      text: widget.textoInicial ?? '',
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _buscarController.dispose();
    super.dispose();
  }

  LatLng get _centroInicial =>
      widget.ubicacionInicial ?? const LatLng(25.6866, -100.3161);

  Future<void> _obtenerMiUbicacion() async {
    setState(() => _buscandoGPS = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('El GPS está desactivado. Enciéndelo.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Los permisos de ubicación están denegados permanentemente.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final miUbi = LatLng(position.latitude, position.longitude);

      _mapController.move(miUbi, 17.0);

      setState(() {
        _ubicacionSeleccionada = miUbi;
      });
    } catch (e) {
      if (!mounted) return;

      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _buscandoGPS = false);
    }
  }

  Future<void> _buscarDireccion(String query) async {
    final q = query.trim();

    if (q.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() => _buscandoTexto = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'DogGoApp_Flutter'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final ubi = LatLng(lat, lon);

          _mapController.move(ubi, 16.0);

          setState(() {
            _ubicacionSeleccionada = ubi;

            if (_descripcionController.text.trim().isEmpty) {
              _descripcionController.text =
                  data[0]['display_name'] ?? data[0]['name'] ?? q;
            }
          });
        } else {
          _snack('No se encontró la dirección 📍');
        }
      } else {
        _snack('No se pudo buscar la dirección.');
      }
    } catch (_) {
      _snack('Error al buscar.');
    } finally {
      if (mounted) setState(() => _buscandoTexto = false);
    }
  }

  void _snack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: G.body(G.white)),
        backgroundColor: G.ink5,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: G.r12),
      ),
    );
  }

  void _confirmar() {
    final ubicacion = _ubicacionSeleccionada;
    final descripcion = _descripcionController.text.trim();

    if (ubicacion == null) {
      _snack('Toca el mapa para fijar un punto.');
      return;
    }

    Navigator.pop(context, {
      'latitud': ubicacion.latitude,
      'longitud': ubicacion.longitude,
      'texto': descripcion.isEmpty ? 'Ubicación seleccionada' : descripcion,
      'ubicacionTexto': descripcion.isEmpty
          ? 'Ubicación seleccionada'
          : descripcion,
      'direccionRecogida': descripcion.isEmpty
          ? 'Ubicación seleccionada'
          : descripcion,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: G.ink0,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroInicial,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
              onTap: (tapPosition, point) {
                setState(() {
                  _ubicacionSeleccionada = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.doggo_flutter',
              ),
              if (_ubicacionSeleccionada != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionSeleccionada!,
                      width: 60,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: const _MarcadorAnimado(),
                    ),
                  ],
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: G.white,
                      shape: BoxShape.circle,
                      boxShadow: G.shadow1,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: G.ink6,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: G.white,
                        borderRadius: G.r99,
                        boxShadow: G.shadow1,
                      ),
                      child: TextField(
                        controller: _buscarController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _buscarDireccion,
                        style: G.body(G.ink6),
                        decoration: InputDecoration(
                          hintText: 'Buscar dirección o lugar...',
                          hintStyle: G.body(G.ink4),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: G.ink3,
                          ),
                          suffixIcon: _buscandoTexto
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: G.brand,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: G.ink3,
                                  ),
                                  onPressed: () => _buscarController.clear(),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
              decoration: const BoxDecoration(
                color: G.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: G.ink2,
                      borderRadius: G.r99,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: G.brandPale,
                          borderRadius: G.r12,
                        ),
                        child: const Icon(
                          Icons.pin_drop_rounded,
                          color: G.brand,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Punto fijado',
                              style: G.h3(G.ink6).copyWith(fontSize: 15),
                            ),
                            Text(
                              _ubicacionSeleccionada == null
                                  ? 'Toca el mapa o busca'
                                  : '${_ubicacionSeleccionada!.latitude.toStringAsFixed(5)}, ${_ubicacionSeleccionada!.longitude.toStringAsFixed(5)}',
                              style: G.body(G.ink4, size: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descripcionController,
                    style: G.body(G.ink6),
                    decoration: InputDecoration(
                      labelText: 'Referencia de la casa (Opcional)',
                      labelStyle: G.body(G.ink4),
                      prefixIcon: const Icon(Icons.home_rounded, color: G.ink3),
                      filled: true,
                      fillColor: G.ink0,
                      border: const OutlineInputBorder(
                        borderRadius: G.r16,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: G.r16,
                        borderSide: BorderSide(
                          color: G.brand,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: G.brand,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: G.r16,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirmar Ubicación',
                        style: G.label(G.white).copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 280,
            child: GestureDetector(
              onTap: _buscandoGPS ? null : _obtenerMiUbicacion,
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: G.white,
                  shape: BoxShape.circle,
                  boxShadow: G.shadow1,
                ),
                child: _buscandoGPS
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: G.brand,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: G.brandDark,
                        size: 26,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarcadorAnimado extends StatefulWidget {
  const _MarcadorAnimado();

  @override
  State<_MarcadorAnimado> createState() => _MarcadorAnimadoState();
}

class _MarcadorAnimadoState extends State<_MarcadorAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          -20 * (1 - Curves.easeOutBack.transform(_ctrl.value)),
        ),
        child: child,
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: G.clay,
        size: 50,
      ),
    );
  }
}
