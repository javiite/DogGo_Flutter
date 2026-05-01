import 'package:flutter/material.dart';
import 'crear_paseo_screen.dart';

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

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

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

    if (numero == null) {
      return '\$${tarifa.toString()} / hora';
    }

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

    if (numero == null) {
      return '⭐ ${calificacion.toString()}';
    }

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

    if (texto == null || texto.isEmpty || texto == 'null') {
      return true;
    }

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
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Detalle del paseador'),
      ),
      body: ListView(
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
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDE3),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _fotoEsUrlAbsoluta(fotoUrl)
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.person,
                              size: 48,
                              color: Color(0xFF6B7280),
                            );
                          },
                        )
                      : const Icon(
                          Icons.person,
                          size: 48,
                          color: Color(0xFF6B7280),
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  rating,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _InfoChip(
                      texto: tarifa,
                      fondo: const Color(0xFFDDF4F1),
                      color: const Color(0xFF14A89A),
                    ),
                    _InfoChip(
                      texto: experiencia,
                      fondo: const Color(0xFFF6ECD8),
                      color: const Color(0xFFB57A4B),
                    ),
                    _InfoChip(
                      texto: disponible ? 'Disponible' : 'No disponible',
                      fondo: disponible
                          ? const Color(0xFFE6F6E9)
                          : const Color(0xFFFBE4E6),
                      color: disponible
                          ? const Color(0xFF4AA564)
                          : const Color(0xFFE56B6F),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            titulo: 'Descripción',
            icono: Icons.description_outlined,
            child: Text(
              descripcion,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            titulo: 'Zona de servicio',
            icono: Icons.location_on_outlined,
            child: Text(
              zona,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF25324A),
                fontWeight: FontWeight.w700,
              ),
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
            height: 50,
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
                backgroundColor: const Color(0xFF14A89A),
                disabledBackgroundColor:
                    const Color(0xFF14A89A).withOpacity(0.45),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: const Color(0xFF14A89A),
                size: 21,
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
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
          Icon(
            icono,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Color(0xFF25324A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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