import 'package:flutter/material.dart';

import '../services/paseadores_service.dart';
import 'detalle_paseador_screen.dart';

class G {
  static const brand = Color(0xFF0D9E7E);
  static const brandPale = Color(0xFFE8F8F3);
  static const brandDark = Color(0xFF0A7A62);
  static const clay = Color(0xFFD4694A);
  static const clayLight = Color(0xFFFAEDE8);
  static const sage = Color(0xFF5B8C5A);
  static const sagePale = Color(0xFFECF4EB);
  static const gold = Color(0xFFCB9B3B);
  static const goldPale = Color(0xFFFBF3E0);
  static const plum = Color(0xFF6B4E8A);
  static const plumPale = Color(0xFFF2EDF8);
  static const ink0 = Color(0xFFFAF7F2);
  static const ink1 = Color(0xFFF3EFE8);
  static const ink2 = Color(0xFFE8E2D9);
  static const ink3 = Color(0xFFC8C0B4);
  static const ink4 = Color(0xFF8C8278);
  static const ink5 = Color(0xFF4A4540);
  static const ink6 = Color(0xFF1E1A16);
  static const white = Color(0xFFFFFFFF);

  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  static const shadow1 = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static TextStyle h2(Color c) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: c,
        letterSpacing: -.4,
        height: 1.15,
      );

  static TextStyle h3(Color c) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: c,
        letterSpacing: -.2,
      );

  static TextStyle body(Color c, {double size = 13.5}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w400, color: c);

  static TextStyle label(Color c, {double size = 12}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: c,
        letterSpacing: .3,
      );
}

class PaseadoresScreen extends StatefulWidget {
  const PaseadoresScreen({super.key});

  @override
  State<PaseadoresScreen> createState() => _PaseadoresScreenState();
}

class _PaseadoresScreenState extends State<PaseadoresScreen> {
  bool _cargando = true;
  String? _error;
  List<dynamic> _paseadores = [];

  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarPaseadores();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPaseadores() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PaseadoresService.obtenerPaseadores();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _paseadores = result['data'] is List ? result['data'] : [];
          _cargando = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Error al cargar.';
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

  String _ts2(dynamic v, [String fb = 'Sin dato']) {
    if (v == null) return fb;
    final t = v.toString().trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? fb : t;
  }

