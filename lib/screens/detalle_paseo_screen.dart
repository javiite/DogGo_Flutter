import 'package:flutter/material.dart';

class DetallePaseoScreen extends StatelessWidget {
  final Map<String, dynamic> paseo;

  const DetallePaseoScreen({
    super.key,
    required this.paseo,
  });

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFE3A72F);
      case 'encurso':
      case 'en curso':
        return const Color(0xFF14A89A);
      case 'finalizado':
        return const Color(0xFF7ACB8A);
      case 'cancelado':
        return const Color(0xFFE56B6F);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = _textoSeguro(paseo['estado'], 'Pendiente');
    final colorEstado = _colorEstado(estado);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Detalle del paseo'),
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
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      '🐶',
                      style: TextStyle(fontSize: 42),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Paseo #${_textoSeguro(paseo['id'], '---')}',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailBox(
            titulo: 'Perro',
            valor: _textoSeguro(
              paseo['perroNombre'] ??
                  (paseo['perro'] is Map<String, dynamic>
                      ? paseo['perro']['nombre']
                      : null),
              'Perro sin nombre',
            ),
          ),
          const SizedBox(height: 12),
          _DetailBox(
            titulo: 'Paseador',
            valor: _textoSeguro(
              paseo['paseadorNombre'] ??
                  (paseo['paseador'] is Map<String, dynamic>
                      ? paseo['paseador']['nombre']
                      : null),
              'Sin paseador',
            ),
          ),
          const SizedBox(height: 12),
          _DetailBox(
            titulo: 'Fecha programada',
            valor: _textoSeguro(
              paseo['fechaProgramada'] ?? paseo['fechaInicio'],
              'Sin fecha',
            ),
          ),
          const SizedBox(height: 12),
          _DetailBox(
            titulo: 'Duración',
            valor: '${_textoSeguro(paseo['duracionMinutos'], '0')} minutos',
          ),
          const SizedBox(height: 12),
          _DetailBox(
            titulo: 'Precio',
            valor: '\$${_textoSeguro(paseo['precio'], '0')}',
          ),
          const SizedBox(height: 18),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEEEE),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text(
                '🗺️ Mapa aquí después',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF25324A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14A89A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ver en mapa',
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

class _DetailBox extends StatelessWidget {
  final String titulo;
  final String valor;

  const _DetailBox({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF25324A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}