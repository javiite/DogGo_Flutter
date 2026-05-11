import 'package:flutter/material.dart';

import '../services/paseadores_service.dart';
import '../services/storage_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'crear_paseo_screen.dart';
import 'detalle_paseador_screen.dart';

class PaseadoresScreen extends StatefulWidget {
  const PaseadoresScreen({super.key});

  @override
  State<PaseadoresScreen> createState() => _PaseadoresScreenState();
}

class _PaseadoresScreenState extends State<PaseadoresScreen> {
  bool _cargando = true;
  bool _soloDisponibles = false;

  String? _error;
  String? _baseUrl;
  String _zonaSeleccionada = 'Todas';
  String _ordenSeleccionado = 'Mejor calificación';

  List<dynamic> _paseadores = [];
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await _cargarBaseUrl();
    await _cargarPaseadores();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = url;
    });
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

  String _texto(dynamic valor, {String fallback = 'Sin dato'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  Map<String, dynamic> _map(dynamic valor) {
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) return Map<String, dynamic>.from(valor);
    return {};
  }

  dynamic _val(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) {
        return mapa[key];
      }
    }

    return null;
  }

  Map<String, dynamic> _usuario(Map<String, dynamic> paseador) {
    return _map(
      _val(
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

  int? _idPaseador(Map<String, dynamic> paseador) {
    final valor = _val(
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

  String _nombre(Map<String, dynamic> paseador) {
    final usuario = _usuario(paseador);

    final nombreCompleto = _texto(
      _val(
        paseador,
        [
          'nombreCompleto',
          'NombreCompleto',
          'paseadorNombreCompleto',
          'PaseadorNombreCompleto',
        ],
      ),
      fallback: '',
    );

    if (nombreCompleto.isNotEmpty) return nombreCompleto;

    final nombre = _texto(
      _val(
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
          _val(
            usuario,
            [
              'nombre',
              'Nombre',
              'name',
              'Name',
            ],
          ),
      fallback: '',
    );

    final apellido = _texto(
      _val(
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
          _val(
            usuario,
            [
              'apellido',
              'Apellido',
              'lastName',
              'LastName',
            ],
          ),
      fallback: '',
    );

    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? 'Paseador DogGo' : completo;
  }

  String _email(Map<String, dynamic> paseador) {
    final usuario = _usuario(paseador);

    return _texto(
      _val(
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
          _val(
            usuario,
            [
              'email',
              'Email',
              'correo',
              'Correo',
            ],
          ),
      fallback: '',
    );
  }

  String _descripcion(Map<String, dynamic> paseador) {
    return _texto(
      _val(
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
      fallback: 'Sin descripción registrada.',
    );
  }

  String _zona(Map<String, dynamic> paseador) {
    return _texto(
      _val(
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
      fallback: 'Sin zona',
    );
  }

  String? _foto(Map<String, dynamic> paseador) {
    final usuario = _usuario(paseador);

    final raw = _val(
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
        _val(
          usuario,
          [
            'fotoUrl',
            'FotoUrl',
            'fotoPerfilUrl',
            'FotoPerfilUrl',
            'imagenUrl',
            'ImagenUrl',
          ],
        );

    return _urlPublica(raw);
  }

  String? _urlPublica(dynamic valor) {
    final raw = valor?.toString().trim();

    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return raw;

    if (raw.startsWith('/')) {
      return '$base$raw';
    }

    return '$base/$raw';
  }

  double? _tarifaNumero(Map<String, dynamic> paseador) {
    final valor = _val(
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

    if (valor == null) return null;

    return double.tryParse(valor.toString());
  }

  String _tarifa(Map<String, dynamic> paseador) {
    final valor = _val(
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

    if (valor == null) return 'Tarifa no disponible';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return '\$${valor.toString()} / hora';

    return '\$${numero.toStringAsFixed(2)} / hora';
  }

  double _ratingNumero(Map<String, dynamic> paseador) {
    final valor = _val(
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

    if (valor == null) return 0;

    return double.tryParse(valor.toString()) ?? 0;
  }

  String _rating(Map<String, dynamic> paseador) {
    final numero = _ratingNumero(paseador);

    if (numero <= 0) return '0.0';

    return numero.toStringAsFixed(1);
  }

  String _experiencia(Map<String, dynamic> paseador) {
    final valor = _val(
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

    if (valor == null) return 'Sin experiencia';

    final numero = int.tryParse(valor.toString());

    if (numero == null) return '${valor.toString()} año(s)';

    if (numero == 1) return '1 año';

    return '$numero años';
  }

  int _experienciaNumero(Map<String, dynamic> paseador) {
    final valor = _val(
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

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  bool _disponible(Map<String, dynamic> paseador) {
    final valor = _val(
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

  List<String> _zonas(Map<String, dynamic> paseador) {
    final zona = _zona(paseador);

    if (zona == 'Sin zona') return [zona];

    final zonas = zona
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return zonas.isEmpty ? [zona] : zonas;
  }

  List<String> get _zonasDisponibles {
    final zonas = <String>{};

    for (final item in _paseadores) {
      final paseador = _map(item);

      for (final zona in _zonas(paseador)) {
        if (zona.trim().isNotEmpty && zona != 'Sin zona') {
          zonas.add(zona.trim());
        }
      }
    }

    final lista = zonas.toList()..sort();

    return ['Todas', ...lista];
  }

  int get _totalDisponibles {
    return _paseadores.where((item) => _disponible(_map(item))).length;
  }

  double get _promedioRating {
    if (_paseadores.isEmpty) return 0;

    final ratings = _paseadores
        .map((item) => _ratingNumero(_map(item)))
        .where((rating) => rating > 0)
        .toList();

    if (ratings.isEmpty) return 0;

    final total = ratings.fold<double>(0, (sum, item) => sum + item);

    return total / ratings.length;
  }

  Map<String, dynamic> _normalizar(Map<String, dynamic> paseador) {
    final normalizado = Map<String, dynamic>.from(paseador);
    final id = _idPaseador(paseador);

    if (id != null) {
      normalizado['id'] = id;
      normalizado['paseadorId'] = id;
    }

    normalizado['nombre'] = _nombre(paseador);
    normalizado['nombreCompleto'] = _nombre(paseador);
    normalizado['email'] = _email(paseador);
    normalizado['descripcion'] = _descripcion(paseador);
    normalizado['zonaServicio'] = _zona(paseador);
    normalizado['fotoUrl'] = _foto(paseador);
    normalizado['imagenUrl'] = _foto(paseador);
    normalizado['disponible'] = _disponible(paseador);

    normalizado['tarifaPorHora'] = _val(
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

    normalizado['calificacionPromedio'] = _val(
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

    normalizado['experienciaAnios'] = _val(
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

  List<dynamic> get _filtrados {
    final query = _busquedaController.text.trim().toLowerCase();

    final filtrados = _paseadores.where((item) {
      final paseador = _map(item);

      if (_soloDisponibles && !_disponible(paseador)) {
        return false;
      }

      if (_zonaSeleccionada != 'Todas') {
        final zonas = _zonas(paseador).map((e) => e.toLowerCase()).toList();

        if (!zonas.contains(_zonaSeleccionada.toLowerCase())) {
          return false;
        }
      }

      if (query.isEmpty) return true;

      final texto = [
        _nombre(paseador),
        _email(paseador),
        _descripcion(paseador),
        _zona(paseador),
        _tarifa(paseador),
        _experiencia(paseador),
        _rating(paseador),
      ].join(' ').toLowerCase();

      return texto.contains(query);
    }).toList();

    filtrados.sort((a, b) {
      final pa = _map(a);
      final pb = _map(b);

      final disponibleA = _disponible(pa) ? 1 : 0;
      final disponibleB = _disponible(pb) ? 1 : 0;

      if (disponibleA != disponibleB) {
        return disponibleB.compareTo(disponibleA);
      }

      if (_ordenSeleccionado == 'Menor tarifa') {
        final tarifaA = _tarifaNumero(pa) ?? 999999;
        final tarifaB = _tarifaNumero(pb) ?? 999999;

        return tarifaA.compareTo(tarifaB);
      }

      if (_ordenSeleccionado == 'Más experiencia') {
        return _experienciaNumero(pb).compareTo(_experienciaNumero(pa));
      }

      return _ratingNumero(pb).compareTo(_ratingNumero(pa));
    });

    return filtrados;
  }

  Future<void> _abrirDetalle(Map<String, dynamic> paseador) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePaseadorScreen(
          paseador: _normalizar(paseador),
        ),
      ),
    );

    if (mounted) {
      await _cargarPaseadores();
    }
  }

  Future<void> _solicitarPaseo(Map<String, dynamic> paseador) async {
    final normalizado = _normalizar(paseador);

    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPaseoScreen(
          paseador: normalizado,
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

      await _cargarPaseadores();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: Stack(
        children: [
          const Positioned.fill(
            child: _PawBackground(),
          ),
          SafeArea(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargarPaseadores,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildTopBar()),
                        SliverToBoxAdapter(child: _buildHeader(lista.length)),
                        SliverToBoxAdapter(child: _buildBuscador()),
                        SliverToBoxAdapter(child: _buildFiltros()),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
                            child: _error != null
                                ? _buildError()
                                : lista.isEmpty
                                    ? _buildVacio()
                                    : Column(
                                        children: lista.map((item) {
                                          final paseador = _map(item);

                                          return _PaseadorCard(
                                            nombre: _nombre(paseador),
                                            precio: _tarifa(paseador),
                                            descripcion:
                                                _descripcion(paseador),
                                            zonas: _zonas(paseador),
                                            experiencia:
                                                _experiencia(paseador),
                                            disponible:
                                                _disponible(paseador),
                                            rating: _rating(paseador),
                                            fotoUrl: _foto(paseador),
                                            onVerPerfil: () =>
                                                _abrirDetalle(paseador),
                                            onSolicitar: () =>
                                                _solicitarPaseo(paseador),
                                          );
                                        }).toList(),
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2.withOpacity(.96),
        border: Border(
          bottom: BorderSide(
            color: DogGoTheme.border.withOpacity(.8),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: DogGoTheme.ink,
            ),
          ),
          const SizedBox(width: 2),
          const DogGoLogo(size: 40),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DogGoTheme.teal.withOpacity(.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  size: 16,
                  color: DogGoTheme.teal,
                ),
                const SizedBox(width: 5),
                Text(
                  'Paseadores',
                  style: DogGoTheme.body(
                    size: 11.5,
                    color: DogGoTheme.teal,
                    weight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _cargarPaseadores,
            icon: const Icon(
              Icons.refresh_rounded,
              color: DogGoTheme.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASEADORES DOGGO',
            style: DogGoTheme.label(size: 11),
          ),
          const SizedBox(height: 10),
          Text(
            'Encuentra un paseador',
            style: DogGoTheme.title(size: 34),
          ),
          const SizedBox(height: 10),
          Text(
            'Compara perfiles, tarifa, zona, experiencia y calificación antes de solicitar tu paseo.',
            style: DogGoTheme.subtitle(size: 15.5),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: DogGoTheme.teal,
              borderRadius: BorderRadius.circular(30),
              boxShadow: DogGoTheme.softShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 126,
                    height: 126,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: -25,
                  child: Icon(
                    Icons.pets_rounded,
                    color: Colors.white.withOpacity(.12),
                    size: 108,
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_search_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$total paseadores encontrados',
                                style: DogGoTheme.title(
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Elige el perfil que mejor encaje con tu perro.',
                                style: DogGoTheme.body(
                                  size: 13,
                                  color: Colors.white.withOpacity(.9),
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: _HeaderStat(
                            value: '$_totalDisponibles',
                            label: 'Disponibles',
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeaderStat(
                            value: _promedioRating <= 0
                                ? '0.0'
                                : _promedioRating.toStringAsFixed(1),
                            label: 'Promedio',
                            icon: Icons.star_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: TextField(
        controller: _busquedaController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar paseador, zona o experiencia...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _busquedaController.text.trim().isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _busquedaController.clear();
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: DogGoTheme.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: DogGoTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: DogGoTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: DogGoTheme.teal,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    final zonas = _zonasDisponibles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterBox(
                  icon: Icons.tune_rounded,
                  label: 'Orden',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _ordenSeleccionado,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(18),
                      items: const [
                        DropdownMenuItem(
                          value: 'Mejor calificación',
                          child: Text('Mejor calificación'),
                        ),
                        DropdownMenuItem(
                          value: 'Menor tarifa',
                          child: Text('Menor tarifa'),
                        ),
                        DropdownMenuItem(
                          value: 'Más experiencia',
                          child: Text('Más experiencia'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _ordenSeleccionado = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterBox(
                  icon: Icons.location_on_rounded,
                  label: 'Zona',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: zonas.contains(_zonaSeleccionada)
                          ? _zonaSeleccionada
                          : 'Todas',
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(18),
                      items: zonas
                          .map(
                            (zona) => DropdownMenuItem(
                              value: zona,
                              child: Text(
                                zona,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _zonaSeleccionada = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color:
                _soloDisponibles ? DogGoTheme.greenLight : DogGoTheme.card,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () {
                setState(() {
                  _soloDisponibles = !_soloDisponibles;
                });
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _soloDisponibles
                        ? DogGoTheme.green.withOpacity(.22)
                        : DogGoTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _soloDisponibles
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: _soloDisponibles
                          ? DogGoTheme.green
                          : DogGoTheme.muted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Mostrar solo paseadores disponibles',
                        style: DogGoTheme.body(
                          size: 13.3,
                          color: DogGoTheme.ink,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return _WebCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: DogGoTheme.red,
          ),
          const SizedBox(height: 14),
          Text(
            _error ?? 'No se pudieron cargar los paseadores.',
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 20),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarPaseadores,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: DogGoTheme.primaryButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return _WebCard(
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 48,
              color: DogGoTheme.teal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron paseadores',
            style: DogGoTheme.title(size: 21),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            'Prueba con otra búsqueda, cambia los filtros o actualiza la lista.',
            style: DogGoTheme.subtitle(size: 13.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _busquedaController.clear();

              setState(() {
                _zonaSeleccionada = 'Todas';
                _soloDisponibles = false;
              });
            },
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Limpiar filtros'),
            style: DogGoTheme.secondaryButton(),
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
  final String experiencia;
  final String rating;
  final String? fotoUrl;
  final List<String> zonas;
  final bool disponible;
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

  bool get _tieneFoto {
    final foto = fotoUrl;

    if (foto == null) return false;

    return foto.startsWith('http://') || foto.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onVerPerfil,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: DogGoTheme.border.withOpacity(.9)),
            boxShadow: DogGoTheme.softShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 8,
                color: disponible ? DogGoTheme.teal : DogGoTheme.muted,
              ),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: 'paseador-$nombre-$precio',
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: DogGoTheme.tealLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _tieneFoto
                                ? Image.network(
                                    fotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return const Icon(
                                        Icons.person_rounded,
                                        color: DogGoTheme.teal,
                                        size: 38,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    color: DogGoTheme.teal,
                                    size: 38,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DogGoTheme.title(size: 21),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                precio,
                                style: DogGoTheme.body(
                                  size: 13.3,
                                  color: DogGoTheme.teal,
                                  weight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: DogGoTheme.orange,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating,
                                    style: DogGoTheme.body(
                                      size: 12.5,
                                      color: DogGoTheme.ink,
                                      weight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Calificación',
                                    style: DogGoTheme.subtitle(size: 11.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: disponible
                                ? DogGoTheme.greenLight
                                : DogGoTheme.redLight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            disponible ? 'Disponible' : 'Ocupado',
                            style: DogGoTheme.body(
                              size: 10.5,
                              color: disponible
                                  ? DogGoTheme.green
                                  : DogGoTheme.red,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DogGoTheme.cream2,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: DogGoTheme.border.withOpacity(.8),
                        ),
                      ),
                      child: Text(
                        descripcion,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.body(
                          size: 13,
                          color: DogGoTheme.ink,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...zonas.take(3).map(
                                (zona) => _Chip(
                                  label: zona,
                                  color: DogGoTheme.teal,
                                  surface: DogGoTheme.tealLight,
                                  icon: Icons.location_on_rounded,
                                ),
                              ),
                          _Chip(
                            label: experiencia,
                            color: DogGoTheme.orange,
                            surface: DogGoTheme.orangeLight,
                            icon: Icons.workspace_premium_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onVerPerfil,
                            icon: const Icon(
                              Icons.visibility_rounded,
                              size: 18,
                            ),
                            label: const Text('Ver perfil'),
                            style: DogGoTheme.secondaryButton(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: disponible ? onSolicitar : null,
                            icon: const Icon(
                              Icons.directions_walk_rounded,
                              size: 18,
                            ),
                            label: const Text('Solicitar'),
                            style: DogGoTheme.primaryButton(),
                          ),
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

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeaderStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.title(
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.body(
                    size: 11,
                    color: Colors.white.withOpacity(.82),
                    weight: FontWeight.w800,
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

class _FilterBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _FilterBox({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 7),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: DogGoTheme.teal,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DogGoTheme.subtitle(size: 10.5),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color surface;
  final IconData icon;

  const _Chip({
    required this.label,
    required this.color,
    required this.surface,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: DogGoTheme.body(
              size: 10.5,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebCard extends StatelessWidget {
  final Widget child;

  const _WebCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: child,
    );
  }
}

class _PawBackground extends StatelessWidget {
  const _PawBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PawBackgroundPainter(),
    );
  }
}

class _PawBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DogGoTheme.teal.withOpacity(.055)
      ..style = PaintingStyle.fill;

    const spacing = 72.0;

    for (double x = -20; x < size.width + spacing; x += spacing) {
      for (double y = -10; y < size.height + spacing; y += spacing) {
        final dx = x + ((y ~/ spacing).isEven ? 0 : 28);
        final dy = y;

        canvas.drawCircle(Offset(dx + 15, dy + 19), 4.2, paint);
        canvas.drawCircle(Offset(dx + 24, dy + 12), 4.0, paint);
        canvas.drawCircle(Offset(dx + 33, dy + 19), 4.2, paint);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(dx + 24, dy + 31),
            width: 22,
            height: 17,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}