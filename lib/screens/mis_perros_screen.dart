import 'package:flutter/material.dart';

import '../services/perros_service.dart';
import '../services/storage_service.dart';
import 'detalle_perro_screen.dart';
import 'editar_perro_screen.dart';
import 'registrar_perro_screen.dart';

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

class MisPerrosScreen extends StatefulWidget {
  const MisPerrosScreen({super.key});

  @override
  State<MisPerrosScreen> createState() => _MisPerrosScreenState();
}

class _MisPerrosScreenState extends State<MisPerrosScreen> {
  bool _cargando = true;
  String? _error;
  String? _baseUrl;
  List<dynamic> _perros = [];

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

    await _cargarPerros();
  }

  Future<void> _cargarPerros() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PerrosService.obtenerMisPerros();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          _perros = data is List ? data : [];
          _cargando = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString() ??
              'No se pudieron obtener los perros.';
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

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _edadTexto(dynamic edad) {
    if (edad == null) return 'Sin edad';

    final texto = edad.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return 'Sin edad';
    }

    if (texto == '1') return '1 año';

    return '$texto años';
  }

  String _nombrePerro(Map<String, dynamic> perro) {
    return _textoSeguro(
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
  }

  String _razaPerro(Map<String, dynamic> perro) {
    return _textoSeguro(
      _valor(
        perro,
        [
          'raza',
          'Raza',
        ],
      ),
      'Sin raza',
    );
  }

  String _tamanoPerro(Map<String, dynamic> perro) {
    return _textoSeguro(
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
  }

  String _notasPerro(Map<String, dynamic> perro) {
    return _textoSeguro(
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
      '',
    );
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

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> perro) async {
    final id = _idPerro(perro);

    if (id == null) {
      _mostrarMensaje('No se encontró el ID del perro.');
      return;
    }

    final nombre = _nombrePerro(perro);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Eliminar perro'),
          content: Text(
            '¿Seguro que quieres eliminar a $nombre? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.rose,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final result = await PerrosService.eliminarPerro(id);

      if (!mounted) return;

      _mostrarMensaje(
        result['message']?.toString() ?? 'Acción completada.',
      );

      if (result['success'] == true) {
        await _cargarPerros();
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e');
    }
  }

  Future<void> _abrirRegistrar() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrarPerroScreen(),
      ),
    );

    if (!mounted) return;

    if (creado == true) {
      await _cargarPerros();
    }
  }

  Future<void> _abrirDetalle(Map<String, dynamic> perro) async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePerroScreen(
          perro: perro,
        ),
      ),
    );

    if (!mounted) return;

    if (actualizado == true) {
      await _cargarPerros();
    }
  }

  Future<void> _abrirEditar(Map<String, dynamic> perro) async {
    final editado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPerroScreen(
          perro: perro,
        ),
      ),
    );

    if (!mounted) return;

    if (editado == true) {
      await _cargarPerros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  '🐾',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mis perros',
              style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarPerros,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirRegistrar,
        backgroundColor: _T.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Añadir perro',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  mensaje: _error!,
                  onRetry: _cargarPerros,
                )
              : RefreshIndicator(
                  onRefresh: _cargarPerros,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.zero,
                    children: [
                      _HeaderPerros(
                        cantidad: _perros.length,
                        onAdd: _abrirRegistrar,
                      ),
                      if (_perros.isEmpty)
                        _EmptyState(
                          onAdd: _abrirRegistrar,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          child: Column(
                            children: List.generate(_perros.length, (index) {
                              final perro = _mapaSeguro(_perros[index]);

                              final nombre = _nombrePerro(perro);
                              final raza = _razaPerro(perro);
                              final tamano = _tamanoPerro(perro);
                              final notas = _notasPerro(perro);
                              final edad = _edadTexto(
                                _valor(
                                  perro,
                                  [
                                    'edad',
                                    'Edad',
                                  ],
                                ),
                              );
                              final fotoUrl = _fotoPerro(perro);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _PerroCard(
                                  nombre: nombre,
                                  edad: edad,
                                  raza: raza,
                                  tamano: tamano,
                                  nota: notas,
                                  fotoUrl: fotoUrl,
                                  index: index,
                                  onVerPerro: () => _abrirDetalle(perro),
                                  onEditar: () => _abrirEditar(perro),
                                  onEliminar: () => _confirmarEliminar(perro),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderPerros extends StatelessWidget {
  final int cantidad;
  final VoidCallback onAdd;

  const _HeaderPerros({
    required this.cantidad,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final textoCantidad = cantidad == 1
        ? 'Tienes 1 perro registrado.'
        : 'Tienes $cantidad perros registrados.';

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
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0EC9A0),
                Color(0xFF057A5F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _T.teal.withOpacity(.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -35,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SmallPill(
                    text: 'TU MANADA',
                    color: Colors.white,
                    background: Colors.white.withOpacity(.18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mis perros',
                    style: _ts(
                      31,
                      FontWeight.w900,
                      Colors.white,
                      spacing: -.8,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    textoCantidad,
                    style: _ts(
                      14,
                      FontWeight.w500,
                      Colors.white.withOpacity(.82),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Añadir perro',
                        style: _ts(
                          12.5,
                          FontWeight.w900,
                          _T.tealDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerroCard extends StatelessWidget {
  final String nombre;
  final String edad;
  final String raza;
  final String tamano;
  final String nota;
  final String fotoUrl;
  final int index;
  final VoidCallback onVerPerro;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _PerroCard({
    required this.nombre,
    required this.edad,
    required this.raza,
    required this.tamano,
    required this.nota,
    required this.fotoUrl,
    required this.index,
    required this.onVerPerro,
    required this.onEditar,
    required this.onEliminar,
  });

  bool get _tieneFoto {
    return fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');
  }

  Color get _accent {
    final colores = [
      _T.teal,
      _T.violet,
      _T.amber,
      _T.emerald,
      _T.rose,
    ];

    return colores[index % colores.length];
  }

  Color get _surface {
    final colores = [
      _T.tealSurface,
      _T.violetSurf,
      _T.amberSurf,
      _T.emeraldSurf,
      _T.roseSurf,
    ];

    return colores[index % colores.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVerPerro,
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _T.shadow(
            opacity: .055,
            blur: 18,
            offset: const Offset(0, 6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 175,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _tieneFoto
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return _DogPlaceholder(
                                accent: _accent,
                                surface: _surface,
                              );
                            },
                          )
                        : _DogPlaceholder(
                            accent: _accent,
                            surface: _surface,
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(.00),
                            Colors.black.withOpacity(.28),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _Tag(
                      text: tamano,
                      color: _accent,
                      background: Colors.white.withOpacity(.92),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.92),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onEditar,
                        icon: Icon(
                          Icons.edit_rounded,
                          color: _accent,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    right: 16,
                    child: Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(
                        26,
                        FontWeight.w900,
                        Colors.white,
                        spacing: -.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(
                        text: raza,
                        color: _accent,
                        background: _surface,
                      ),
                      _Tag(
                        text: edad,
                        color: _T.inkSub,
                        background: const Color(0xFFF3F4F6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfoBox(
                          titulo: tamano,
                          subtitulo: 'Tamaño',
                          color: _accent,
                          surface: _surface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniInfoBox(
                          titulo: edad,
                          subtitulo: 'Edad',
                          color: _accent,
                          surface: _surface,
                        ),
                      ),
                    ],
                  ),
                  if (nota.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _T.amberSurf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _T.amber.withOpacity(.25),
                        ),
                      ),
                      child: Text(
                        'Nota: $nota',
                        style: _ts(
                          12.5,
                          FontWeight.w700,
                          const Color(0xFF8A6A1F),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onVerPerro,
                          icon: const Icon(Icons.visibility_rounded, size: 18),
                          label: const Text('Ver perro'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _CircleActionButton(
                        icon: Icons.edit_outlined,
                        color: _accent,
                        background: _surface,
                        onTap: onEditar,
                      ),
                      const SizedBox(width: 8),
                      _CircleActionButton(
                        icon: Icons.delete_outline,
                        color: _T.rose,
                        background: _T.roseSurf,
                        onTap: onEliminar,
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
}

class _DogPlaceholder extends StatelessWidget {
  final Color accent;
  final Color surface;

  const _DogPlaceholder({
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      child: Stack(
        children: [
          Positioned(
            top: -35,
            right: -35,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                color: accent.withOpacity(.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Text(
              '🐶',
              style: TextStyle(
                fontSize: 76,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: _ts(13, FontWeight.w900, color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: _ts(11.5, FontWeight.w500, _T.inkSub),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
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

class _SmallPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _SmallPill({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(.20),
        ),
      ),
      child: Text(
        text,
        style: _ts(10, FontWeight.w900, color, spacing: 1.2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
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
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _T.tealSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🐶',
                      style: TextStyle(fontSize: 44),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Todavía no tienes perros registrados',
                  textAlign: TextAlign.center,
                  style: _ts(18, FontWeight.w900, _T.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando agregues uno, aparecerá aquí con su información.',
                  textAlign: TextAlign.center,
                  style: _ts(13, FontWeight.w500, _T.inkSub, height: 1.3),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Añadir perro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                'No se pudieron cargar tus perros',
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