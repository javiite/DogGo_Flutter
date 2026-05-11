import 'package:flutter/material.dart';

import '../services/paseos_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'calendario_paseos_screen.dart';
import 'chat_paseo_screen.dart';
import 'detalle_paseo_screen.dart';
import 'mapa_paseo_screen.dart';

class MisPaseosScreen extends StatefulWidget {
  final int? usuarioId;
  final String? rol;
  final String? filtroInicial;

  const MisPaseosScreen({
    super.key,
    this.usuarioId,
    this.rol,
    this.filtroInicial,
  });

  @override
  State<MisPaseosScreen> createState() => _MisPaseosScreenState();
}

class _MisPaseosScreenState extends State<MisPaseosScreen> {
  final TextEditingController _busquedaController = TextEditingController();

  List<Map<String, dynamic>> _paseos = [];
  bool _cargando = true;
  bool _accionando = false;
  String? _error;
  String? _rolReal;
  String? _baseUrl;
  String _filtroEstado = 'Todos';

  final List<String> _filtros = const [
    'Todos',
    'Pendiente',
    'Aceptado',
    'EnCurso',
    'Finalizado',
    'Cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _filtroEstado = widget.filtroInicial ?? 'Todos';
    _busquedaController.addListener(() {
      if (mounted) setState(() {});
    });
    _inicializar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String get _rolUsuario => _rolReal ?? widget.rol ?? '';
  bool get _esPaseador => SessionService.esPaseadorRol(_rolUsuario);
  bool get _esDuenio => SessionService.esDuenioRol(_rolUsuario);

  Future<void> _inicializar() async {
    await _cargarBaseUrl();
    await _cargarRol();
    await _cargarPaseos();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await StorageService.obtenerBaseUrl();
    if (!mounted) return;
    setState(() => _baseUrl = url);
  }

  Future<void> _cargarRol() async {
    try {
      final rol = await SessionService.obtenerRol();
      if (!mounted) return;
      setState(() => _rolReal = rol ?? widget.rol);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rolReal = widget.rol);
    }
  }

