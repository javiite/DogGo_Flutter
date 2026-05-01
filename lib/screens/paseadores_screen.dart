import 'package:flutter/material.dart';
import '../services/paseadores_service.dart';
import 'detalle_paseador_screen.dart';

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
        final data = result['data'];

        setState(() {
          _paseadores = data is List ? data : [];
          _cargando = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString() ??
              'No se pudieron obtener los paseadores.';
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

  Map<String, dynamic> _mapaSeguro(dynamic valor) {
    if (valor is Map<String, dynamic>) {
      return valor;
    }

    if (valor is Map) {
      return Map<String, dynamic>.from(valor);
    }

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

  Map<String, dynamic> _usuarioDe(Map<String, dynamic> paseador) {
    final usuario = _valor(
      paseador,
      [
        'usuario',
        'Usuario',
        'user',
        'User',
        'datosUsuario',
        'DatosUsuario',
      ],
    );

    return _mapaSeguro(usuario);
  }

  String _nombrePaseador(Map<String, dynamic> paseador) {
    final usuario = _usuarioDe(paseador);

    final nombreDirecto = _valor(
      paseador,
      [
        'nombreCompleto',
        'NombreCompleto',
        'paseadorNombreCompleto',
        'nombrePaseadorCompleto',
      ],
    );

    final nombreDirectoTexto = _textoSeguro(nombreDirecto, '');

    if (nombreDirectoTexto.isNotEmpty) {
      return nombreDirectoTexto;
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

  String _emailPaseador(Map<String, dynamic> paseador) {
    final usuario = _usuarioDe(paseador);

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

  String _descripcion(Map<String, dynamic> paseador) {
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

  String _zona(Map<String, dynamic> paseador) {
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

  String _fotoUrl(Map<String, dynamic> paseador) {
    final usuario = _usuarioDe(paseador);

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

  String _tarifaTexto(Map<String, dynamic> paseador) {
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

  String _calificacionTexto(Map<String, dynamic> paseador) {
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

  String _experienciaTexto(Map<String, dynamic> paseador) {
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

    return '$experiencia año(s) exp.';
  }

  bool _disponible(Map<String, dynamic> paseador) {
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

  List<String> _zonasLista(Map<String, dynamic> paseador) {
    final zona = _zona(paseador);

    if (zona == 'Sin zona') {
      return [zona];
    }

    final separadas = zona
        .split(',')
        .map((z) => z.trim())
        .where((z) => z.isNotEmpty)
        .toList();

    return separadas.isEmpty ? [zona] : separadas;
  }

  Map<String, dynamic> _normalizarPaseadorParaDetalle(
    Map<String, dynamic> paseador,
  ) {
    final normalizado = Map<String, dynamic>.from(paseador);

    normalizado['nombre'] = _nombrePaseador(paseador);
    normalizado['email'] = _emailPaseador(paseador);
    normalizado['descripcion'] = _descripcion(paseador);
    normalizado['zonaServicio'] = _zona(paseador);
    normalizado['fotoUrl'] = _fotoUrl(paseador);
    normalizado['disponible'] = _disponible(paseador);

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

    normalizado['tarifaPorHora'] = tarifa;
    normalizado['calificacionPromedio'] = calificacion;
    normalizado['experienciaAnios'] = experiencia;

    return normalizado;
  }

  List<dynamic> get _paseadoresFiltrados {
    final texto = _busquedaController.text.trim().toLowerCase();

    if (texto.isEmpty) return _paseadores;

    return _paseadores.where((item) {
      final paseador = _mapaSeguro(item);

      final nombre = _nombrePaseador(paseador).toLowerCase();
      final descripcion = _descripcion(paseador).toLowerCase();
      final zona = _zona(paseador).toLowerCase();
      final email = _emailPaseador(paseador).toLowerCase();

      return nombre.contains(texto) ||
          descripcion.contains(texto) ||
          zona.contains(texto) ||
          email.contains(texto);
    }).toList();
  }

  Future<void> _abrirDetalle(Map<String, dynamic> paseador) async {
    final paseadorNormalizado = _normalizarPaseadorParaDetalle(paseador);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePaseadorScreen(
          paseador: paseadorNormalizado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _paseadoresFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.pets, color: Color(0xFF14A89A)),
            SizedBox(width: 8),
            Text(
              'DogGo',
              style: TextStyle(
                color: Color(0xFF25324A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Volver',
              style: TextStyle(color: Color(0xFF25324A)),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                          onPressed: _cargarPaseadores,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4EDE3),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE7E0D5)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ENCUENTRA TU PASEADOR',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF14A89A),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Paseadores disponibles',
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.1,
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Se encontraron ${lista.length} paseadores.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _busquedaController,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre, zona o descripción',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  _busquedaController.text.trim().isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _busquedaController.clear();
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: lista.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_search,
                                      size: 76,
                                      color: Color(0xFFB8B3AA),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'No se encontraron paseadores',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF25324A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Prueba con otra búsqueda o vuelve a cargar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _cargarPaseadores,
                                      child: const Text('Recargar'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarPaseadores,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(18),
                                itemCount: lista.length,
                                itemBuilder: (context, index) {
                                  final paseador = _mapaSeguro(lista[index]);

                                  final nombre = _nombrePaseador(paseador);
                                  final tarifa = _tarifaTexto(paseador);
                                  final descripcion = _descripcion(paseador);
                                  final zonas = _zonasLista(paseador);
                                  final experiencia =
                                      _experienciaTexto(paseador);
                                  final rating =
                                      _calificacionTexto(paseador);
                                  final disponible = _disponible(paseador);
                                  final fotoUrl = _fotoUrl(paseador);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _PaseadorCard(
                                      nombre: nombre,
                                      precio: tarifa,
                                      descripcion: descripcion,
                                      zonas: zonas,
                                      experiencia: experiencia,
                                      disponible: disponible,
                                      rating: rating,
                                      fotoUrl: fotoUrl,
                                      onVerPerfil: () async {
                                        await _abrirDetalle(paseador);
                                      },
                                      onSolicitar: () async {
                                        await _abrirDetalle(paseador);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _PaseadorCard extends StatelessWidget {
  final String nombre;
  final String precio;
  final String descripcion;
  final List<String> zonas;
  final String experiencia;
  final bool disponible;
  final String rating;
  final String fotoUrl;
  final VoidCallback onVerPerfil;
  final VoidCallback onSolicitar;

  const _PaseadorCard({
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.zonas,
    required this.experiencia,
    required this.disponible,
    required this.rating,
    required this.fotoUrl,
    required this.onVerPerfil,
    required this.onSolicitar,
  });

  bool get _tieneFotoAbsoluta {
    return fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E2D9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDE3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _tieneFotoAbsoluta
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF6B7280),
                                size: 30,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF6B7280),
                            size: 30,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF25324A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        precio,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...zonas.map(
                  (z) => _TagChip(
                    texto: z,
                    colorFondo: const Color(0xFFDDF4F1),
                    colorTexto: const Color(0xFF14A89A),
                  ),
                ),
                _TagChip(
                  texto: experiencia,
                  colorFondo: const Color(0xFFF6ECD8),
                  colorTexto: const Color(0xFFB57A4B),
                ),
                _TagChip(
                  texto: disponible ? 'Disponible' : 'No disponible',
                  colorFondo: disponible
                      ? const Color(0xFFE6F6E9)
                      : const Color(0xFFFBE4E6),
                  colorTexto: disponible
                      ? const Color(0xFF4AA564)
                      : const Color(0xFFE56B6F),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onVerPerfil,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF14A89A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: Color(0xFF14A89A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSolicitar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14A89A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Solicitar paseo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

class _TagChip extends StatelessWidget {
  final String texto;
  final Color colorFondo;
  final Color colorTexto;

  const _TagChip({
    required this.texto,
    required this.colorFondo,
    required this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: colorTexto,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}