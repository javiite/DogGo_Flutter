import 'package:flutter/material.dart';
import '../services/perros_service.dart';

class DetallePerroScreen extends StatefulWidget {
  final Map<String, dynamic> perro;

  const DetallePerroScreen({
    super.key,
    required this.perro,
  });

  @override
  State<DetallePerroScreen> createState() => _DetallePerroScreenState();
}

class _DetallePerroScreenState extends State<DetallePerroScreen> {
  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _perroDetalle;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PerrosService.obtenerPerroPorId(
        widget.perro['id'] as int,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _perroDetalle = result['data'] as Map<String, dynamic>;
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

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  @override
  Widget build(BuildContext context) {
    final perro = _perroDetalle ?? widget.perro;

    final nombre = _textoSeguro(perro['nombre'], 'Perro');
    final raza = _textoSeguro(perro['raza'], 'Sin raza');
    final edad = _textoSeguro(perro['edad'], 'Sin edad');
    final tamano = _textoSeguro(
      perro['tamano'] ?? perro['tamaño'],
      'Sin tamaño',
    );
    final notas = _textoSeguro(
      perro['notas'] ?? perro['nota'] ?? perro['descripcion'],
      'Sin notas',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Detalle del perro'),
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
                          onPressed: _cargarDetalle,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
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
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCEEEE),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text(
                                '🐶',
                                style: TextStyle(fontSize: 52),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            raza,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailBox(titulo: 'Nombre', valor: nombre),
                    const SizedBox(height: 12),
                    _DetailBox(titulo: 'Raza', valor: raza),
                    const SizedBox(height: 12),
                    _DetailBox(titulo: 'Edad', valor: '$edad años'),
                    const SizedBox(height: 12),
                    _DetailBox(titulo: 'Tamaño', valor: tamano),
                    const SizedBox(height: 12),
                    _DetailBox(titulo: 'Notas', valor: notas),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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