  Map<String, dynamic> _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  dynamic _val(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  Map<String, dynamic> _usuario(Map<String, dynamic> p) =>
      _map(_val(p, ['usuario', 'Usuario', 'user', 'User']));

  String _nombre(Map<String, dynamic> p) {
    final u = _usuario(p);

    final n = _ts2(
      _val(p, [
            'nombre',
            'Nombre',
            'paseadorNombre',
            'PaseadorNombre',
          ]) ??
          _val(u, ['nombre', 'Nombre']),
      '',
    );

    final a = _ts2(
      _val(p, [
            'apellido',
            'Apellido',
            'paseadorApellido',
            'PaseadorApellido',
          ]) ??
          _val(u, ['apellido', 'Apellido']),
      '',
    );

    final c = '$n $a'.trim();

    return c.isEmpty ? 'Sin dato' : c;
  }

  String _descripcion(Map<String, dynamic> p) => _ts2(
        _val(p, ['descripcion', 'Descripcion', 'bio', 'Bio']),
        'Sin descripción',
      );

  String _zona(Map<String, dynamic> p) => _ts2(
        _val(p, ['zonaServicio', 'ZonaServicio', 'zona', 'Zona']),
        'Sin zona',
      );

  String _foto(Map<String, dynamic> p) {
    final u = _usuario(p);

    return _ts2(
      _val(p, ['fotoUrl', 'FotoUrl', 'imagenUrl', 'ImagenUrl']) ??
          _val(u, ['fotoUrl', 'FotoUrl', 'imagenUrl', 'ImagenUrl']),
      '',
    );
  }

  String _tarifa(Map<String, dynamic> p) {
    final t = _val(p, [
      'tarifaPorHora',
      'TarifaPorHora',
      'tarifa',
      'Tarifa',
    ]);

    if (t == null) return 'Tarifa n/d';

    final n = double.tryParse(t.toString());

    return n == null ? '\$$t/h' : '\$${n.toStringAsFixed(2)}/h';
  }

  String _rating(Map<String, dynamic> p) {
    final c = _val(p, [
      'calificacionPromedio',
      'CalificacionPromedio',
      'rating',
      'Rating',
    ]);

    if (c == null) return 'Sin cal.';

    final n = double.tryParse(c.toString());

    return n == null ? '⭐ $c' : '⭐ ${n.toStringAsFixed(1)}';
  }

  String _exp(Map<String, dynamic> p) {
    final e = _val(p, [
      'experienciaAnios',
      'ExperienciaAnios',
      'experiencia',
      'Experiencia',
    ]);

    return e == null ? 'Sin exp.' : '$e año(s)';
  }

  bool _disponible(Map<String, dynamic> p) {
    final v = _val(p, ['disponible', 'Disponible', 'activo', 'Activo']);

    if (v is bool) return v;

    final t = v?.toString().trim().toLowerCase();

    if (t == null || t.isEmpty || t == 'null') return true;

    return t == 'true' || t == '1' || t == 'si' || t == 'sí';
  }

  List<String> _zonas(Map<String, dynamic> p) {
    final z = _zona(p);

    if (z == 'Sin zona') return [z];

    final s = z
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return s.isEmpty ? [z] : s;
  }

  Map<String, dynamic> _normalizar(Map<String, dynamic> p) {
    final n = Map<String, dynamic>.from(p);

    n['nombre'] = _nombre(p);
    n['descripcion'] = _descripcion(p);
    n['zonaServicio'] = _zona(p);
    n['fotoUrl'] = _foto(p);
    n['disponible'] = _disponible(p);
    n['tarifaPorHora'] = _val(p, [
      'tarifaPorHora',
      'TarifaPorHora',
      'tarifa',
      'Tarifa',
    ]);
    n['calificacionPromedio'] = _val(p, [
      'calificacionPromedio',
      'CalificacionPromedio',
      'rating',
      'Rating',
    ]);
    n['experienciaAnios'] = _val(p, [
      'experienciaAnios',
      'ExperienciaAnios',
      'experiencia',
      'Experiencia',
    ]);

    return n;
  }

  List<dynamic> get _filtrados {
    final q = _busquedaController.text.trim().toLowerCase();

    if (q.isEmpty) return _paseadores;

    return _paseadores.where((item) {
      final p = _map(item);

      return [
        _nombre(p),
        _descripcion(p),
        _zona(p),
      ].join(' ').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;

    return Scaffold(
      backgroundColor: G.ink0,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            backgroundColor: G.ink0,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: G.ink6,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Paseadores', style: G.h2(G.ink6)),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: _cargarPaseadores,
                icon: const Icon(Icons.refresh_rounded, color: G.ink6),
              ),
            ],
          ),
        ],
        body: _cargando
            ? const Center(child: CircularProgressIndicator(color: G.brand))
            : _error != null
                ? _buildError()
                : Column(
                    children: [
                      _buildHeader(lista.length),
                      Expanded(
                        child: lista.isEmpty
                            ? _buildVacio()
                            : _buildLista(lista),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: G.ink0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$count paseadores encontrados', style: G.label(G.ink4)),
          const SizedBox(height: 10),
          Container(
            height: 48,
            decoration: const BoxDecoration(
              color: G.white,
              borderRadius: G.r16,
              boxShadow: G.shadow1,
            ),
            child: TextField(
              controller: _busquedaController,
              onChanged: (_) => setState(() {}),
              style: G.body(G.ink6),
              decoration: InputDecoration(
                hintText: 'Buscar paseador o zona...',
                hintStyle: G.body(G.ink3),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: G.ink4,
                  size: 20,
                ),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: G.ink4,
                        ),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<dynamic> lista) {
    return RefreshIndicator(
      color: G.brand,
      onRefresh: _cargarPaseadores,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: lista.length,
        itemBuilder: (_, i) {
          final p = _map(lista[i]);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PaseadorCard(
              nombre: _nombre(p),
              precio: _tarifa(p),
              descripcion: _descripcion(p),
              zonas: _zonas(p),
              experiencia: _exp(p),
              disponible: _disponible(p),
              rating: _rating(p),
              fotoUrl: _foto(p),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetallePaseadorScreen(
                    paseador: _normalizar(p),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: G.clay),
            const SizedBox(height: 14),
            Text(_error!, textAlign: TextAlign.center, style: G.h3(G.ink6)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarPaseadores,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: G.brand,
                foregroundColor: G.white,
                shape: const RoundedRectangleBorder(borderRadius: G.r12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search_rounded, size: 72, color: G.ink3),
          const SizedBox(height: 14),
          Text('No se encontraron paseadores', style: G.h3(G.ink6)),
          const SizedBox(height: 6),
          Text('Prueba con otra búsqueda', style: G.body(G.ink4)),
        ],
      ),
    );
  }
}

class _PaseadorCard extends StatelessWidget {
  final String nombre;
  final String precio;
  final String descripcion;
  final String experiencia;
  final String rating;
  final String fotoUrl;
  final List<String> zonas;
  final bool disponible;
  final VoidCallback onTap;

  const _PaseadorCard({
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.zonas,
    required this.experiencia,
    required this.disponible,
    required this.rating,
    required this.fotoUrl,
    required this.onTap,
  });

  bool get _tieneFoto =>
      fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: G.white,
          borderRadius: G.r20,
          boxShadow: G.shadow1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: G.brandPale,
                      borderRadius: G.r16,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _tieneFoto
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: G.brand,
                              size: 28,
                            ),
                          )
                        : const Icon(Icons.person, color: G.brand, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, style: G.h3(G.ink6).copyWith(fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(precio, style: G.label(G.ink4)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '★★★★★',
                        style: TextStyle(color: G.gold, fontSize: 12),
                      ),
                      Text(
                        rating,
                        style: G.label(G.ink4).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  descripcion,
                  style: G.body(G.ink5).copyWith(height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...zonas.map((z) => _Chip(z, G.brandDark, G.brandPale)),
                  _Chip(experiencia, G.gold, G.goldPale),
                  _Chip(
                    disponible ? 'Disponible' : 'Ocupado',
                    disponible ? G.sage : G.clay,
                    disponible ? G.sagePale : G.clayLight,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _OutBtn('Ver perfil', onTap)),
                  const SizedBox(width: 10),
                  Expanded(child: _FillBtn('Solicitar', onTap)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _Chip(this.label, this.fg, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: G.r8),
      child: Text(label, style: G.label(fg).copyWith(fontSize: 10.5)),
    );
  }
}

class _OutBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: G.brand,
        side: const BorderSide(color: G.brand, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: G.r12),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: G.label(G.brand).copyWith(fontSize: 13)),
    );
  }
}

class _FillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FillBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: G.brand,
        foregroundColor: G.white,
        shape: const RoundedRectangleBorder(borderRadius: G.r12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
      ),
      child: Text(label, style: G.label(G.white).copyWith(fontSize: 13)),
    );
  }
}