  Future<void> _cargarPaseos() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final result = await PaseosService.obtenerMisPaseos();
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _paseos = _normalizarLista(result['data']);
          _cargando = false;
        });
      } else {
        setState(() {
          _cargando = false;
          _error = result['message']?.toString() ?? 'No se pudieron cargar.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic datos) {
    if (datos is Map) {
      final posibleLista =
          datos['data'] ??
          datos['paseos'] ??
          datos['items'] ??
          datos['resultado'] ??
          datos['result'] ??
          datos['value'];
      return _normalizarLista(posibleLista);
    }
    if (datos is! List) return [];
    return datos
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  int? _idPaseo(Map<String, dynamic> paseo) {
    final valor =
        paseo['id'] ?? paseo['Id'] ?? paseo['paseoId'] ?? paseo['PaseoId'];
    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '');
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) =>
      (valor == null ||
          valor.toString().trim().isEmpty ||
          valor.toString().toLowerCase() == 'null')
      ? fallback
      : valor.toString().trim();

  double? _doubleSeguro(dynamic valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString());
  }

  String _estado(Map<String, dynamic> paseo) =>
      _texto(paseo['estado'] ?? paseo['Estado'], fallback: 'Pendiente');
  String _normalizarEstado(String estado) =>
      estado.replaceAll(' ', '').toLowerCase();

  String _estadoLegible(String estado) {
    switch (_normalizarEstado(estado)) {
      case 'encurso':
        return 'En curso';
      case 'pendiente':
        return 'Pendiente';
      case 'aceptado':
        return 'Aceptado';
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  Color _colorEstado(String estado) {
    switch (_normalizarEstado(estado)) {
      case 'pendiente':
        return DogGoTheme.orange;
      case 'aceptado':
        return DogGoTheme.purple;
      case 'encurso':
        return DogGoTheme.green;
      case 'finalizado':
        return DogGoTheme.teal;
      case 'cancelado':
        return DogGoTheme.red;
      default:
        return DogGoTheme.muted;
    }
  }

  Color _surfaceEstado(String estado) {
    switch (_normalizarEstado(estado)) {
      case 'pendiente':
        return DogGoTheme.orangeLight;
      case 'aceptado':
        return DogGoTheme.purpleLight;
      case 'encurso':
        return DogGoTheme.greenLight;
      case 'finalizado':
        return DogGoTheme.tealLight;
      case 'cancelado':
        return DogGoTheme.redLight;
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData _iconoEstado(String estado) {
    switch (_normalizarEstado(estado)) {
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'aceptado':
        return Icons.verified_rounded;
      case 'encurso':
        return Icons.directions_walk_rounded;
      case 'finalizado':
        return Icons.flag_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  bool _estaPendiente(Map<String, dynamic> paseo) =>
      _normalizarEstado(_estado(paseo)) == 'pendiente';
  bool _estaAceptado(Map<String, dynamic> paseo) =>
      _normalizarEstado(_estado(paseo)) == 'aceptado';
  bool _estaEnCurso(Map<String, dynamic> paseo) =>
      _normalizarEstado(_estado(paseo)) == 'encurso';
  bool _estaFinalizado(Map<String, dynamic> paseo) =>
      _normalizarEstado(_estado(paseo)) == 'finalizado';
  bool _estaCancelado(Map<String, dynamic> paseo) =>
      _normalizarEstado(_estado(paseo)) == 'cancelado';

  bool _puedeAceptar(Map<String, dynamic> paseo) =>
      _esPaseador && _estaPendiente(paseo);
  bool _puedeRechazar(Map<String, dynamic> paseo) =>
      _esPaseador && _estaPendiente(paseo);
  bool _puedeIniciar(Map<String, dynamic> paseo) =>
      _esPaseador && _estaAceptado(paseo);
  bool _puedeFinalizar(Map<String, dynamic> paseo) =>
      _esPaseador && _estaEnCurso(paseo);
  bool _puedeCancelar(Map<String, dynamic> paseo) =>
      !(_estaFinalizado(paseo) || _estaCancelado(paseo)) &&
      (_esPaseador || _esDuenio);
  bool _tieneAccionesRapidas(Map<String, dynamic> paseo) =>
      _puedeAceptar(paseo) ||
      _puedeRechazar(paseo) ||
      _puedeIniciar(paseo) ||
      _puedeFinalizar(paseo) ||
      _puedeCancelar(paseo);

  String _nombrePerro(Map<String, dynamic> paseo) => _texto(
    paseo['perroNombre'] ??
        paseo['nombrePerro'] ??
        paseo['perro']?['nombre'] ??
        paseo['Perro']?['nombre'],
    fallback: 'Perro',
  );

  String _nombrePaseador(Map<String, dynamic> paseo) {
    final n = _texto(
      paseo['nombrePaseador'] ?? paseo['paseador']?['usuario']?['nombre'],
      fallback: '',
    );
    final a = _texto(
      paseo['apellidoPaseador'] ?? paseo['paseador']?['usuario']?['apellido'],
      fallback: '',
    );
    final c = '$n $a'.trim();
    return c.isEmpty ? 'Paseador no asignado' : c;
  }

  String _nombreDuenio(Map<String, dynamic> paseo) {
    final n = _texto(
      paseo['nombreDuenio'] ?? paseo['perro']?['usuario']?['nombre'],
      fallback: '',
    );
    final a = _texto(
      paseo['apellidoDuenio'] ?? paseo['perro']?['usuario']?['apellido'],
      fallback: '',
    );
    final c = '$n $a'.trim();
    return c.isEmpty ? 'Dueño' : c;
  }

  DateTime? _fechaDate(Map<String, dynamic> paseo) {
    final v =
        paseo['fechaProgramada'] ?? paseo['fechaInicio'] ?? paseo['fecha'];
    return DateTime.tryParse(v?.toString() ?? '')?.toLocal();
  }

  String _fechaCompacta(Map<String, dynamic> paseo) {
    final fecha = _fechaDate(paseo);
    if (fecha == null) return 'Sin fecha';
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  String _horaCompacta(Map<String, dynamic> paseo) {
    final fecha = _fechaDate(paseo);
    if (fecha == null) return '--:--';
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _precio(Map<String, dynamic> paseo) {
    final v = paseo['precio'] ?? paseo['Precio'];
    final n = double.tryParse(v?.toString() ?? '');
    return n != null ? '\$${n.toStringAsFixed(2)}' : 'Sin precio';
  }

  String _duracion(Map<String, dynamic> paseo) =>
      '${paseo['duracionMinutos'] ?? paseo['DuracionMinutos'] ?? '0'} min';

  String? _fotoPerro(Map<String, dynamic> paseo) {
    final texto = (paseo['perroFotoUrl'] ?? paseo['perro']?['fotoUrl'])
        ?.toString()
        .trim();
    if (texto == null || texto.isEmpty || texto.toLowerCase() == 'null')
      return null;
    if (texto.startsWith('http')) return texto;
    final base = _baseUrl?.trim() ?? '';
    return base.isEmpty
        ? null
        : (texto.startsWith('/') ? '$base$texto' : '$base/$texto');
  }

  String _direccionRecogida(Map<String, dynamic> paseo) => _texto(
    paseo['ubicacionTexto'] ?? paseo['direccionRecogida'],
    fallback: 'Sin ubicación',
  );
  String _zonaRecogida(Map<String, dynamic> paseo) =>
      _texto(paseo['zonaRecogida'] ?? paseo['zona'], fallback: 'Sin zona');

  List<Map<String, dynamic>> get _paseosFiltrados {
    final busqueda = _busquedaController.text.trim().toLowerCase();
    return _paseos.where((p) {
      final coincideEstado =
          _filtroEstado == 'Todos' ||
          _normalizarEstado(_estado(p)) == _normalizarEstado(_filtroEstado);
      final texto = [
        _nombrePerro(p),
        _nombrePaseador(p),
        _estado(p),
        _zonaRecogida(p),
      ].join(' ').toLowerCase();
      return coincideEstado && (busqueda.isEmpty || texto.contains(busqueda));
    }).toList()..sort((a, b) {
      final fa = _fechaDate(a);
      final fb = _fechaDate(b);
      if (fa == null || fb == null) return 0;
      final aAct = _estaPendiente(a) || _estaAceptado(a) || _estaEnCurso(a);
      final bAct = _estaPendiente(b) || _estaAceptado(b) || _estaEnCurso(b);
      if (aAct != bAct) return aAct ? -1 : 1;
      return aAct ? fa.compareTo(fb) : fb.compareTo(fa);
    });
  }

  int _conteoPorEstado(String f) => f == 'Todos'
      ? _paseos.length
      : _paseos
            .where((p) => _normalizarEstado(_estado(p)) == _normalizarEstado(f))
            .length;

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _ejecutarAccion({
    required Future<Map<String, dynamic>> Function() accion,
    required String mensajeExito,
  }) async {
    if (_accionando) return;
    setState(() => _accionando = true);
    try {
      final result = await accion();
      if (!mounted) return;
      if (result['success'] == true) {
        _mostrarMensaje(mensajeExito);
        await _cargarPaseos();
      } else {
        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudo completar la acción.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error: $e');
    } finally {
      if (mounted) setState(() => _accionando = false);
    }
  }

  // --- FIX PARA CANCELAR PASEO (CONSERVANDO TU MODAL) ---
  Future<void> _cancelar(int id) async {
    final controller = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DogGoTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('Cancelar paseo', style: DogGoTheme.title(size: 22)),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Motivo de cancelación',
              hintText: 'Ej. Cambio de horario, emergencia...',
              filled: true,
              fillColor: DogGoTheme.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.cancel_rounded),
              label: const Text('Confirmar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;
    final motivo = controller.text.trim();
    if (motivo.isEmpty) {
      _mostrarMensaje('Escribe el motivo.');
      return;
    }

    // EL FIX: Esperamos a que cierre el modal para ejecutar el snackbar/petición
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ejecutarAccion(
        accion: () => PaseosService.cancelarPaseo(id, motivo: motivo),
        mensajeExito: 'Paseo cancelado correctamente.',
      );
    });
  }

  Future<void> _aceptar(int id) => _ejecutarAccion(
    accion: () => PaseosService.aceptarPaseo(id),
    mensajeExito: 'Paseo aceptado correctamente.',
  );
  Future<void> _rechazar(int id) => _ejecutarAccion(
    accion: () => PaseosService.rechazarPaseo(id),
    mensajeExito: 'Paseo rechazado correctamente.',
  );
  Future<void> _iniciar(int id) => _ejecutarAccion(
    accion: () => PaseosService.iniciarPaseo(id),
    mensajeExito: 'Paseo iniciado correctamente.',
  );
  Future<void> _finalizar(int id) => _ejecutarAccion(
    accion: () => PaseosService.finalizarPaseo(id),
    mensajeExito: 'Paseo finalizado correctamente.',
  );

  Future<void> _abrirDetalle(Map<String, dynamic> paseo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePaseoScreen(
          paseo: paseo,
          rol: _rolUsuario,
          onPaseoActualizado: _cargarPaseos,
        ),
      ),
    );
    if (mounted) await _cargarPaseos();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _paseosFiltrados;
    final enCurso = _paseos.where(_estaEnCurso).firstOrNull;

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarPaseos,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: DogGoTheme.cream2,
                      elevation: 0,
                      toolbarHeight: 72,
                      flexibleSpace: _buildTopBar(),
                    ),
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildResumen()),
                    if (enCurso != null)
                      SliverToBoxAdapter(
                        child: _buildPaseoEnCursoBanner(enCurso),
                      ),
                    SliverToBoxAdapter(child: _buildBuscador()),
                    SliverToBoxAdapter(child: _buildFiltros()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                      sliver: filtrados.isEmpty
                          ? SliverToBoxAdapter(child: _buildVacio())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _buildPaseoCard(filtrados[i]),
                                childCount: filtrados.length,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // --- TODOS TUS WIDGETS ORIGINALES "BONITOS" ---

  Widget _buildTopBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: DogGoTheme.cream2,
      border: Border(
        bottom: BorderSide(color: DogGoTheme.border.withOpacity(.72)),
      ),
    ),
    child: Row(
      children: [
        _TopIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        const DogGoLogo(size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mis paseos',
                style: DogGoTheme.body(size: 15, weight: FontWeight.w900),
              ),
              Text(
                SessionService.normalizarRol(_rolUsuario),
                style: DogGoTheme.subtitle(size: 11.5),
              ),
            ],
          ),
        ),
        _TopIconButton(
          icon: Icons.calendar_month_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CalendarioPaseosScreen(paseos: _paseos, rol: _rolUsuario),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _TopIconButton(icon: Icons.refresh_rounded, onTap: _cargarPaseos),
      ],
    ),
  );

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DogGoTheme.border.withOpacity(.78)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _esPaseador ? 'Panel de paseos' : 'Tus paseos',
            style: DogGoTheme.title(size: 31),
          ),
          const SizedBox(height: 8),
          Text(
            _esPaseador
                ? 'Solicitudes y servicios activos.'
                : 'Reservas y seguimiento de tus perros.',
            style: DogGoTheme.subtitle(size: 14.5),
          ),
        ],
      ),
    ),
  );

  Widget _buildResumen() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DogGoTheme.ink,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ResumenItem(
              value: _conteoPorEstado('Pendiente').toString(),
              label: 'Pend.',
              color: DogGoTheme.orange,
            ),
            _ResumenItem(
              value: _conteoPorEstado('Aceptado').toString(),
              label: 'Acept.',
              color: DogGoTheme.purple,
            ),
            _ResumenItem(
              value: _conteoPorEstado('EnCurso').toString(),
              label: 'Curso',
              color: DogGoTheme.green,
            ),
            _ResumenItem(
              value: _conteoPorEstado('Finalizado').toString(),
              label: 'Listos',
              color: DogGoTheme.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaseoEnCursoBanner(Map<String, dynamic> paseo) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DogGoTheme.green.withOpacity(.1),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DogGoTheme.green.withOpacity(.22)),
      ),
      child: Row(
        children: [
          _buildFotoPerro(
            _fotoPerro(paseo),
            DogGoTheme.green,
            Colors.white,
            size: 50,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'En curso: ${_nombrePerro(paseo)}',
              style: DogGoTheme.title(size: 18),
            ),
          ),
          _TopIconButton(
            icon: Icons.my_location_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MapaPaseoScreen(paseo: paseo)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildBuscador() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Container(
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border.withOpacity(.82)),
      ),
      child: TextField(
        controller: _busquedaController,
        decoration: const InputDecoration(
          hintText: 'Buscar...',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ),
  );

  Widget _buildFiltros() => SizedBox(
    height: 58,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      scrollDirection: Axis.horizontal,
      itemCount: _filtros.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final f = _filtros[i];
        final sel = f == _filtroEstado;
        return ActionChip(
          label: Text(f),
          onPressed: () => setState(() => _filtroEstado = f),
          backgroundColor: sel ? DogGoTheme.teal : DogGoTheme.card,
          labelStyle: TextStyle(color: sel ? Colors.white : DogGoTheme.ink),
        );
      },
    ),
  );

  Widget _buildPaseoCard(Map<String, dynamic> paseo) {
    final est = _estado(paseo);
    final col = _colorEstado(est);
    final id = _idPaseo(paseo);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DogGoTheme.border.withOpacity(.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildFotoPerro(
                  _fotoPerro(paseo),
                  col,
                  col.withOpacity(.1),
                  size: 60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombrePerro(paseo),
                        style: DogGoTheme.title(size: 19),
                      ),
                      Text(
                        '${_fechaCompacta(paseo)} • ${_horaCompacta(paseo)}',
                        style: DogGoTheme.subtitle(size: 12),
                      ),
                    ],
                  ),
                ),
                _EstadoBadge(
                  estado: _estadoLegible(est),
                  color: col,
                  surface: col.withOpacity(.1),
                  icono: _iconoEstado(est),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoBlock(
                    icono: Icons.timer,
                    label: 'Duración',
                    value: _duracion(paseo),
                    color: DogGoTheme.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoBlock(
                    icono: Icons.attach_money,
                    label: 'Precio',
                    value: _precio(paseo),
                    color: DogGoTheme.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _BotonPaseo(
                  texto: 'Chat',
                  icono: Icons.chat,
                  primary: false,
                  onPressed: () {
                    final id = _idPaseo(paseo);
                    if (id != null)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPaseoScreen(
                            paseoId: id,
                            nombrePerro: _nombrePerro(paseo),
                            nombreOtroUsuario: _esPaseador
                                ? _nombreDuenio(paseo)
                                : _nombrePaseador(paseo),
                          ),
                        ),
                      );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotonPaseo(
                    texto: 'Ver Detalle',
                    icono: Icons.visibility,
                    primary: true,
                    onPressed: () => _abrirDetalle(paseo),
                  ),
                ),
                if (id != null && _puedeCancelar(paseo)) ...[
                  const SizedBox(width: 8),
                  _BotonAccionChico(
                    texto: 'X',
                    icono: Icons.cancel,
                    color: DogGoTheme.red,
                    onPressed: () => _cancelar(id),
                    outlined: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoPerro(String? f, Color c, Color s, {double size = 60}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: s,
          borderRadius: BorderRadius.circular(20),
        ),
        child: f != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  f,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.pets, color: c),
                ),
              )
            : Icon(Icons.pets, color: c),
      );

  Widget _buildVacio() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 60, color: DogGoTheme.muted),
          const SizedBox(height: 10),
          Text('No hay paseos', style: DogGoTheme.subtitle()),
        ],
      ),
    ),
  );
}

