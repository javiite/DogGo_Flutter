import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    super.dispose();
  }

  LatLng get _centroInicial {
    return widget.ubicacionInicial ?? const LatLng(25.6866, -100.3161);
  }

  void _confirmar() {
    final ubicacion = _ubicacionSeleccionada;
    final descripcion = _descripcionController.text.trim();

    if (ubicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un punto en el mapa.'),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'latitud': ubicacion.latitude,
      'longitud': ubicacion.longitude,
      'texto': descripcion.isEmpty ? 'Ubicación seleccionada' : descripcion,
    });
  }

  String _coordText() {
    final ubicacion = _ubicacionSeleccionada;

    if (ubicacion == null) {
      return 'Toca el mapa para seleccionar una ubicación.';
    }

    return '${ubicacion.latitude.toStringAsFixed(6)}, ${ubicacion.longitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final marcador = _ubicacionSeleccionada;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.doggo_flutter',
                  ),
                  if (marcador != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: marcador,
                          width: 64,
                          height: 64,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF1F8A70),
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pin_drop_rounded,
                        color: Color(0xFF1F8A70),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _coordText(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción o referencia',
                      hintText: 'Ej. Frente a la casa, portón negro...',
                      prefixIcon: const Icon(Icons.home_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: const BorderSide(
                          color: Color(0xFF1F8A70),
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _confirmar,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Usar esta ubicación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F8A70),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}