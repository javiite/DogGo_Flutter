import 'package:flutter/material.dart';

import '../services/perros_service.dart';
import '../services/storage_service.dart';
import '../widgets/doggo_logo.dart';
import '../widgets/doggo_pattern_background.dart';
import 'detalle_perro_screen.dart';
import 'editar_perro_screen.dart';
import 'registrar_perro_screen.dart';

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
    if (!mounted) return;

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

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
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

  String _edadTexto(Map<String, dynamic> perro) {
    final edad = _valor(
      perro,
      [
        'edad',
        'Edad',
      ],
    );

    if (edad == null) return 'Sin edad';

    final texto = edad.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return 'Sin edad';

    if (texto == '1') return '1 año';

    if (texto.toLowerCase().contains('año')) return texto;

    return '$texto años';
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
          backgroundColor: _DogGoWeb.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Eliminar perro',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _DogGoWeb.ink,
            ),
          ),
          content: Text(
            '¿Seguro que quieres eliminar a $nombre? Esta acción no se puede deshacer.',
            style: _DogGoWeb.subtitle(14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DogGoWeb.rose,
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
    final tienePerros = _perros.isNotEmpty;

    return Scaffold(
      backgroundColor: _DogGoWeb.cream,
      body: SafeArea(
        child: DogGoPatternBackground(
          opacity: 1.15,
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(
                      mensaje: _error!,
                      onRetry: _cargarPerros,
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarPerros,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _TopWebBar(
                              onBack: () => Navigator.pop(context, true),
                              onRefresh: _cargarPerros,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _HeroMisPerros(
                              cantidad: _perros.length,
                              onAdd: _abrirRegistrar,
                            ),
                          ),
                          if (_perros.isEmpty)
                            SliverToBoxAdapter(
                              child: _EmptyState(
                                onAdd: _abrirRegistrar,
                              ),
                            )
                          else ...[
                            SliverToBoxAdapter(
                              child: _SectionHeader(
                                title: 'Tus mascotas registradas',
                                subtitle:
                                    'Toca una tarjeta para ver el perfil completo, editar datos o eliminar.',
                                onAdd: _abrirRegistrar,
                              ),
                            ),
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 14, 18, 120),
                              sliver: SliverList.separated(
                                itemCount: _perros.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final perro = _mapaSeguro(_perros[index]);

                                  return _PerroWebCard(
                                    nombre: _nombrePerro(perro),
                                    raza: _razaPerro(perro),
                                    edad: _edadTexto(perro),
                                    tamano: _tamanoPerro(perro),
                                    nota: _notasPerro(perro),
                                    fotoUrl: _fotoPerro(perro),
                                    index: index,
                                    onVer: () => _abrirDetalle(perro),
                                    onEditar: () => _abrirEditar(perro),
                                    onEliminar: () => _confirmarEliminar(perro),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
        ),
      ),
      floatingActionButton: tienePerros
          ? FloatingActionButton.extended(
              onPressed: _abrirRegistrar,
              backgroundColor: _DogGoWeb.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Añadir perro',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
    );
  }
}

class _TopWebBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _TopWebBar({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.94),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(.07),
          ),
        ),
      ),
      child: Row(
        children: [
          _TopIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 8),
          const DogGoLogo(size: 54),
          const Spacer(),
          _TopIconButton(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _DogGoWeb.card,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _DogGoWeb.stroke),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: _DogGoWeb.ink,
            size: 23,
          ),
        ),
      ),
    );
  }
}

class _HeroMisPerros extends StatelessWidget {
  final int cantidad;
  final VoidCallback onAdd;

