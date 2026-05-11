import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'crear_paseo_screen.dart';

class DetallePaseadorScreen extends StatefulWidget {
  final Map<String, dynamic> paseador;

  const DetallePaseadorScreen({
    super.key,
    required this.paseador,
  });

  @override
  State<DetallePaseadorScreen> createState() => _DetallePaseadorScreenState();
}

class _DetallePaseadorScreenState extends State<DetallePaseadorScreen> {
  bool _cargandoReviews = false;
  String? _baseUrl;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = url;
    });

    await _cargarReviews();
  }

  Future<void> _cargarReviews() async {
    final id = _paseadorId();

    if (id == null) return;

    setState(() {
      _cargandoReviews = true;
    });

    final endpoints = [
      '/api/paseadores/$id/calificaciones',
      '/api/Paseadores/$id/calificaciones',
      '/api/calificaciones/paseador/$id',
      '/api/Calificaciones/paseador/$id',
      '/api/paseadores/$id/reviews',
      '/api/Paseadores/$id/reviews',
    ];

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);
        final statusCode = respuesta['statusCode'];

        if (statusCode is int && statusCode >= 200 && statusCode < 300) {
          if (!mounted) return;

          setState(() {
            _reviews = _normalizarLista(respuesta);
            _cargandoReviews = false;
          });
          return;
        }
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;

    setState(() {
      _cargandoReviews = false;
    });
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final body = respuesta['body'];
      datos = body ?? respuesta;

      if (datos is Map) {
        datos = datos['data'] ??
            datos['calificaciones'] ??
            datos['reviews'] ??
            datos['resenas'] ??
            datos['reseñas'] ??
            datos['items'] ??
            datos['resultado'] ??
            datos['result'] ??
            datos['value'];
      }
    }

    if (datos is! List) return [];

    return datos
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Map<String, dynamic> _map(dynamic valor) {
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) return Map<String, dynamic>.from(valor);
    return {};
  }

  dynamic _val(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) return mapa[key];
    }

    return null;
  }

  String _texto(dynamic valor, {String fallback = 'Sin dato'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;

    return texto;
  }

  int? _intValor(dynamic valor) {
    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '');
  }

  double _doubleValor(dynamic valor, {double fallback = 0}) {
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? fallback;
  }

  String _urlPublica(dynamic valor) {
    final raw = valor?.toString().trim();

    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return '';

    if (raw.startsWith('/')) return '$base$raw';

    return '$base/$raw';
  }

  String _nombre() {
    return _texto(
      _val(
        widget.paseador,
        [
          'nombreCompleto',
          'NombreCompleto',
          'nombre',
          'Nombre',
          'paseadorNombre',
          'PaseadorNombre',
        ],
      ),
      fallback: 'Paseador DogGo',
    );
  }

  String _email() {
    return _texto(
      _val(
        widget.paseador,
        [
          'email',
          'Email',
          'correo',
          'Correo',
          'paseadorEmail',
          'PaseadorEmail',
        ],
      ),
      fallback: '',
    );
  }

  String _descripcion() {
    return _texto(
      _val(
        widget.paseador,
        [
          'descripcion',
          'Descripcion',
          'bio',
          'Bio',
          'presentacion',
          'Presentacion',
        ],
      ),
      fallback: 'Sin descripción registrada.',
    );
  }

  String _zona() {
    return _texto(
      _val(
        widget.paseador,
        [
          'zonaServicio',
          'ZonaServicio',
          'zona',
          'Zona',
          'zonas',
          'Zonas',
        ],
      ),
      fallback: 'Sin zona',
    );
  }

  List<String> _zonas() {
    final zona = _zona();

    if (zona == 'Sin zona') return [zona];

    final lista = zona
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return lista.isEmpty ? [zona] : lista;
  }

  String _foto() {
    return _urlPublica(
      _val(
        widget.paseador,
        [
          'fotoUrl',
          'FotoUrl',
          'imagenUrl',
          'ImagenUrl',
          'fotoPerfilUrl',
          'FotoPerfilUrl',
        ],
      ),
    );
  }

  int? _paseadorId() {
    return _intValor(
      _val(
        widget.paseador,
        [
          'id',
          'Id',
          'paseadorId',
          'PaseadorId',
          'idPaseador',
          'IdPaseador',
        ],
      ),
    );
  }

  double _tarifaNumero() {
    return _doubleValor(
      _val(
        widget.paseador,
        [
          'tarifaPorHora',
          'TarifaPorHora',
          'tarifa',
          'Tarifa',
          'precioHora',
          'PrecioHora',
        ],
      ),
    );
  }

  String _tarifa() {
    return '\$${_tarifaNumero().toStringAsFixed(2)}';
  }

  double _ratingNumero() {
    return _doubleValor(
      _val(
        widget.paseador,
        [
          'calificacionPromedio',
          'CalificacionPromedio',
          'rating',
          'Rating',
          'calificacion',
          'Calificacion',
        ],
      ),
    );
  }

  String _rating() {
    final value = _ratingNumero();

    if (value <= 0) return '0.0';

    return value.toStringAsFixed(1);
  }

  int _experienciaNumero() {
    return _intValor(
          _val(
            widget.paseador,
            [
              'experienciaAnios',
              'ExperienciaAnios',
              'experienciaAños',
              'ExperienciaAños',
              'experiencia',
              'Experiencia',
            ],
          ),
        ) ??
        0;
  }

  String _experiencia() {
    final value = _experienciaNumero();

    if (value <= 0) return 'Sin experiencia';
    if (value == 1) return '1 año';

    return '$value años';
  }

  bool _disponible() {
    final valor = _val(
      widget.paseador,
      [
        'disponible',
        'Disponible',
        'estaDisponible',
        'EstaDisponible',
        'activo',
        'Activo',
      ],
    );

    if (valor is bool) return valor;

    final texto = valor?.toString().trim().toLowerCase();

    if (texto == null || texto.isEmpty || texto == 'null') return true;

    return texto == 'true' || texto == '1' || texto == 'si' || texto == 'sí';
  }

  Future<void> _solicitar() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPaseoScreen(
          paseador: widget.paseador,
        ),
      ),
    );

    if (!mounted) return;

    if (creado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paseo creado correctamente.'),
        ),
      );

      Navigator.pop(context, true);
    }
  }

  String _reviewAutor(Map<String, dynamic> review) {
    final duenio = _map(
      _val(
        review,
        [
          'duenio',
          'Dueño',
          'dueno',
          'Dueno',
          'usuario',
          'Usuario',
          'cliente',
          'Cliente',
        ],
      ),
    );

    return _texto(
      _val(
            review,
            [
              'duenioNombre',
              'DueñoNombre',
              'duenoNombre',
              'DuenoNombre',
              'clienteNombre',
              'ClienteNombre',
              'autor',
              'Autor',
            ],
          ) ??
          _val(
            duenio,
            [
              'nombre',
              'Nombre',
              'nombreCompleto',
              'NombreCompleto',
            ],
          ),
      fallback: 'Dueño DogGo',
    );
  }

  String _reviewComentario(Map<String, dynamic> review) {
    return _texto(
      _val(
        review,
        [
          'comentario',
          'Comentario',
          'resena',
          'Resena',
          'reseña',
          'Reseña',
          'mensaje',
          'Mensaje',
        ],
      ),
      fallback: 'Sin comentario escrito.',
    );
  }

  String _reviewPuntaje(Map<String, dynamic> review) {
    final value = _doubleValor(
      _val(review, ['puntaje', 'Puntaje', 'rating', 'Rating', 'calificacion']),
    );

    if (value <= 0) return '0.0';

    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final foto = _foto();
    final tieneFoto = foto.startsWith('http://') || foto.startsWith('https://');

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: BoxDecoration(
            color: DogGoTheme.cream.withOpacity(.96),
            border: Border(
              top: BorderSide(color: DogGoTheme.border.withOpacity(.75)),
            ),
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _disponible() ? _solicitar : null,
              icon: const Icon(Icons.directions_walk_rounded),
              label: Text('Solicitar paseo con ${_nombre()}'),
              style: DogGoTheme.primaryButton(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarReviews,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 108),
            children: [
              _TopBar(disponible: _disponible()),
              const SizedBox(height: 18),
              _HeroProfile(
                nombre: _nombre(),
                email: _email(),
                fotoUrl: foto,
                tieneFoto: tieneFoto,
                rating: _rating(),
                tarifa: _tarifa(),
                experiencia: _experiencia(),
                disponible: _disponible(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.payments_rounded,
                      value: _tarifa(),
                      label: 'por hora',
                      color: DogGoTheme.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.star_rounded,
                      value: _rating(),
                      label: 'rating',
                      color: DogGoTheme.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.workspace_premium_rounded,
                      value: '${_experienciaNumero()}',
                      label: 'años exp.',
                      color: DogGoTheme.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ReadyCard(disponible: _disponible()),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.description_rounded,
                title: 'Sobre el paseador',
                subtitle: 'Presentación profesional',
                child: Text(
                  _descripcion(),
                  style: DogGoTheme.body(
                    size: 14.5,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.location_on_rounded,
                title: 'Zona de servicio',
                subtitle: 'Áreas donde puede realizar paseos',
                color: DogGoTheme.purple,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _zonas()
                      .map(
                        (zona) => _SmallChip(
                          text: zona,
                          icon: Icons.location_on_rounded,
                          color: DogGoTheme.purple,
                          surface: DogGoTheme.purpleLight,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _ServiceDataCard(
                tarifa: '${_tarifa()} / hora',
                rating: _rating(),
                experiencia: _experiencia(),
                estado: _disponible() ? 'Disponible' : 'Ocupado',
              ),
              const SizedBox(height: 14),
              _ReviewsCard(
                cargando: _cargandoReviews,
                reviews: _reviews,
                autor: _reviewAutor,
                comentario: _reviewComentario,
                puntaje: _reviewPuntaje,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool disponible;

  const _TopBar({
    required this.disponible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          const DogGoLogo(size: 42),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: disponible ? DogGoTheme.greenLight : DogGoTheme.redLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  disponible
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                  color: disponible ? DogGoTheme.green : DogGoTheme.red,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Text(
                  disponible ? 'Disponible' : 'Ocupado',
                  style: DogGoTheme.body(
                    size: 12,
                    color: disponible ? DogGoTheme.green : DogGoTheme.red,
                    weight: FontWeight.w900,
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

class _HeroProfile extends StatelessWidget {
  final String nombre;
  final String email;
  final String fotoUrl;
  final bool tieneFoto;
  final String rating;
  final String tarifa;
  final String experiencia;
  final bool disponible;

  const _HeroProfile({
    required this.nombre,
    required this.email,
    required this.fotoUrl,
    required this.tieneFoto,
    required this.rating,
    required this.tarifa,
    required this.experiencia,
    required this.disponible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(32),
        boxShadow: DogGoTheme.softShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PERFIL DE PASEADOR',
                  style: DogGoTheme.body(
                    size: 12,
                    color: Colors.white.withOpacity(.86),
                    weight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Stack(
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withOpacity(.22),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: tieneFoto
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 56,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: disponible ? DogGoTheme.green : DogGoTheme.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        disponible ? Icons.check_rounded : Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                nombre,
                textAlign: TextAlign.center,
                style: DogGoTheme.title(
                  size: 31,
                  color: Colors.white,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: DogGoTheme.body(
                    size: 13,
                    color: Colors.white.withOpacity(.86),
                    weight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                alignment: WrapAlignment.center,
                children: [
                  _HeroPill(
                    icon: Icons.star_rounded,
                    text: '$rating rating',
                  ),
                  _HeroPill(
                    icon: Icons.attach_money_rounded,
                    text: '$tarifa / hora',
                  ),
                  _HeroPill(
                    icon: Icons.workspace_premium_rounded,
                    text: '$experiencia de experiencia',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(
            text,
            style: DogGoTheme.body(
              size: 12,
              color: Colors.white,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.title(size: 20),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.subtitle(size: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  final bool disponible;

  const _ReadyCard({
    required this.disponible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: disponible ? DogGoTheme.greenLight : DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: disponible
              ? DogGoTheme.green.withOpacity(.18)
              : DogGoTheme.red.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: disponible ? DogGoTheme.green : DogGoTheme.red,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              disponible ? Icons.verified_user_rounded : Icons.block_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disponible
                      ? 'Listo para recibir solicitudes'
                      : 'No disponible por ahora',
                  style: DogGoTheme.title(size: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  disponible
                      ? 'Puedes solicitar un paseo y revisar la información antes de confirmar.'
                      : 'El paseador aparece como ocupado o no disponible.',
                  style: DogGoTheme.subtitle(size: 12.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.color = DogGoTheme.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DogGoTheme.title(size: 19)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: DogGoTheme.subtitle(size: 12.5)),
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

class _ServiceDataCard extends StatelessWidget {
  final String tarifa;
  final String rating;
  final String experiencia;
  final String estado;

  const _ServiceDataCard({
    required this.tarifa,
    required this.rating,
    required this.experiencia,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.fact_check_rounded,
      title: 'Datos del servicio',
      subtitle: 'Información clave antes de solicitar',
      color: DogGoTheme.orange,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.18,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _ServiceMiniCard(
            icon: Icons.payments_rounded,
            label: 'Tarifa',
            value: tarifa,
            color: DogGoTheme.teal,
          ),
          _ServiceMiniCard(
            icon: Icons.star_rounded,
            label: 'Calificación',
            value: rating,
            color: DogGoTheme.orange,
          ),
          _ServiceMiniCard(
            icon: Icons.work_rounded,
            label: 'Experiencia',
            value: experiencia,
            color: DogGoTheme.purple,
          ),
          _ServiceMiniCard(
            icon: Icons.check_circle_rounded,
            label: 'Estado',
            value: estado,
            color: DogGoTheme.green,
          ),
        ],
      ),
    );
  }
}

class _ServiceMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ServiceMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const Spacer(),
          Text(
            label,
            style: DogGoTheme.subtitle(size: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 14,
              color: DogGoTheme.ink,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  final bool cargando;
  final List<Map<String, dynamic>> reviews;
  final String Function(Map<String, dynamic>) autor;
  final String Function(Map<String, dynamic>) comentario;
  final String Function(Map<String, dynamic>) puntaje;

  const _ReviewsCard({
    required this.cargando,
    required this.reviews,
    required this.autor,
    required this.comentario,
    required this.puntaje,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.rate_review_rounded,
      title: 'Opiniones y reseñas',
      subtitle: 'Comentarios de otros dueños',
      color: DogGoTheme.orange,
      child: cargando
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          : reviews.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DogGoTheme.cream2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DogGoTheme.border),
                  ),
                  child: Text(
                    'Todavía no hay reseñas visibles para este paseador.',
                    textAlign: TextAlign.center,
                    style: DogGoTheme.subtitle(size: 13),
                  ),
                )
              : Column(
                  children: reviews.take(5).map((review) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DogGoTheme.cream2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DogGoTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: DogGoTheme.orangeLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: DogGoTheme.orange,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        autor(review),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: DogGoTheme.body(
                                          size: 13.5,
                                          color: DogGoTheme.ink,
                                          weight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      puntaje(review),
                                      style: DogGoTheme.body(
                                        size: 12.5,
                                        color: DogGoTheme.orange,
                                        weight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  comentario(review),
                                  style: DogGoTheme.subtitle(size: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color surface;

  const _SmallChip({
    required this.text,
    required this.icon,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: DogGoTheme.body(
              size: 11,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
