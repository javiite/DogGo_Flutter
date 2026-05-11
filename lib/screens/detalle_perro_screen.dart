import 'package:flutter/material.dart';

import '../services/perros_service.dart';
import '../services/storage_service.dart';
import '../widgets/doggo_logo.dart';
import 'editar_perro_screen.dart';

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

  void _salir() {
    Navigator.pop(context, _huboCambios);
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
        backgroundColor: _DogGoWeb.bg,
        body: SafeArea(
          child: _PatternBackground(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(
                        mensaje: _error!,
                        onRetry: _cargarDetalle,
                        onBack: _salir,
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarDetalle,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _TopWebBar(
                                onBack: _salir,
                                onRefresh: _cargarDetalle,
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 28, 22, 34),
                                child: Column(
                                  children: [
                                    _HeaderIntro(
                                      nombre: nombre,
                                    ),
                                    const SizedBox(height: 18),
                                    _HeroDetallePerro(
                                      nombre: nombre,
                                      raza: raza,
                                      edad: edad,
                                      tamano: tamano,
                                      fotoUrl: fotoUrl,
                                      tieneFoto: tieneFoto,
                                      onEditar: () => _abrirEditar(perro),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MiniInfoBox(
                                            titulo: tamano,
                                            subtitulo: 'Tamaño',
                                            color: _DogGoWeb.tealDeep,
                                            surface: _DogGoWeb.tealLight,
                                            icon: Icons.straighten_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _MiniInfoBox(
                                            titulo: edad,
                                            subtitulo: 'Edad',
                                            color: _DogGoWeb.purple,
                                            surface: _DogGoWeb.purpleLight,
                                            icon: Icons.cake_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    _SectionCard(
                                      title: 'Información general',
                                      subtitle: 'Datos principales de tu mascota',
                                      icon: Icons.pets_rounded,
                                      color: _DogGoWeb.tealDeep,
                                      surface: _DogGoWeb.tealLight,
                                      child: Column(
                                        children: [
                                          _InfoRow(
                                            icon: Icons.pets_rounded,
                                            title: 'Nombre',
                                            value: nombre,
                                            color: _DogGoWeb.tealDeep,
                                            surface: _DogGoWeb.tealLight,
                                          ),
                                          _InfoRow(
                                            icon: Icons.category_rounded,
                                            title: 'Raza',
                                            value: raza,
                                            color: _DogGoWeb.purple,
                                            surface: _DogGoWeb.purpleLight,
                                          ),
                                          _InfoRow(
                                            icon: Icons.straighten_rounded,
                                            title: 'Tamaño',
                                            value: tamano,
                                            color: _DogGoWeb.green,
                                            surface: _DogGoWeb.greenLight,
                                          ),
                                          _InfoRow(
                                            icon: Icons.cake_rounded,
                                            title: 'Edad',
                                            value: edad,
                                            color: _DogGoWeb.orange,
                                            surface: _DogGoWeb.orangeLight,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _SectionCard(
                                      title: 'Notas y cuidados',
                                      subtitle:
                                          'Información útil para el paseador',
                                      icon: Icons.notes_rounded,
                                      color: _DogGoWeb.orange,
                                      surface: _DogGoWeb.orangeLight,
                                      child: _NoteBox(text: notas),
                                    ),
                                    const SizedBox(height: 18),
                                    _CareTipsCard(
                                      nombre: nombre,
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _abrirEditar(perro),
                                        icon: const Icon(Icons.edit_rounded),
                                        label: const Text('Editar perro'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _DogGoWeb.teal,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: OutlinedButton(
                                        onPressed: _salir,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _DogGoWeb.muted,
                                          side: const BorderSide(
                                            color: _DogGoWeb.stroke,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        child: const Text('Volver'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: _FooterDogGo(),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
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
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(.08),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _DogGoWeb.ink,
            ),
          ),
          const DogGoLogo(size: 54),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _DogGoWeb.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIntro extends StatelessWidget {
  final String nombre;

  const _HeaderIntro({
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: _DogGoWeb.cream.withOpacity(.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🐾 PERFIL DE MASCOTA',
            style: _DogGoWeb.label(),
          ),
          const SizedBox(height: 10),
          Text(
            nombre,
            style: _DogGoWeb.title(34),
          ),
          const SizedBox(height: 10),
          Text(
            'Consulta la información de tu perro y mantenla actualizada para que cada paseo sea más seguro.',
            style: _DogGoWeb.subtitle(15.5),
          ),
        ],
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
      decoration: BoxDecoration(
        color: _DogGoWeb.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 300,
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
                          Colors.black.withOpacity(.02),
                          Colors.black.withOpacity(.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: _Tag(
                    text: tamano,
                    color: _DogGoWeb.tealDeep,
                    background: Colors.white.withOpacity(.94),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Material(
                    color: Colors.white.withOpacity(.94),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onEditar,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(
                          Icons.edit_rounded,
                          color: _DogGoWeb.tealDeep,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _DogGoWeb.title(
                          34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(
                            text: raza,
                            color: _DogGoWeb.tealDeep,
                            background: Colors.white.withOpacity(.92),
                          ),
                          _Tag(
                            text: edad,
                            color: _DogGoWeb.purple,
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            color: _DogGoWeb.card,
            child: Column(
              children: [
                Text(
                  'Perfil de mascota',
                  style: _DogGoWeb.label(),
                ),
                const SizedBox(height: 7),
                Text(
                  'Esta información se usará como referencia cuando solicites paseos para $nombre.',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeDogPlaceholder extends StatelessWidget {
  const _LargeDogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DogGoWeb.tealLight,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -45,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _DogGoWeb.teal.withOpacity(.13),
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
                color: _DogGoWeb.purple.withOpacity(.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Text(
              '🐶',
              style: TextStyle(
                fontSize: 96,
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
  final IconData icon;

  const _MiniInfoBox({
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.surface,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: _DogGoWeb.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _DogGoWeb.body(
              15,
              color: _DogGoWeb.ink,
              weight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: _DogGoWeb.subtitle(11.5),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color surface;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surface,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _DogGoWeb.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _DogGoWeb.title(20),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: _DogGoWeb.subtitle(12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _DogGoWeb.cream.withOpacity(.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DogGoWeb.stroke.withOpacity(.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: _DogGoWeb.subtitle(12),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _DogGoWeb.body(
                13.5,
                color: _DogGoWeb.ink,
                weight: FontWeight.w900,
              ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: sinNotas ? const Color(0xFFF3F4F6) : _DogGoWeb.orangeLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: sinNotas
              ? _DogGoWeb.stroke
              : _DogGoWeb.orange.withOpacity(.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            sinNotas ? Icons.notes_rounded : Icons.info_outline_rounded,
            color: sinNotas ? _DogGoWeb.muted : _DogGoWeb.orange,
            size: 24,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              sinNotas
                  ? 'No hay notas especiales registradas para este perro.'
                  : text,
              style: _DogGoWeb.body(
                13,
                color: sinNotas ? _DogGoWeb.muted : const Color(0xFF8A6A1F),
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareTipsCard extends StatelessWidget {
  final String nombre;

  const _CareTipsCard({
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _DogGoWeb.tealLight.withOpacity(.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _DogGoWeb.teal.withOpacity(.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _DogGoWeb.teal,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo DogGo',
                  style: _DogGoWeb.title(17),
                ),
                const SizedBox(height: 5),
                Text(
                  'Mantén actualizados los datos de $nombre. Esto ayuda al paseador a conocer su tamaño, edad y cuidados especiales antes del paseo.',
                  style: _DogGoWeb.subtitle(12.5),
                ),
              ],
            ),
          ),
        ],
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

class _ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorState({
    required this.mensaje,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopWebBar(
          onBack: onBack,
          onRefresh: onRetry,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _DogGoWeb.card,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _DogGoWeb.stroke),
                  boxShadow: _DogGoWeb.shadow(),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 72,
                      color: _DogGoWeb.rose,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No se pudo cargar el perro',
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
        ),
      ],
    );
  }
}

class _FooterDogGo extends StatelessWidget {
  const _FooterDogGo();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DogGoWeb.tealLight.withOpacity(.45),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Column(
        children: [
          const DogGoLogo(size: 42),
          const SizedBox(height: 10),
          Text(
            'DogGo © 2026 — Proyecto universitario',
            style: _DogGoWeb.subtitle(13),
          ),
        ],
      ),
    );
  }
}

class _PatternBackground extends StatelessWidget {
  final Widget child;

  const _PatternBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DogPatternPainter(),
      child: child,
    );
  }
}

class _DogPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _DogGoWeb.teal.withOpacity(.10)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const stepX = 82.0;
    const stepY = 82.0;

    for (double y = 30; y < size.height + stepY; y += stepY) {
      for (double x = 22; x < size.width + stepX; x += stepX) {
        final shiftedX = x + ((y ~/ stepY) % 2 == 0 ? 0 : 34);

        _drawPaw(canvas, paint, Offset(shiftedX, y));
        _drawBone(canvas, paint, Offset(shiftedX + 38, y + 38));
      }
    }
  }

  void _drawPaw(Canvas canvas, Paint paint, Offset c) {
    canvas.drawCircle(c + const Offset(0, 7), 7, paint);
    canvas.drawCircle(c + const Offset(-9, -2), 3.8, paint);
    canvas.drawCircle(c + const Offset(-3, -8), 3.8, paint);
    canvas.drawCircle(c + const Offset(5, -8), 3.8, paint);
    canvas.drawCircle(c + const Offset(11, -2), 3.8, paint);
  }

  void _drawBone(Canvas canvas, Paint paint, Offset c) {
    canvas.drawLine(
      c + const Offset(-11, -11),
      c + const Offset(11, 11),
      paint,
    );

    canvas.drawCircle(c + const Offset(-15, -13), 4, paint);
    canvas.drawCircle(c + const Offset(-9, -17), 4, paint);
    canvas.drawCircle(c + const Offset(15, 13), 4, paint);
    canvas.drawCircle(c + const Offset(9, 17), 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DogGoWeb {
  static const teal = Color(0xFF009C8C);
  static const tealDeep = Color(0xFF087E73);
  static const tealLight = Color(0xFFD9F5EF);

  static const purple = Color(0xFF7156C8);
  static const purpleLight = Color(0xFFEDE7FA);

  static const orange = Color(0xFFFFA726);
  static const orangeLight = Color(0xFFFFF1D9);

  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFE5F8ED);

  static const rose = Color(0xFFEF4444);
  static const roseLight = Color(0xFFFEEEEE);

  static const bg = Color(0xFFF5F0E8);
  static const cream = Color(0xFFFFF4E8);
  static const card = Colors.white;
  static const ink = Color(0xFF202033);
  static const muted = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E1DA);

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