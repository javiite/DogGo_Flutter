import 'package:flutter/material.dart';

import '../services/perros_service.dart';
import '../services/storage_service.dart';
import 'editar_perro_screen.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);

  static const violet = Color(0xFF7C5CBF);
  static const violetSurf = Color(0xFFF0EBFA);

  static const amber = Color(0xFFFFAB2E);
  static const amberSurf = Color(0xFFFFF4E0);

  static const emerald = Color(0xFF22C55E);
  static const emeraldSurf = Color(0xFFE6FAF0);

  static const rose = Color(0xFFEF4444);
  static const roseSurf = Color(0xFFFEEEEE);

  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static List<BoxShadow> shadow({
    double opacity = .055,
    double blur = 16,
    Offset offset = const Offset(0, 5),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }
}

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double spacing = 0,
  double height = 1.2,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

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
  bool _huboCambios = false;

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

  String _edadTexto(dynamic edad) {
    final texto = _textoSeguro(edad, 'Sin edad');

    if (texto == 'Sin edad') return texto;
    if (texto == '1') return '1 año';

    if (texto.toLowerCase().contains('año')) {
      return texto;
    }

    return '$texto años';
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
          'imagen',
          'Imagen',
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

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return '';

    if (raw.startsWith('/')) {
      return '$base$raw';
    }

    return '$base/$raw';
  }

  Future<void> _abrirEditar(Map<String, dynamic> perro) async {
    final editado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPerroScreen(
          perro: perro,
        ),
      ),
    );

    if (!mounted) return;

    if (editado == true) {
      _huboCambios = true;
      await _cargarDetalle();
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _huboCambios);
    return false;
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

    final edad = _edadTexto(
      _valor(
        perro,
        [
          'edad',
          'Edad',
        ],
      ),
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: _T.tealDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '🐶',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Detalle del perro',
                style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
              ),
            ],
          ),
          actions: [
            if (!_cargando && _error == null)
              IconButton(
                tooltip: 'Editar perro',
                onPressed: () => _abrirEditar(perro),
                icon: const Icon(Icons.edit_rounded),
              ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _cargarDetalle,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(
                    mensaje: _error!,
                    onRetry: _cargarDetalle,
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDetalle,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.zero,
                      children: [
                        _HeroDetallePerro(
                          nombre: nombre,
                          raza: raza,
                          edad: edad,
                          tamano: tamano,
                          fotoUrl: fotoUrl,
                          tieneFoto: tieneFoto,
                          onEditar: () => _abrirEditar(perro),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _MiniInfoBox(
                                  titulo: tamano,
                                  subtitulo: 'Tamaño',
                                  color: _T.teal,
                                  surface: _T.tealSurface,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MiniInfoBox(
                                  titulo: edad,
                                  subtitulo: 'Edad',
                                  color: _T.violet,
                                  surface: _T.violetSurf,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _SectionCard(
                          title: '🐾 Información general',
                          children: [
                            _InfoRow(
                              icon: Icons.pets_rounded,
                              title: 'Nombre',
                              value: nombre,
                              color: _T.teal,
                              surface: _T.tealSurface,
                            ),
                            _InfoRow(
                              icon: Icons.category_rounded,
                              title: 'Raza',
                              value: raza,
                              color: _T.violet,
                              surface: _T.violetSurf,
                            ),
                            _InfoRow(
                              icon: Icons.straighten_rounded,
                              title: 'Tamaño',
                              value: tamano,
                              color: _T.emerald,
                              surface: _T.emeraldSurf,
                            ),
                            _InfoRow(
                              icon: Icons.cake_rounded,
                              title: 'Edad',
                              value: edad,
                              color: _T.amber,
                              surface: _T.amberSurf,
                            ),
                          ],
                        ),
                        _SectionCard(
                          title: '📝 Notas y cuidados',
                          children: [
                            _NoteBox(text: notas),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 34),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirEditar(perro),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Editar perro'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _T.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _HeroDetallePerro extends StatelessWidget {
  final String nombre;
  final String raza;
  final String edad;
  final String tamano;
  final String fotoUrl;
  final bool tieneFoto;
  final VoidCallback onEditar;

  const _HeroDetallePerro({
    required this.nombre,
    required this.raza,
    required this.edad,
    required this.tamano,
    required this.fotoUrl,
    required this.tieneFoto,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF089B7A),
            Color(0xFFF4F0E8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _T.shadow(
              opacity: .075,
              blur: 22,
              offset: const Offset(0, 8),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 245,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: tieneFoto
                          ? Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const _LargeDogPlaceholder();
                              },
                            )
                          : const _LargeDogPlaceholder(),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(.03),
                              Colors.black.withOpacity(.38),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _Tag(
                        text: tamano,
                        color: _T.tealDeep,
                        background: Colors.white.withOpacity(.94),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.94),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onEditar,
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: _T.tealDeep,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(
                              31,
                              FontWeight.w900,
                              Colors.white,
                              spacing: -.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Tag(
                                text: raza,
                                color: _T.tealDeep,
                                background: Colors.white.withOpacity(.92),
                              ),
                              _Tag(
                                text: edad,
                                color: _T.violet,
                                background: Colors.white.withOpacity(.92),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  children: [
                    Text(
                      'Perfil de mascota',
                      style: _ts(11, FontWeight.w900, _T.tealDeep, spacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consulta los datos principales de $nombre y mantenlos actualizados.',
                      textAlign: TextAlign.center,
                      style: _ts(13, FontWeight.w500, _T.inkSub, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeDogPlaceholder extends StatelessWidget {
  const _LargeDogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.tealSurface,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -45,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _T.teal.withOpacity(.13),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: _T.violet.withOpacity(.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Text(
              '🐶',
              style: TextStyle(
                fontSize: 92,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color surface;

  const _MiniInfoBox({
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _T.shadow(
          opacity: .045,
          blur: 14,
          offset: const Offset(0, 4),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              style: _ts(13, FontWeight.w900, color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            style: _ts(11.5, FontWeight.w500, _T.inkSub),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _T.shadow(
          opacity: .05,
          blur: 16,
          offset: const Offset(0, 4),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: _ts(14, FontWeight.w900, _T.ink, spacing: -.2),
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color surface;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: _ts(12, FontWeight.w600, _T.inkSub),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _ts(13.5, FontWeight.w900, _T.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;

  const _NoteBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final sinNotas = text.trim().isEmpty || text == 'Sin notas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sinNotas ? const Color(0xFFF3F4F6) : _T.amberSurf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sinNotas ? _T.stroke : _T.amber.withOpacity(.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              sinNotas ? Icons.notes_rounded : Icons.info_outline_rounded,
              color: sinNotas ? _T.inkSub : _T.amber,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sinNotas
                    ? 'No hay notas especiales registradas para este perro.'
                    : text,
                style: _ts(
                  12.5,
                  FontWeight.w700,
                  sinNotas ? _T.inkSub : const Color(0xFF8A6A1F),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _Tag({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: _ts(11, FontWeight.w900, color),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _T.shadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: _T.rose.withOpacity(.85),
              ),
              const SizedBox(height: 14),
              Text(
                'No se pudo cargar el perro',
                textAlign: TextAlign.center,
                style: _ts(18, FontWeight.w900, _T.ink),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: _ts(13, FontWeight.w500, _T.inkSub, height: 1.3),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}