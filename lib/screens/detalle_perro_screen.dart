import 'package:flutter/material.dart';

import '../services/perros_service.dart';
import '../services/storage_service.dart';

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
  String? _baseUrl;
  Map<String, dynamic>? _perroDetalle;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final baseUrl = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = baseUrl;
    });

    await _cargarDetalle();
  }

  Map<String, dynamic> _mapaSeguro(dynamic valor) {
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) return Map<String, dynamic>.from(valor);
    return {};
  }

  dynamic _valor(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) {
        return mapa[key];
      }
    }

    return null;
  }

  int? _idPerro(Map<String, dynamic> perro) {
    final valor = _valor(
      perro,
      [
        'id',
        'Id',
        'perroId',
        'PerroId',
        'idPerro',
        'IdPerro',
      ],
    );

    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '');
  }

  Future<void> _cargarDetalle() async {
    final id = _idPerro(widget.perro);

    if (id == null) {
      setState(() {
        _error = 'No se encontró el ID del perro.';
        _cargando = false;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PerrosService.obtenerPerroPorId(id);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _perroDetalle = _mapaSeguro(result['data']);
          _cargando = false;
        });
      } else {
        setState(() {
          _error =
              result['message']?.toString() ?? 'No se pudo obtener el perro.';
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

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _fotoPerro(Map<String, dynamic> perro) {
    final raw = _textoSeguro(
      _valor(
        perro,
        [
          'fotoUrl',
          'FotoUrl',
          'foto',
          'Foto',
          'urlFoto',
          'UrlFoto',
          'imagenUrl',
          'ImagenUrl',
          'fotoPerroUrl',
          'FotoPerroUrl',
        ],
      ),
      '',
    );

    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    if (_baseUrl == null || _baseUrl!.trim().isEmpty) {
      return '';
    }

    if (raw.startsWith('/')) {
      return '${_baseUrl!}$raw';
    }

    return '${_baseUrl!}/$raw';
  }

  @override
  Widget build(BuildContext context) {
    final perro = _perroDetalle ?? widget.perro;

    final nombre = _textoSeguro(
      _valor(
        perro,
        [
          'nombre',
          'Nombre',
          'nombrePerro',
          'NombrePerro',
        ],
      ),
      'Perro',
    );

    final raza = _textoSeguro(
      _valor(
        perro,
        [
          'raza',
          'Raza',
        ],
      ),
      'Sin raza',
    );

    final edad = _textoSeguro(
      _valor(
        perro,
        [
          'edad',
          'Edad',
        ],
      ),
      'Sin edad',
    );

    final tamano = _textoSeguro(
      _valor(
        perro,
        [
          'tamano',
          'Tamano',
          'tamanio',
          'Tamanio',
          'tamaño',
          'Tamaño',
        ],
      ),
      'Sin tamaño',
    );

    final notas = _textoSeguro(
      _valor(
        perro,
        [
          'notas',
          'Notas',
          'nota',
          'Nota',
          'descripcion',
          'Descripcion',
          'observaciones',
          'Observaciones',
        ],
      ),
      'Sin notas',
    );

    final fotoUrl = _fotoPerro(perro);
    final tieneFoto =
        fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');

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
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCEEEE),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: tieneFoto
                                ? Image.network(
                                    fotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return const Center(
                                        child: Text(
                                          '🐶',
                                          style: TextStyle(fontSize: 58),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Text(
                                      '🐶',
                                      style: TextStyle(fontSize: 58),
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
                    _DetailBox(
                      titulo: 'Edad',
                      valor: edad == 'Sin edad' ? edad : '$edad años',
                    ),
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