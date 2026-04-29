import 'package:flutter/material.dart';
import '../services/paseos_service.dart';

class MisPaseosScreen extends StatefulWidget {
  const MisPaseosScreen({super.key});

  @override
  State<MisPaseosScreen> createState() => _MisPaseosScreenState();
}

class _MisPaseosScreenState extends State<MisPaseosScreen> {
  bool _cargando = true;
  String? _error;
  List<dynamic> _paseos = [];

  @override
  void initState() {
    super.initState();
    _cargarPaseos();
  }

  Future<void> _cargarPaseos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PaseosService.obtenerMisPaseos();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _paseos = result['data'] as List<dynamic>;
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
                          _mostrarMensaje('Detalle del paseo después');
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

  List<dynamic> get _pendientes => _paseos.where((p) {
        final estado = _textoSeguro((p as Map<String, dynamic>)['estado'], '');
        return estado.toLowerCase() == 'pendiente' ||
            estado.toLowerCase() == 'en curso' ||
            estado.toLowerCase() == 'encurso';
      }).toList();

  List<dynamic> get _finalizados => _paseos.where((p) {
        final estado = _textoSeguro((p as Map<String, dynamic>)['estado'], '');
        return estado.toLowerCase() == 'finalizado';
      }).toList();

  List<dynamic> get _cancelados => _paseos.where((p) {
        final estado = _textoSeguro((p as Map<String, dynamic>)['estado'], '');
        return estado.toLowerCase() == 'cancelado';
      }).toList();

  String _tituloPaseo(Map<String, dynamic> paseo) {
    final id = paseo['id'];
    return id != null ? 'Paseo #$id' : 'Paseo';
  }

  String _nombrePerro(Map<String, dynamic> paseo) {
    if (paseo['perroNombre'] != null) return _textoSeguro(paseo['perroNombre']);
    if (paseo['perro'] is Map<String, dynamic>) {
      return _textoSeguro((paseo['perro'] as Map<String, dynamic>)['nombre']);
    }
    return 'Perro sin nombre';
  }

  String _nombrePaseador(Map<String, dynamic> paseo) {
    if (paseo['paseadorNombre'] != null) {
      return _textoSeguro(paseo['paseadorNombre']);
    }
    if (paseo['paseador'] is Map<String, dynamic>) {
      final paseador = paseo['paseador'] as Map<String, dynamic>;
      if (paseador['nombre'] != null) return _textoSeguro(paseador['nombre']);
      if (paseador['usuario'] is Map<String, dynamic>) {
        return _textoSeguro(
          (paseador['usuario'] as Map<String, dynamic>)['nombre'],
          'Sin paseador',
        );
      }
    }
    return 'Sin paseador';
  }

  String _fechaPaseo(Map<String, dynamic> paseo) {
    final fechaProgramada = paseo['fechaProgramada'];
    final fechaInicio = paseo['fechaInicio'];
    final duracion = paseo['duracionMinutos'];

    final fecha = fechaProgramada ?? fechaInicio;
    final fechaTexto = fecha != null ? fecha.toString() : 'Sin fecha';

    if (duracion != null) {
      return '$fechaTexto · $duracion min';
    }

    return fechaTexto;
  }

  String? _extraPaseo(Map<String, dynamic> paseo) {
    final estado = _textoSeguro(paseo['estado'], '');

    if (estado.toLowerCase() == 'cancelado') {
      final canceladoPor = _textoSeguro(paseo['canceladoPor'], 'Sin dato');
      return '🚫 Cancelado por: $canceladoPor';
    }

    if (estado.toLowerCase() == 'finalizado') {
      return '⭐ Paseo completado';
    }

    final recogida = paseo['ubicacionTexto'] ??
        paseo['direccionRecogida'] ??
        paseo['ubicacionRecogida'];

    if (recogida != null && recogida.toString().trim().isNotEmpty) {
      return '📍 ${recogida.toString()}';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                          onPressed: _cargarPaseos,
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
                                  numero: '${_pendientes.length}',
                                  texto: 'Pendientes',
                                  color: const Color(0xFFE3A72F),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ResumenCard(
                                  numero: '${_finalizados.length}',
                                  texto: 'Finalizados',
                                  color: const Color(0xFF7ACB8A),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ResumenCard(
                                  numero: '${_cancelados.length}',
                                  texto: 'Cancelados',
                                  color: const Color(0xFFE56B6F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _paseos.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.map_outlined,
                                      size: 76,
                                      color: Color(0xFFB8B3AA),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Todavía no tienes paseos',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF25324A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Cuando agendes uno, aparecerá aquí.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        _mostrarMensaje('Crear paseo después');
                                      },
                                      child: const Text('Nuevo paseo'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarPaseos,
                              child: ListView(
                                padding: const EdgeInsets.all(18),
                                children: [
                                  if (_pendientes.isNotEmpty) ...[
                                    const _SectionTitle(
                                      titulo: 'Pendientes',
                                      color: Color(0xFFE3A72F),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._pendientes.map((p) {
                                      final paseo = p as Map<String, dynamic>;
                                      return _buildPaseoCard(
                                        context,
                                        titulo: _tituloPaseo(paseo),
                                        perro: _nombrePerro(paseo),
                                        paseador: _nombrePaseador(paseo),
                                        fecha: _fechaPaseo(paseo),
                                        estado: _textoSeguro(
                                          paseo['estado'],
                                          'Pendiente',
                                        ),
                                        extra: _extraPaseo(paseo),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                  if (_finalizados.isNotEmpty) ...[
                                    const _SectionTitle(
                                      titulo: 'Finalizados',
                                      color: Color(0xFF7ACB8A),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._finalizados.map((p) {
                                      final paseo = p as Map<String, dynamic>;
                                      return _buildPaseoCard(
                                        context,
                                        titulo: _tituloPaseo(paseo),
                                        perro: _nombrePerro(paseo),
                                        paseador: _nombrePaseador(paseo),
                                        fecha: _fechaPaseo(paseo),
                                        estado: _textoSeguro(
                                          paseo['estado'],
                                          'Finalizado',
                                        ),
                                        extra: _extraPaseo(paseo),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                  if (_cancelados.isNotEmpty) ...[
                                    const _SectionTitle(
                                      titulo: 'Cancelados',
                                      color: Color(0xFFE56B6F),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._cancelados.map((p) {
                                      final paseo = p as Map<String, dynamic>;
                                      return _buildPaseoCard(
                                        context,
                                        titulo: _tituloPaseo(paseo),
                                        perro: _nombrePerro(paseo),
                                        paseador: _nombrePaseador(paseo),
                                        fecha: _fechaPaseo(paseo),
                                        estado: _textoSeguro(
                                          paseo['estado'],
                                          'Cancelado',
                                        ),
                                        extra: _extraPaseo(paseo),
                                      );
                                    }),
                                  ],
                                ],
                              ),
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