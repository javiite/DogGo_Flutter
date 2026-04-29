import 'package:flutter/material.dart';
import '../services/paseadores_service.dart';

class PaseadoresScreen extends StatefulWidget {
  const PaseadoresScreen({super.key});

  @override
  State<PaseadoresScreen> createState() => _PaseadoresScreenState();
}

class _PaseadoresScreenState extends State<PaseadoresScreen> {
  bool _cargando = true;
  String? _error;
  List<dynamic> _paseadores = [];

  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarPaseadores();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPaseadores() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PaseadoresService.obtenerPaseadores();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _paseadores = result['data'] as List<dynamic>;
          _cargando = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  String _tarifaTexto(dynamic tarifa) {
    if (tarifa == null) return 'Tarifa no disponible';
    return '\$${tarifa.toString()} / hora';
  }

  String _calificacionTexto(dynamic calificacion) {
    if (calificacion == null) return 'Sin calificación';
    return '⭐ ${calificacion.toString()}';
  }

  String _experienciaTexto(dynamic experiencia) {
    if (experiencia == null) return 'Sin experiencia';
    return '$experiencia año(s) exp.';
  }

  List<dynamic> get _paseadoresFiltrados {
    final texto = _busquedaController.text.trim().toLowerCase();

    if (texto.isEmpty) return _paseadores;

    return _paseadores.where((item) {
      final paseador = item as Map<String, dynamic>;
      final nombre = _textoSeguro(paseador['nombre']).toLowerCase();
      final descripcion = _textoSeguro(
        paseador['descripcion'],
        '',
      ).toLowerCase();
      final zona = _textoSeguro(
        paseador['zonaServicio'] ?? paseador['zona'],
        '',
      ).toLowerCase();

      return nombre.contains(texto) ||
          descripcion.contains(texto) ||
          zona.contains(texto);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _paseadoresFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: const [
            Icon(Icons.pets, color: Color(0xFF14A89A)),
            SizedBox(width: 8),
            Text(
              'DogGo',
              style: TextStyle(
                color: Color(0xFF25324A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Volver',
              style: TextStyle(color: Color(0xFF25324A)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 72,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarPaseadores,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4EDE3),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE7E0D5)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🦴 ENCUENTRA TU PASEADOR',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF14A89A),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Paseadores disponibles',
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.1,
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Se encontraron ${lista.length} paseadores.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _busquedaController,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre, zona o descripción',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: lista.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_search,
                                      size: 76,
                                      color: Color(0xFFB8B3AA),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'No se encontraron paseadores',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF25324A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Prueba con otra búsqueda o vuelve a cargar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _cargarPaseadores,
                                      child: const Text('Recargar'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarPaseadores,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(18),
                                itemCount: lista.length,
                                itemBuilder: (context, index) {
                                  final paseador =
                                      lista[index] as Map<String, dynamic>;

                                  final nombre = _textoSeguro(
                                    paseador['nombre'],
                                  );
                                  final tarifa = _tarifaTexto(
                                    paseador['tarifaPorHora'] ??
                                        paseador['tarifa'],
                                  );
                                  final descripcion = _textoSeguro(
                                    paseador['descripcion'],
                                    'Sin descripción',
                                  );
                                  final zona = _textoSeguro(
                                    paseador['zonaServicio'] ??
                                        paseador['zona'],
                                    'Sin zona',
                                  );
                                  final experiencia = _experienciaTexto(
                                    paseador['experienciaAnios'] ??
                                        paseador['experiencia'],
                                  );
                                  final rating = _calificacionTexto(
                                    paseador['calificacionPromedio'] ??
                                        paseador['rating'],
                                  );
                                  final disponible =
                                      paseador['disponible'] == true;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _PaseadorCard(
                                      nombre: nombre,
                                      precio: tarifa,
                                      descripcion: descripcion,
                                      zonas: [zona],
                                      experiencia: experiencia,
                                      disponible: disponible,
                                      rating: rating,
                                      onVerPerfil: () {
                                        _mostrarMensaje(
                                          'Detalle de $nombre después',
                                        );
                                      },
                                      onSolicitar: () {
                                        _mostrarMensaje(
                                          'Solicitar paseo a $nombre después',
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _PaseadorCard extends StatelessWidget {
  final String nombre;
  final String precio;
  final String descripcion;
  final List<String> zonas;
  final String experiencia;
  final bool disponible;
  final String rating;
  final VoidCallback onVerPerfil;
  final VoidCallback onSolicitar;

  const _PaseadorCard({
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.zonas,
    required this.experiencia,
    required this.disponible,
    required this.rating,
    required this.onVerPerfil,
    required this.onSolicitar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E2D9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDE3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF6B7280),
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF25324A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        precio,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...zonas.map(
                  (z) => _TagChip(
                    texto: z,
                    colorFondo: const Color(0xFFDDF4F1),
                    colorTexto: const Color(0xFF14A89A),
                  ),
                ),
                _TagChip(
                  texto: experiencia,
                  colorFondo: const Color(0xFFF6ECD8),
                  colorTexto: const Color(0xFFB57A4B),
                ),
                _TagChip(
                  texto: disponible ? 'Disponible' : 'No disponible',
                  colorFondo: disponible
                      ? const Color(0xFFE6F6E9)
                      : const Color(0xFFFBE4E6),
                  colorTexto: disponible
                      ? const Color(0xFF4AA564)
                      : const Color(0xFFE56B6F),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onVerPerfil,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF14A89A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: Color(0xFF14A89A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSolicitar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14A89A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Solicitar paseo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String texto;
  final Color colorFondo;
  final Color colorTexto;

  const _TagChip({
    required this.texto,
    required this.colorFondo,
    required this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: colorTexto,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}