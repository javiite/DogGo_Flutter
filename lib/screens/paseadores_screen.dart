import 'package:flutter/material.dart';

class PaseadoresScreen extends StatelessWidget {
  const PaseadoresScreen({super.key});

  void _mostrarMensaje(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paseadores = [
      {
        'nombre': 'Javier Terrones',
        'precio': '\$70.00 / hora',
        'descripcion': 'Buena persona, amistosa y le gustan los animales.',
        'zonas': ['Centro', 'Cumbres'],
        'experiencia': '4 años(s) exp.',
        'disponible': true,
        'rating': '5.0',
      },
      {
        'nombre': 'Javier 5 5',
        'precio': '\$60.00 / hora',
        'descripcion': 'Paseador con disponibilidad entre semana.',
        'zonas': ['Centro', 'Cumbres'],
        'experiencia': '6 años(s) exp.',
        'disponible': true,
        'rating': '4.8',
      },
      {
        'nombre': 'pru3ba paseador',
        'precio': '\$60.00 / hora',
        'descripcion': 'fwferuo´+p',
        'zonas': ['Centro', 'Cumbres'],
        'experiencia': '6 años(s) exp.',
        'disponible': true,
        'rating': '4.6',
      },
    ];

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
      body: Column(
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
              children: const [
                Text(
                  '🦴 ENCUENTRA TU PASEADOR',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Paseadores disponibles',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Elige al paseador ideal para tu mascota.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE7E2D9)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Nombre o descripción',
                          filled: true,
                          fillColor: const Color(0xFFF8F4EC),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _FiltroFake(
                              texto: 'Todas las zonas',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FiltroFake(
                              texto: 'Mejor calificación',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  _mostrarMensaje(context, 'Filtrar después');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF14A89A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Buscar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () {
                                  _mostrarMensaje(context, 'Limpiar después');
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF14A89A),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    color: Color(0xFF14A89A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...paseadores.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PaseadorCard(
                      nombre: p['nombre'] as String,
                      precio: p['precio'] as String,
                      descripcion: p['descripcion'] as String,
                      zonas: p['zonas'] as List<String>,
                      experiencia: p['experiencia'] as String,
                      disponible: p['disponible'] as bool,
                      rating: p['rating'] as String,
                      onVerPerfil: () {
                        _mostrarMensaje(
                          context,
                          'Ver perfil de ${p['nombre']} después',
                        );
                      },
                      onSolicitar: () {
                        _mostrarMensaje(
                          context,
                          'Solicitar paseo a ${p['nombre']} después',
                        );
                      },
                    ),
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

class _FiltroFake extends StatelessWidget {
  final String texto;

  const _FiltroFake({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '★★★★★',
                      style: TextStyle(
                        color: Color(0xFFE3A72F),
                        fontSize: 12,
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
                  colorFondo: const Color(0xFFE6F6E9),
                  colorTexto: const Color(0xFF4AA564),
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