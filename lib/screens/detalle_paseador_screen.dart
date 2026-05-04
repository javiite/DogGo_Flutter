import 'package:flutter/material.dart';

import 'crear_paseo_screen.dart';

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

class DetallePaseadorScreen extends StatelessWidget {
  final Map<String, dynamic> paseador;

  const DetallePaseadorScreen({
    super.key,
    required this.paseador,
  });

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
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

  Map<String, dynamic> _usuario() {
    return _mapaSeguro(
      _valor(
        paseador,
        [
          'usuario',
          'Usuario',
          'user',
          'User',
          'datosUsuario',
          'DatosUsuario',
        ],
      ),
    );
  }

  int? _idPaseador() {
    final valor = _valor(
      paseador,
      [
        'id',
        'Id',
        'paseadorId',
        'PaseadorId',
        'idPaseador',
        'IdPaseador',
      ],
    );

    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '');
  }

  String _nombrePaseador() {
    final usuario = _usuario();

    final nombreCompleto = _textoSeguro(
      _valor(
        paseador,
        [
          'nombreCompleto',
          'NombreCompleto',
          'paseadorNombreCompleto',
          'PaseadorNombreCompleto',
        ],
      ),
      '',
    );

    if (nombreCompleto.isNotEmpty) return nombreCompleto;

    final nombre = _textoSeguro(
      _valor(
            paseador,
            [
              'nombre',
              'Nombre',
              'paseadorNombre',
              'PaseadorNombre',
              'nombrePaseador',
              'NombrePaseador',
            ],
          ) ??
          _valor(
            usuario,
            [
              'nombre',
              'Nombre',
              'name',
              'Name',
            ],
          ),
      '',
    );

    final apellido = _textoSeguro(
      _valor(
            paseador,
            [
              'apellido',
              'Apellido',
              'paseadorApellido',
              'PaseadorApellido',
              'apellidoPaseador',
              'ApellidoPaseador',
            ],
          ) ??
          _valor(
            usuario,
            [
              'apellido',
              'Apellido',
              'lastName',
              'LastName',
            ],
          ),
      '',
    );

    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? 'Sin dato' : completo;
  }

  String _emailPaseador() {
    final usuario = _usuario();

    return _textoSeguro(
      _valor(
            paseador,
            [
              'email',
              'Email',
              'correo',
              'Correo',
              'paseadorEmail',
              'PaseadorEmail',
            ],
          ) ??
          _valor(
            usuario,
            [
              'email',
              'Email',
              'correo',
              'Correo',
            ],
          ),
      '',
    );
  }

  String _descripcion() {
    return _textoSeguro(
      _valor(
        paseador,
        [
          'descripcion',
          'Descripcion',
          'descripción',
          'bio',
          'Bio',
          'presentacion',
          'Presentacion',
        ],
      ),
      'Sin descripción',
    );
  }

  String _zona() {
    return _textoSeguro(
      _valor(
        paseador,
        [
          'zonaServicio',
          'ZonaServicio',
          'zona',
          'Zona',
          'zonas',
          'Zonas',
          'ubicacion',
          'Ubicacion',
        ],
      ),
      'Sin zona',
    );
  }

  String _fotoUrl() {
    final usuario = _usuario();

    return _textoSeguro(
      _valor(
            paseador,
            [
              'fotoUrl',
              'FotoUrl',
              'fotoPerfilUrl',
              'FotoPerfilUrl',
              'imagenUrl',
              'ImagenUrl',
            ],
          ) ??
          _valor(
            usuario,
            [
              'fotoUrl',
              'FotoUrl',
              'fotoPerfilUrl',
              'FotoPerfilUrl',
              'imagenUrl',
              'ImagenUrl',
            ],
          ),
      '',
    );
  }

  String _tarifaTexto() {
    final tarifa = _valor(
      paseador,
      [
        'tarifaPorHora',
        'TarifaPorHora',
        'tarifa',
        'Tarifa',
        'precioHora',
        'PrecioHora',
      ],
    );

    if (tarifa == null) return 'Tarifa no disponible';

    final numero = double.tryParse(tarifa.toString());

    if (numero == null) return '\$${tarifa.toString()} / hora';

    return '\$${numero.toStringAsFixed(2)} / hora';
  }

  String _calificacionTexto() {
    final calificacion = _valor(
      paseador,
      [
        'calificacionPromedio',
        'CalificacionPromedio',
        'rating',
        'Rating',
        'calificacion',
        'Calificacion',
      ],
    );

    if (calificacion == null) return 'Sin calificación';

    final numero = double.tryParse(calificacion.toString());

    if (numero == null) return '⭐ ${calificacion.toString()}';

    return '⭐ ${numero.toStringAsFixed(1)}';
  }

  String _experienciaTexto() {
    final experiencia = _valor(
      paseador,
      [
        'experienciaAnios',
        'ExperienciaAnios',
        'experienciaAños',
        'ExperienciaAños',
        'experiencia',
        'Experiencia',
      ],
    );

    if (experiencia == null) return 'Sin experiencia';

    return '$experiencia año(s) de experiencia';
  }

  bool _disponible() {
    final valor = _valor(
      paseador,
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

  Map<String, dynamic> _paseadorNormalizado() {
    final normalizado = Map<String, dynamic>.from(paseador);
    final id = _idPaseador();

    if (id != null) {
      normalizado['id'] = id;
      normalizado['paseadorId'] = id;
    }

    normalizado['nombre'] = _nombrePaseador();
    normalizado['email'] = _emailPaseador();
    normalizado['descripcion'] = _descripcion();
    normalizado['zonaServicio'] = _zona();
    normalizado['fotoUrl'] = _fotoUrl();
    normalizado['disponible'] = _disponible();

    normalizado['tarifaPorHora'] = _valor(
      paseador,
      [
        'tarifaPorHora',
        'TarifaPorHora',
        'tarifa',
        'Tarifa',
        'precioHora',
        'PrecioHora',
      ],
    );

    normalizado['calificacionPromedio'] = _valor(
      paseador,
      [
        'calificacionPromedio',
        'CalificacionPromedio',
        'rating',
        'Rating',
        'calificacion',
        'Calificacion',
      ],
    );

    normalizado['experienciaAnios'] = _valor(
      paseador,
      [
        'experienciaAnios',
        'ExperienciaAnios',
        'experienciaAños',
        'ExperienciaAños',
        'experiencia',
        'Experiencia',
      ],
    );

    return normalizado;
  }

  bool _fotoEsUrlAbsoluta(String fotoUrl) {
    return fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _nombrePaseador();
    final descripcion = _descripcion();
    final tarifa = _tarifaTexto();
    final rating = _calificacionTexto();
    final experiencia = _experienciaTexto();
    final zona = _zona();
    final disponible = _disponible();
    final fotoUrl = _fotoUrl();
    final email = _emailPaseador();

    return Scaffold(
      backgroundColor: G.ink0,
      appBar: AppBar(
        backgroundColor: G.ink0,
        foregroundColor: G.ink6,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Detalle del paseador', style: G.h3(G.ink6)),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
        children: [
          _buildHero(
            nombre: nombre,
            email: email,
            fotoUrl: fotoUrl,
            rating: rating,
            tarifa: tarifa,
            experiencia: experiencia,
            disponible: disponible,
          ),
          const SizedBox(height: 16),
          _DetailCard(
            titulo: 'Descripción',
            icono: Icons.description_outlined,
            child: Text(
              descripcion,
              style: G.body(G.ink5).copyWith(height: 1.35),
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            titulo: 'Zona de servicio',
            icono: Icons.location_on_outlined,
            child: Text(
              zona,
              style: G.h3(G.ink6).copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            titulo: 'Información',
            icono: Icons.info_outline_rounded,
            child: Column(
              children: [
                _InfoRow(
                  icono: Icons.payments_outlined,
                  titulo: 'Tarifa',
                  valor: tarifa,
                ),
                _InfoRow(
                  icono: Icons.star_border_rounded,
                  titulo: 'Calificación',
                  valor: rating,
                ),
                _InfoRow(
                  icono: Icons.work_outline_rounded,
                  titulo: 'Experiencia',
                  valor: experiencia,
                ),
                _InfoRow(
                  icono: Icons.check_circle_outline_rounded,
                  titulo: 'Disponibilidad',
                  valor: disponible ? 'Disponible' : 'No disponible',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: disponible
                  ? () async {
                      final creado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CrearPaseoScreen(
                            paseador: _paseadorNormalizado(),
                          ),
                        ),
                      );

                      if (!context.mounted) return;

                      if (creado == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Paseo creado correctamente.'),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.directions_walk_rounded),
              label: const Text('Solicitar paseo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: G.brand,
                disabledBackgroundColor: G.brand.withOpacity(.45),
                foregroundColor: G.white,
                shape: const RoundedRectangleBorder(borderRadius: G.r24),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero({
    required String nombre,
    required String email,
    required String fotoUrl,
    required String rating,
    required String tarifa,
    required String experiencia,
    required bool disponible,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: G.white,
        borderRadius: G.r24,
        boxShadow: G.shadow1,
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: G.brandPale,
              borderRadius: G.r24,
            ),
            clipBehavior: Clip.antiAlias,
            child: _fotoEsUrlAbsoluta(fotoUrl)
                ? Image.network(
                    fotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.person,
                        size: 52,
                        color: G.brand,
                      );
                    },
                  )
                : const Icon(
                    Icons.person,
                    size: 52,
                    color: G.brand,
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: G.h2(G.ink6).copyWith(fontSize: 25),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: G.body(G.ink4, size: 13).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            rating,
            style: G.label(G.ink4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(texto: tarifa, fondo: G.brandPale, color: G.brandDark),
              _InfoChip(texto: experiencia, fondo: G.goldPale, color: G.gold),
              _InfoChip(
                texto: disponible ? 'Disponible' : 'No disponible',
                fondo: disponible ? G.sagePale : G.clayLight,
                color: disponible ? G.sage : G.clay,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;

  const _DetailCard({
    required this.titulo,
    required this.icono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: G.white,
        borderRadius: G.r20,
        boxShadow: G.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: G.brand, size: 21),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: G.h3(G.ink6).copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;

  const _InfoChip({
    required this.texto,
    required this.fondo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: fondo, borderRadius: G.r12),
      child: Text(
        texto,
        style: G.label(color).copyWith(fontSize: 12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _InfoRow({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: G.ink4, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: G.label(G.ink4).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: G.h3(G.ink6).copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