  const _HeroMisPerros({
    required this.cantidad,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final textoCantidad = cantidad == 1
        ? 'Tienes 1 perro registrado.'
        : 'Tienes $cantidad perros registrados.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: _DogGoWeb.card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _DogGoWeb.stroke),
          boxShadow: _DogGoWeb.shadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: Transform.rotate(
                angle: -.18,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: _DogGoWeb.tealLight,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: _DogGoWeb.teal,
                    size: 58,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -28,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: _DogGoWeb.orange.withOpacity(.09),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _DogGoWeb.tealLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'TU MANADA',
                    style: _DogGoWeb.label(),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 86),
                  child: Text(
                    'Mis perros',
                    style: _DogGoWeb.title(36),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 62),
                  child: Text(
                    textoCantidad,
                    style: _DogGoWeb.subtitle(16),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        icon: Icons.pets_rounded,
                        title: '$cantidad',
                        subtitle: cantidad == 1 ? 'Mascota' : 'Mascotas',
                        color: _DogGoWeb.teal,
                        background: _DogGoWeb.tealLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(
                        icon: Icons.favorite_rounded,
                        title: 'DogGo',
                        subtitle: 'Cuidado',
                        color: _DogGoWeb.orange,
                        background: _DogGoWeb.orangeLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      cantidad == 0
                          ? 'Añadir mi primer perro'
                          : 'Añadir otro perro',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DogGoWeb.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
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

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;

  const _HeroStat({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _DogGoWeb.body(
                    15,
                    color: _DogGoWeb.ink,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _DogGoWeb.subtitle(11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _DogGoWeb.title(24),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: _DogGoWeb.subtitle(13.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _DogGoWeb.tealLight,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(18),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.add_rounded,
                  color: _DogGoWeb.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerroWebCard extends StatelessWidget {
  final String nombre;
  final String raza;
  final String edad;
  final String tamano;
  final String nota;
  final String fotoUrl;
  final int index;
  final VoidCallback onVer;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _PerroWebCard({
    required this.nombre,
    required this.raza,
    required this.edad,
    required this.tamano,
    required this.nota,
    required this.fotoUrl,
    required this.index,
    required this.onVer,
    required this.onEditar,
    required this.onEliminar,
  });

  bool get _tieneFoto {
    return fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');
  }

  Color get _accent {
    final colors = [
      _DogGoWeb.tealDeep,
      _DogGoWeb.purple,
      _DogGoWeb.orange,
      _DogGoWeb.green,
      _DogGoWeb.rose,
    ];

    return colors[index % colors.length];
  }

  Color get _surface {
    final colors = [
      _DogGoWeb.tealLight,
      _DogGoWeb.purpleLight,
      _DogGoWeb.orangeLight,
      _DogGoWeb.greenLight,
      _DogGoWeb.roseLight,
    ];

    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onVer,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: _DogGoWeb.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _DogGoWeb.stroke),
            boxShadow: _DogGoWeb.shadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 210,
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
                                  surface: _surface,
                                  accent: _accent,
                                );
                              },
                            )
                          : _DogPlaceholder(
                              surface: _surface,
                              accent: _accent,
                            ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(.42),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _ChipLabel(
                        text: tamano,
                        color: _DogGoWeb.tealDeep,
                        background: Colors.white.withOpacity(.92),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _DogGoWeb.title(
                          28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChipLabel(
                          text: raza,
                          color: _DogGoWeb.tealDeep,
                          background: _DogGoWeb.tealLight,
                        ),
                        _ChipLabel(
                          text: edad,
                          color: _DogGoWeb.orange,
                          background: _DogGoWeb.orangeLight,
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
                          color: _DogGoWeb.orangeLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _DogGoWeb.orange.withOpacity(.12),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.sticky_note_2_rounded,
                              color: _DogGoWeb.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nota,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _DogGoWeb.body(
                                  12.5,
                                  color: _DogGoWeb.ink,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: OutlinedButton.icon(
                              onPressed: onVer,
                              icon: const Icon(
                                Icons.visibility_rounded,
                                size: 18,
                              ),
                              label: const Text('Ver perfil'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _DogGoWeb.tealDeep,
                                side: const BorderSide(
                                  color: _DogGoWeb.tealDeep,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoundButton(
                          icon: Icons.edit_rounded,
                          color: _DogGoWeb.orange,
                          background: _DogGoWeb.orangeLight,
                          onTap: onEditar,
                        ),
                        const SizedBox(width: 8),
                        _RoundButton(
                          icon: Icons.delete_outline_rounded,
                          color: _DogGoWeb.rose,
                          background: _DogGoWeb.roseLight,
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
      ),
    );
  }
}

class _DogPlaceholder extends StatelessWidget {
  final Color surface;
  final Color accent;

  const _DogPlaceholder({
    required this.surface,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: accent.withOpacity(.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -26,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Text(
              '🐶',
              style: TextStyle(
                fontSize: 72,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 10,
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

class _ChipLabel extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _ChipLabel({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _DogGoWeb.body(
          11,
          color: color,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _RoundButton({
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
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 19,
            color: color,
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 110),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
        decoration: BoxDecoration(
          color: _DogGoWeb.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _DogGoWeb.stroke),
          boxShadow: _DogGoWeb.shadow(),
        ),
        child: Column(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: const BoxDecoration(
                color: _DogGoWeb.tealLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🐶',
                  style: TextStyle(fontSize: 54),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Todavía no tienes perros registrados',
              textAlign: TextAlign.center,
              style: _DogGoWeb.title(25),
            ),
            const SizedBox(height: 10),
            Text(
              'Agrega tu primera mascota para guardar su foto, raza, edad, tamaño y notas importantes antes de solicitar paseos.',
              textAlign: TextAlign.center,
              style: _DogGoWeb.subtitle(15),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir mi primer perro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DogGoWeb.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _DogGoWeb.warm,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _DogGoWeb.stroke),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _DogGoWeb.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cuando registres un perro, aparecerá aquí con su tarjeta completa y podrás editarlo cuando quieras.',
                      style: _DogGoWeb.body(
                        12.8,
                        color: _DogGoWeb.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
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

class _ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DogGoPatternBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _DogGoWeb.card,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _DogGoWeb.shadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 70,
                  color: _DogGoWeb.rose,
                ),
                const SizedBox(height: 14),
                Text(
                  'No se pudieron cargar tus perros',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.title(20),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(13),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DogGoWeb.teal,
                    foregroundColor: Colors.white,
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

class _DogGoWeb {
  static const teal = Color(0xFF0F9B8E);
  static const tealDeep = Color(0xFF0D8A7E);
  static const tealLight = Color(0xFFE0F5F3);

  static const purple = Color(0xFF7156C8);
  static const purpleLight = Color(0xFFEDE7FA);

  static const orange = Color(0xFFF5A623);
  static const orangeLight = Color(0xFFFFF3DC);

  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFE5F8ED);

  static const rose = Color(0xFFEF4444);
  static const roseLight = Color(0xFFFEEEEE);

  static const cream = Color(0xFFFFFBF5);
  static const warm = Color(0xFFFFF6ED);
  static const card = Colors.white;
  static const ink = Color(0xFF2D3142);
  static const muted = Color(0xFF7B8194);
  static const stroke = Color(0xFFEDE8E0);

  static TextStyle title(
    double size, {
    Color color = ink,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -.6,
      height: 1.08,
    );
  }

  static TextStyle subtitle(double size) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: muted,
      height: 1.35,
    );
  }

  static TextStyle label() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: tealDeep,
      letterSpacing: 1.6,
    );
  }

  static TextStyle body(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.25,
    );
  }

  static List<BoxShadow> shadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(.06),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ];
  }
}