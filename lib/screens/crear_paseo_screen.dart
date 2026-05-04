import 'package:flutter/material.dart';

import '../services/paseadores_service.dart';
import '../services/perros_service.dart';
import '../services/paseos_service.dart';
import 'seleccionar_ubicacion_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────────────────────
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

  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  static const shadow1 = [
    BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
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

class CrearPaseoScreen extends StatefulWidget {
  final Map<String, dynamic>? paseador;
  const CrearPaseoScreen({super.key, this.paseador});
  @override
  State<CrearPaseoScreen> createState() => _CrearPaseoScreenState();
}

class _CrearPaseoScreenState extends State<CrearPaseoScreen> {
  List<dynamic> _perros = [];
  List<dynamic> _paseadores = [];
  bool _cargandoPerros = true;
  bool _cargandoPaseadores = false;
  bool _guardando = false;
  int? _perroIdSeleccionado;
  int? _paseadorIdSeleccionado;
  Map<String, dynamic>? _paseadorSeleccionado;
  int _duracion = 30;
  DateTime? _fechaSeleccionada;
  double? _latitudRecogida;
  double? _longitudRecogida;
  String? _ubicacionTexto;
  final TextEditingController _notasController = TextEditingController();

  final List<Map<String, dynamic>> _duraciones = [
    {'label': '30 min', 'val': 30},
    {'label': '45 min', 'val': 45},
    {'label': '1 hora', 'val': 60},
    {'label': '1.5 hrs', 'val': 90},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.paseador != null) {
      _paseadorSeleccionado = _mapaSeguro(widget.paseador);
      _paseadorIdSeleccionado = _idPaseador(_paseadorSeleccionado!);
    }
    _cargarPerros();
    if (widget.paseador == null) _cargarPaseadores();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _mapaSeguro(dynamic valor) {
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) return Map<String, dynamic>.from(valor);
    return {};
  }

  dynamic _valor(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) return mapa[key];
    }
    return null;
  }

  int? _intSeguro(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  int? _idPaseador(Map<String, dynamic> paseador) => _intSeguro(
    _valor(paseador, [
      'id',
      'Id',
      'paseadorId',
      'PaseadorId',
      'idPaseador',
      'IdPaseador',
    ]),
  );
  int? _idPerro(Map<String, dynamic> perro) => _intSeguro(
    _valor(perro, ['id', 'Id', 'perroId', 'PerroId', 'idPerro', 'IdPerro']),
  );

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _nombrePaseador(Map<String, dynamic>? paseador) {
    if (paseador == null || paseador.isEmpty) return 'Selecciona un paseador';
    final nombre = _textoSeguro(
      _valor(paseador, ['nombre', 'Nombre', 'paseadorNombre']),
      '',
    );
    final apellido = _textoSeguro(
      _valor(paseador, ['apellido', 'Apellido', 'paseadorApellido']),
      '',
    );
    final completo = '$nombre $apellido'.trim();
    return completo.isEmpty ? 'Paseador seleccionado' : completo;
  }

  Future<void> _cargarPerros() async {
    setState(() => _cargandoPerros = true);
    try {
      final result = await PerrosService.obtenerMisPerros();
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _perros = result['data'] is List ? result['data'] : [];
          _cargandoPerros = false;
        });
      } else {
        setState(() => _cargandoPerros = false);
        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudieron cargar tus perros.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoPerros = false);
      _mostrarMensaje('Error de conexión: $e');
    }
  }

  Future<void> _cargarPaseadores() async {
    setState(() => _cargandoPaseadores = true);
    try {
      final result = await PaseadoresService.obtenerPaseadores();
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _paseadores = result['data'] is List ? result['data'] : [];
          _cargandoPaseadores = false;
        });
      } else {
        setState(() => _cargandoPaseadores = false);
        _mostrarMensaje(
          result['message']?.toString() ??
              'No se pudieron cargar los paseadores.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoPaseadores = false);
      _mostrarMensaje('Error al cargar paseadores: $e');
    }
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: DateTime(2030),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora == null) return;
    setState(
      () => _fechaSeleccionada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      ),
    );
  }

  Future<void> _seleccionarUbicacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarUbicacionScreen()),
    );
    if (!mounted || resultado == null || resultado is! Map) return;

    final latitud = _leerDouble(resultado, [
      'latitud',
      'lat',
      'latitude',
      'latitudRecogida',
    ]);
    final longitud = _leerDouble(resultado, [
      'longitud',
      'lng',
      'lon',
      'longitude',
      'longitudRecogida',
    ]);
    final texto = _leerTexto(resultado, [
      'ubicacionTexto',
      'direccionRecogida',
      'direccion',
      'texto',
      'descripcion',
      'nombre',
      'texto',
    ]);

    if (latitud == null || longitud == null) {
      _mostrarMensaje('La ubicación no tiene coordenadas válidas.');
      return;
    }

    setState(() {
      _latitudRecogida = latitud;
      _longitudRecogida = longitud;
      _ubicacionTexto = texto.isNotEmpty
          ? texto
          : 'Ubicación seleccionada en el mapa';
    });
  }

  double? _leerDouble(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      if (value is double) return value;
      if (value is int || value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _leerTexto(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final texto = value.toString().trim();
      if (texto.isNotEmpty) return texto;
    }
    return '';
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: G.body(G.white).copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: G.ink5,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: G.r12),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} a las $hora:$minuto';
  }

  Future<void> _crearPaseo() async {
    final paseadorId =
        _paseadorIdSeleccionado ??
        (_paseadorSeleccionado == null
            ? null
            : _idPaseador(_paseadorSeleccionado!));
    if (paseadorId == null) {
      _mostrarMensaje('Por favor, selecciona un paseador.');
      return;
    }
    if (_perroIdSeleccionado == null) {
      _mostrarMensaje('Por favor, selecciona un perro.');
      return;
    }
    if (_fechaSeleccionada == null) {
      _mostrarMensaje('Por favor, selecciona fecha y hora.');
      return;
    }
    if (_latitudRecogida == null || _longitudRecogida == null) {
      _mostrarMensaje('Selecciona la ubicación de recogida en el mapa.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final result = await PaseosService.crearPaseo(
        paseadorId: paseadorId,
        perroId: _perroIdSeleccionado!,
        fechaProgramada: _fechaSeleccionada!,
        duracionMinutos: _duracion,
        latitudRecogida: _latitudRecogida,
        longitudRecogida: _longitudRecogida,
        ubicacionTexto: _ubicacionTexto,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        _mostrarMensaje('¡Paseo programado con éxito! 🐾');
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudo crear el paseo.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: G.ink0,
      appBar: AppBar(
        backgroundColor: G.ink0,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: G.ink6,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Programar Paseo',
          style: G.h3(G.ink6).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _cargandoPerros || _cargandoPaseadores
          ? const Center(child: CircularProgressIndicator(color: G.brand))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.paseador == null) ...[
                    _seccionTitulo('¿Con quién?'),
                    _selectorPaseadores(),
                    const SizedBox(height: 24),
                  ] else ...[
                    _seccionTitulo('Paseador seleccionado'),
                    _paseadorFijoCard(),
                    const SizedBox(height: 24),
                  ],
                  _seccionTitulo('¿A quién paseamos?'),
                  _selectorPerros(),
                  const SizedBox(height: 24),
                  _seccionTitulo('Duración del paseo'),
                  _selectorDuracion(),
                  const SizedBox(height: 24),
                  _seccionTitulo('¿Cuándo?'),
                  _selectorFechaPremium(),
                  const SizedBox(height: 24),
                  _seccionTitulo('Punto de encuentro'),
                  _ubicacionCard(),
                  const SizedBox(height: 24),
                  _seccionTitulo('Notas para el paseador (Opcional)'),
                  _campoNotas(),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (_cargandoPerros || _cargandoPaseadores)
          ? null
          : _botonConfirmar(),
    );
  }

  Widget _seccionTitulo(String titulo) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: Text(titulo, style: G.h3(G.ink6)),
  );

  Widget _selectorPaseadores() {
    if (_paseadores.isEmpty)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('No hay paseadores disponibles', style: G.body(G.ink4)),
      );
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _paseadores.length,
        itemBuilder: (context, index) {
          final p = _mapaSeguro(_paseadores[index]);
          final id = _idPaseador(p);
          final nombre = _nombrePaseador(p);
          final isSelected = _paseadorIdSeleccionado == id;
          return GestureDetector(
            onTap: () => setState(() {
              _paseadorIdSeleccionado = id;
              _paseadorSeleccionado = p;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 95,
              decoration: BoxDecoration(
                color: isSelected ? G.brandPale : G.white,
                borderRadius: G.r20,
                border: Border.all(
                  color: isSelected ? G.brand : G.ink2,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: G.brand.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : G.shadow1,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: G.brand.withOpacity(0.1),
                    child: const Icon(Icons.person_rounded, color: G.brand),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombre.split(' ')[0],
                    style: G
                        .label(isSelected ? G.brand : G.ink5)
                        .copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _paseadorFijoCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: G.white,
      borderRadius: G.r16,
      border: Border.all(color: G.brand.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: G.brand.withOpacity(0.1),
          child: const Icon(Icons.person_rounded, color: G.brand),
        ),
        const SizedBox(width: 12),
        Text(
          _nombrePaseador(_paseadorSeleccionado),
          style: G.h3(G.ink6).copyWith(fontSize: 15),
        ),
      ],
    ),
  );

  Widget _selectorPerros() {
    if (_perros.isEmpty)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('No tienes perros registrados', style: G.body(G.ink4)),
      );
    final List<Color> colores = [G.clay, G.sage, G.plum, G.gold];
    final List<Color> pales = [G.clayLight, G.sagePale, G.plumPale, G.goldPale];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _perros.length,
        itemBuilder: (context, index) {
          final p = _mapaSeguro(_perros[index]);
          final id = _idPerro(p);
          final isSelected = _perroIdSeleccionado == id;
          final color = colores[index % colores.length];
          final pale = pales[index % pales.length];
          return GestureDetector(
            onTap: () => setState(() => _perroIdSeleccionado = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 85,
              decoration: BoxDecoration(
                color: isSelected ? pale : G.white,
                borderRadius: G.r20,
                border: Border.all(
                  color: isSelected ? color : G.ink2,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : G.shadow1,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _textoSeguro(p['emoji'], '🐕'),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _textoSeguro(p['nombre']),
                    style: G
                        .label(isSelected ? color : G.ink5)
                        .copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectorDuracion() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _duraciones.map((opcion) {
        final isSelected = _duracion == opcion['val'];
        return GestureDetector(
          onTap: () => setState(() => _duracion = opcion['val']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? G.brand : G.white,
              borderRadius: G.r16,
              border: Border.all(color: isSelected ? G.brand : G.ink2),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: G.brand.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : G.shadow1,
            ),
            child: Text(
              opcion['label'],
              style: G.label(isSelected ? G.white : G.ink5),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _selectorFechaPremium() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: GestureDetector(
      onTap: _guardando ? null : _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: G.white,
          borderRadius: G.r16,
          border: Border.all(color: G.ink2),
          boxShadow: G.shadow1,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: G.plumPale, borderRadius: G.r12),
              child: const Icon(Icons.calendar_month_rounded, color: G.plum),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha y Hora',
                    style: G.h3(G.ink6).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fechaSeleccionada == null
                        ? 'Toca para programar'
                        : _formatearFecha(_fechaSeleccionada!),
                    style: G
                        .body(
                          _fechaSeleccionada == null ? G.ink4 : G.plum,
                          size: 12,
                        )
                        .copyWith(
                          fontWeight: _fechaSeleccionada == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: G.ink3),
          ],
        ),
      ),
    ),
  );

  Widget _ubicacionCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: GestureDetector(
      onTap: _guardando ? null : _seleccionarUbicacion,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: G.white,
          borderRadius: G.r16,
          border: Border.all(
            color: _latitudRecogida == null ? G.ink2 : G.brand.withOpacity(0.5),
          ),
          boxShadow: G.shadow1,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: G.brandPale,
                borderRadius: G.r12,
              ),
              child: const Icon(Icons.location_on_rounded, color: G.brand),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lugar de recogida',
                    style: G.h3(G.ink6).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ubicacionTexto ?? 'Toca para abrir el mapa',
                    style: G.body(
                      _ubicacionTexto == null ? G.ink4 : G.brandDark,
                      size: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: G.ink3),
          ],
        ),
      ),
    ),
  );

  Widget _campoNotas() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: TextField(
      controller: _notasController,
      maxLines: 3,
      enabled: !_guardando,
      style: G.body(G.ink6),
      decoration: InputDecoration(
        hintText: 'Ej. Cansa rápido, llevarle agua...',
        hintStyle: G.body(G.ink3),
        filled: true,
        fillColor: G.white,
        border: OutlineInputBorder(
          borderRadius: G.r16,
          borderSide: const BorderSide(color: G.ink2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: G.r16,
          borderSide: const BorderSide(color: G.ink2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: G.r16,
          borderSide: const BorderSide(color: G.brand),
        ),
      ),
    ),
  );

  Widget _botonConfirmar() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: ElevatedButton(
      onPressed: _guardando ? null : _crearPaseo,
      style: ElevatedButton.styleFrom(
        backgroundColor: G.brand,
        disabledBackgroundColor: G.brand.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: G.r16),
        elevation: 4,
        shadowColor: G.brand.withOpacity(0.5),
      ),
      child: _guardando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: G.white, strokeWidth: 2),
            )
          : Text(
              'Confirmar y Programar',
              style: G.label(G.white).copyWith(fontSize: 14),
            ),
    ),
  );
}
