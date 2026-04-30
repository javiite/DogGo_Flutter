import 'package:flutter/material.dart';
import 'crear_paseo_screen.dart';

class DetallePaseadorScreen extends StatelessWidget {
  final Map<String, dynamic> paseador;

  const DetallePaseadorScreen({
    super.key,
    required this.paseador,
  });

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
    return '$experiencia año(s) de experiencia';
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _textoSeguro(paseador['nombre']);
    final descripcion = _textoSeguro(
      paseador['descripcion'],
      'Sin descripción',
    );
    final tarifa = _tarifaTexto(
      paseador['tarifaPorHora'] ?? paseador['tarifa'],
    );
    final rating = _calificacionTexto(
      paseador['calificacionPromedio'] ?? paseador['rating'],
    );
    final experiencia = _experienciaTexto(
      paseador['experienciaAnios'] ?? paseador['experiencia'],
    );
    final zona = _textoSeguro(
      paseador['zonaServicio'] ?? paseador['zona'],
      'Sin zona',
    );
    final disponible = paseador['disponible'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Detalle del paseador'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7E2D9)),
            ),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDE3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 46,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rating,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _InfoChip(
                      texto: tarifa,
                      fondo: const Color(0xFFDDF4F1),
                      color: const Color(0xFF14A89A),
                    ),
                    _InfoChip(
                      texto: experiencia,
                      fondo: const Color(0xFFF6ECD8),
                      color: const Color(0xFFB57A4B),
                    ),
                    _InfoChip(
                      texto: disponible ? 'Disponible' : 'No disponible',
                      fondo: disponible
                          ? const Color(0xFFE6F6E9)
                          : const Color(0xFFFBE4E6),
                      color: disponible
                          ? const Color(0xFF4AA564)
                          : const Color(0xFFE56B6F),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            titulo: 'Descripción',
            child: Text(
              descripcion,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            titulo: 'Zona de servicio',
            child: Text(
              zona,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF25324A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: disponible
                  ? () async {
                      final creado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CrearPaseoScreen(
                            paseador: paseador,
                          ),
                        ),
                      );

                      if (!context.mounted) return;

                      if (creado == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Paseo creado correctamente'),
                          ),
                        );
                      }
                    }
                  : null,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _DetailCard({
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF25324A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;

  const _InfoChip({
    required this.texto,
    required this.fondo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}