// --- COMPONENTES AUXILIARES ORIGINALES ---

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: DogGoTheme.card,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: DogGoTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20),
      ),
    ),
  );
}

class _ResumenItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _ResumenItem({
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: DogGoTheme.title(size: 20, color: Colors.white)),
      Text(
        label,
        style: DogGoTheme.subtitle(
          size: 10,
          color: Colors.white.withOpacity(.7),
        ),
      ),
    ],
  );
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  final Color color, surface;
  final IconData icono;
  const _EstadoBadge({
    required this.estado,
    required this.color,
    required this.surface,
    required this.icono,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icono, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          estado,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _InfoBlock extends StatelessWidget {
  final IconData icono;
  final String label, value;
  final Color color;
  const _InfoBlock({
    required this.icono,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: DogGoTheme.cream2,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: DogGoTheme.subtitle(size: 10)),
          ],
        ),
        Text(value, style: DogGoTheme.body(size: 12, weight: FontWeight.w900)),
      ],
    ),
  );
}

class _BotonPaseo extends StatelessWidget {
  final String texto;
  final IconData icono;
  final bool primary;
  final VoidCallback onPressed;
  const _BotonPaseo({
    required this.texto,
    required this.icono,
    required this.primary,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icono, size: 16),
    label: Text(texto, style: const TextStyle(fontSize: 12)),
    style: ElevatedButton.styleFrom(
      backgroundColor: primary ? DogGoTheme.teal : Colors.white,
      foregroundColor: primary ? Colors.white : DogGoTheme.ink,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DogGoTheme.border),
      ),
    ),
  );
}

class _BotonAccionChico extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback onPressed;
  final bool outlined;
  const _BotonAccionChico({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icono, color: color),
    style: IconButton.styleFrom(
      backgroundColor: outlined ? color.withOpacity(.1) : color,
      foregroundColor: outlined ? color : Colors.white,
    ),
  );
}
