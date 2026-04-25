import 'package:flutter/material.dart';

class MisPaseosScreen extends StatelessWidget {
  const MisPaseosScreen({super.key});

  void _mostrarMensaje(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return const Color(0xFFE3A72F);
      case 'EnCurso':
        return const Color(0xFF14A89A);
      case 'Finalizado':
        return const Color(0xFF7ACB8A);
      case 'Cancelado':
        return const Color(0xFFE56B6F);
      default:
        return Colors.grey;
    }
  }

  Widget _buildEstadoChip(String estado) {
    final color = _colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPaseoCard(
    BuildContext context, {
    required String titulo,
    required String perro,
    required String paseador,
    required String fecha,
    required String estado,
    String? extra,
  }) {
    final color = _colorEstado(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  '🐶',
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF25324A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    perro,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paseador: $paseador',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fecha,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (extra != null && extra.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        extra,
                        style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildEstadoChip(estado),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _mostrarMensaje(context, 'Detalle del paseo después');
                        },
                        child: const Text('Ver detalle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paseosPendientes = [
      {
        'titulo': 'Paseo #26',
        'perro': 'wdqqwdqwd',
        'paseador': 'Javier Terrones',
        'fecha': 'Hoy · 30 min',
        'estado': 'Pendiente',
        'extra': '📍 Recolección pendiente',
      }
    ];

    final paseosFinalizados = [
      {
        'titulo': 'Paseo #3',
        'perro': 'CHOCOROL',
        'paseador': 'Javier 5 5',
        'fecha': '04/04/2026 21:04',
        'estado': 'Finalizado',
        'extra': '⭐ Calificación disponible',
      }
    ];

    final paseosCancelados = [
      {
        'titulo': 'Paseo #4',
        'perro': 'CHOCOROL',
        'paseador': 'Javier Terrones',
        'fecha': '05/04/2026 16:26',
        'estado': 'Cancelado',
        'extra': '🚫 Cancelado por: Dueño',
      },
      {
        'titulo': 'Paseo #2',
        'perro': 'chocoroles',
        'paseador': 'Javier Paseador',
        'fecha': '04/04/2026 20:55',
        'estado': 'Cancelado',
        'extra': '🚫 Cancelado por: Dueño',
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
              children: [
                const Text(
                  '🦴 TU HISTORIAL',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mis paseos',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Revisa el estado de todos tus paseos, activos e históricos.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ResumenCard(
                        numero: '1',
                        texto: 'Pendiente',
                        color: Color(0xFFE3A72F),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResumenCard(
                        numero: '1',
                        texto: 'Finalizado',
                        color: Color(0xFF7ACB8A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResumenCard(
                        numero: '2',
                        texto: 'Cancelados',
                        color: Color(0xFFE56B6F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const _SectionTitle(
                  titulo: 'Pendientes',
                  color: Color(0xFFE3A72F),
                ),
                const SizedBox(height: 10),
                ...paseosPendientes.map(
                  (p) => _buildPaseoCard(
                    context,
                    titulo: p['titulo']!,
                    perro: p['perro']!,
                    paseador: p['paseador']!,
                    fecha: p['fecha']!,
                    estado: p['estado']!,
                    extra: p['extra'],
                  ),
                ),
                const SizedBox(height: 8),
                const _SectionTitle(
                  titulo: 'Finalizados',
                  color: Color(0xFF7ACB8A),
                ),
                const SizedBox(height: 10),
                ...paseosFinalizados.map(
                  (p) => _buildPaseoCard(
                    context,
                    titulo: p['titulo']!,
                    perro: p['perro']!,
                    paseador: p['paseador']!,
                    fecha: p['fecha']!,
                    estado: p['estado']!,
                    extra: p['extra'],
                  ),
                ),
                const SizedBox(height: 8),
                const _SectionTitle(
                  titulo: 'Cancelados',
                  color: Color(0xFFE56B6F),
                ),
                const SizedBox(height: 10),
                ...paseosCancelados.map(
                  (p) => _buildPaseoCard(
                    context,
                    titulo: p['titulo']!,
                    perro: p['perro']!,
                    paseador: p['paseador']!,
                    fecha: p['fecha']!,
                    estado: p['estado']!,
                    extra: p['extra'],
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

class _ResumenCard extends StatelessWidget {
  final String numero;
  final String texto;
  final Color color;

  const _ResumenCard({
    required this.numero,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            numero,
            style: TextStyle(
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String titulo;
  final Color color;

  const _SectionTitle({
    required this.titulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 5,
          backgroundColor: color,
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF25324A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}