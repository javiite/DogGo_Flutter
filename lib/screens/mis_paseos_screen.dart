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

  String get _rolUsuario {
    return _rolReal ?? widget.rol ?? '';
  }

  bool get _esPaseador {
    return SessionService.esPaseadorRol(_rolUsuario);
  }

  bool get _esDuenio {
    return SessionService.esDuenioRol(_rolUsuario);
  }

  Future<void> _inicializar() async {
    await _cargarBaseUrl();
    await _cargarRol();
    await _cargarPaseos();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = url;
    });
  }

  Future<void> _cargarRol() async {
    try {
      final rol = await SessionService.obtenerRol();

      if (!mounted) return;

      setState(() {
        _rolReal = rol ?? widget.rol;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _rolReal = widget.rol;
      });
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
      final posibleLista = datos['data'] ??
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
    final valor = paseo['id'] ??
        paseo['Id'] ??
        paseo['paseoId'] ??
        paseo['PaseoId'];

    if (valor is int) return valor;

    return int.tryParse(valor?.toString() ?? '');
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  double? _doubleSeguro(dynamic valor) {
    if (valor == null) return null;

    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is num) return valor.toDouble();

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return double.tryParse(texto);
  }

  String _estado(Map<String, dynamic> paseo) {
    return _texto(
      paseo['estado'] ?? paseo['Estado'],
      fallback: 'Pendiente',
    );
  }

  String _normalizarEstado(String estado) {
    return estado.replaceAll(' ', '').toLowerCase();
  }

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

  bool _estaPendiente(Map<String, dynamic> paseo) {
    return _normalizarEstado(_estado(paseo)) == 'pendiente';
  }

  bool _estaAceptado(Map<String, dynamic> paseo) {
    return _normalizarEstado(_estado(paseo)) == 'aceptado';
  }

  bool _estaEnCurso(Map<String, dynamic> paseo) {
    return _normalizarEstado(_estado(paseo)) == 'encurso';
  }

  bool _estaFinalizado(Map<String, dynamic> paseo) {
    return _normalizarEstado(_estado(paseo)) == 'finalizado';
  }

  bool _estaCancelado(Map<String, dynamic> paseo) {
    return _normalizarEstado(_estado(paseo)) == 'cancelado';
  }

  bool _puedeAceptar(Map<String, dynamic> paseo) {
    return _esPaseador && _estaPendiente(paseo);
  }

  bool _puedeRechazar(Map<String, dynamic> paseo) {
    return _esPaseador && _estaPendiente(paseo);
  }

  bool _puedeIniciar(Map<String, dynamic> paseo) {
    return _esPaseador && _estaAceptado(paseo);
  }

  bool _puedeFinalizar(Map<String, dynamic> paseo) {
    return _esPaseador && _estaEnCurso(paseo);
  }

  bool _puedeCancelar(Map<String, dynamic> paseo) {
    final terminado = _estaFinalizado(paseo) || _estaCancelado(paseo);

    if (terminado) return false;

    return _esPaseador || _esDuenio;
  }

  bool _tieneAccionesRapidas(Map<String, dynamic> paseo) {
    return _puedeAceptar(paseo) ||
        _puedeRechazar(paseo) ||
        _puedeIniciar(paseo) ||
        _puedeFinalizar(paseo) ||
        _puedeCancelar(paseo);
  }

  String _nombrePerro(Map<String, dynamic> paseo) {
    return _texto(
      paseo['perroNombre'] ??
          paseo['nombrePerro'] ??
          paseo['PerroNombre'] ??
          paseo['NombrePerro'] ??
          paseo['perro']?['nombre'] ??
          paseo['perro']?['Nombre'] ??
          paseo['Perro']?['nombre'] ??
          paseo['Perro']?['Nombre'],
      fallback: 'Perro',
    );
  }

  String _nombrePaseador(Map<String, dynamic> paseo) {
    final nombre = paseo['paseadorNombre'] ??
        paseo['nombrePaseador'] ??
        paseo['PaseadorNombre'] ??
        paseo['NombrePaseador'] ??
        paseo['paseador']?['nombre'] ??
        paseo['paseador']?['Nombre'] ??
        paseo['paseador']?['usuario']?['nombre'] ??
        paseo['paseador']?['Usuario']?['Nombre'] ??
        paseo['Paseador']?['usuario']?['nombre'] ??
        paseo['Paseador']?['Usuario']?['Nombre'];

    final apellido = paseo['paseadorApellido'] ??
        paseo['apellidoPaseador'] ??
        paseo['PaseadorApellido'] ??
        paseo['ApellidoPaseador'] ??
        paseo['paseador']?['apellido'] ??
        paseo['paseador']?['Apellido'] ??
        paseo['paseador']?['usuario']?['apellido'] ??
        paseo['paseador']?['Usuario']?['Apellido'] ??
        paseo['Paseador']?['usuario']?['apellido'] ??
        paseo['Paseador']?['Usuario']?['Apellido'];

    final nombreTxt = _texto(nombre, fallback: '');
    final apellidoTxt = _texto(apellido, fallback: '');

    final completo = '$nombreTxt $apellidoTxt'.trim();

    return completo.isEmpty ? 'Paseador no asignado' : completo;
  }

  String _nombreDuenio(Map<String, dynamic> paseo) {
    final nombre = paseo['duenioNombre'] ??
        paseo['nombreDuenio'] ??
        paseo['dueñoNombre'] ??
        paseo['DuenioNombre'] ??
        paseo['NombreDuenio'] ??
        paseo['perro']?['duenio']?['nombre'] ??
        paseo['perro']?['usuario']?['nombre'] ??
        paseo['perro']?['Usuario']?['Nombre'] ??
        paseo['Perro']?['Usuario']?['Nombre'];

    final apellido = paseo['duenioApellido'] ??
        paseo['apellidoDuenio'] ??
        paseo['dueñoApellido'] ??
        paseo['DuenioApellido'] ??
        paseo['ApellidoDuenio'] ??
        paseo['perro']?['duenio']?['apellido'] ??
        paseo['perro']?['usuario']?['apellido'] ??
        paseo['perro']?['Usuario']?['Apellido'] ??
        paseo['Perro']?['Usuario']?['Apellido'];

    final nombreTxt = _texto(nombre, fallback: '');
    final apellidoTxt = _texto(apellido, fallback: '');

    final completo = '$nombreTxt $apellidoTxt'.trim();

    return completo.isEmpty ? 'Dueño' : completo;
  }

  String _fechaBonita(dynamic valor) {
    if (valor == null) return 'Sin fecha';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return valor.toString();

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  String _fechaPrincipal(Map<String, dynamic> paseo) {
    final valor = paseo['fechaProgramada'] ??
        paseo['FechaProgramada'] ??
        paseo['fechaInicio'] ??
        paseo['FechaInicio'] ??
        paseo['fecha'] ??
        paseo['Fecha'];

    return _fechaBonita(valor);
  }

  DateTime? _fechaDate(Map<String, dynamic> paseo) {
    final valor = paseo['fechaProgramada'] ??
        paseo['FechaProgramada'] ??
        paseo['fechaInicio'] ??
        paseo['FechaInicio'] ??
        paseo['fecha'] ??
        paseo['Fecha'];

    final fecha = DateTime.tryParse(valor?.toString() ?? '');

    return fecha?.toLocal();
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

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  String _precio(Map<String, dynamic> paseo) {
    final valor = paseo['precio'] ?? paseo['Precio'];

    if (valor == null) return 'Sin precio';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    return '\$${numero.toStringAsFixed(2)}';
  }

  String _duracion(Map<String, dynamic> paseo) {
    final valor = paseo['duracionMinutos'] ?? paseo['DuracionMinutos'];

    if (valor == null) return 'Sin duración';

    return '$valor min';
  }

  String? _fotoPerro(Map<String, dynamic> paseo) {
    final valor = paseo['perroFotoUrl'] ??
        paseo['fotoPerroUrl'] ??
        paseo['PerroFotoUrl'] ??
        paseo['FotoPerroUrl'] ??
        paseo['perro']?['fotoUrl'] ??
        paseo['perro']?['FotoUrl'] ??
        paseo['perro']?['imagenUrl'] ??
        paseo['perro']?['ImagenUrl'] ??
        paseo['Perro']?['fotoUrl'] ??
        paseo['Perro']?['FotoUrl'] ??
        paseo['Perro']?['imagenUrl'] ??
        paseo['Perro']?['ImagenUrl'];

    final texto = valor?.toString().trim();

    if (texto == null || texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    if (texto.startsWith('http://') || texto.startsWith('https://')) {
      return texto;
    }

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return null;

    if (texto.startsWith('/')) {
      return '$base$texto';
    }

    return '$base/$texto';
  }

  String _direccionRecogida(Map<String, dynamic> paseo) {
    return _texto(
      paseo['ubicacionTexto'] ??
          paseo['ubicacionRecogidaTexto'] ??
          paseo['direccionRecogida'] ??
          paseo['referenciasRecogida'] ??
          paseo['direccion'] ??
          paseo['UbicacionTexto'] ??
          paseo['UbicacionRecogidaTexto'] ??
          paseo['DireccionRecogida'] ??
          paseo['ReferenciasRecogida'] ??
          paseo['Direccion'],
      fallback: 'Sin ubicación de recogida',
    );
  }

  String _zonaRecogida(Map<String, dynamic> paseo) {
    return _texto(
      paseo['zonaRecogida'] ?? paseo['ZonaRecogida'] ?? paseo['zona'] ?? paseo['Zona'],
      fallback: 'Sin zona',
    );
  }

  double? _latitudRecogida(Map<String, dynamic> paseo) {
    return _doubleSeguro(
      paseo['latitudRecogida'] ??
          paseo['latRecogida'] ??
          paseo['ubicacionLatitud'] ??
          paseo['LatitudRecogida'] ??
          paseo['LatRecogida'] ??
          paseo['UbicacionLatitud'],
    );
  }

  double? _longitudRecogida(Map<String, dynamic> paseo) {
    return _doubleSeguro(
      paseo['longitudRecogida'] ??
          paseo['lngRecogida'] ??
          paseo['lonRecogida'] ??
          paseo['ubicacionLongitud'] ??
          paseo['LongitudRecogida'] ??
          paseo['LngRecogida'] ??
          paseo['LonRecogida'] ??
          paseo['UbicacionLongitud'],
    );
  }

  bool _tieneCoordenadasRecogida(Map<String, dynamic> paseo) {
    return _latitudRecogida(paseo) != null && _longitudRecogida(paseo) != null;
  }

  List<Map<String, dynamic>> get _paseosFiltrados {
    final busqueda = _busquedaController.text.trim().toLowerCase();

    final lista = _paseos.where((paseo) {
      final estado = _estado(paseo);
      final estadoNormalizado = _normalizarEstado(estado);
      final filtroNormalizado = _normalizarEstado(_filtroEstado);

      final coincideEstado =
          _filtroEstado == 'Todos' || estadoNormalizado == filtroNormalizado;

      final textoBusqueda = [
        _nombrePerro(paseo),
        _nombrePaseador(paseo),
        _nombreDuenio(paseo),
        estado,
        _fechaPrincipal(paseo),
        _precio(paseo),
        _duracion(paseo),
        _direccionRecogida(paseo),
        _zonaRecogida(paseo),
      ].join(' ').toLowerCase();

      final coincideBusqueda = busqueda.isEmpty || textoBusqueda.contains(busqueda);

      return coincideEstado && coincideBusqueda;
    }).toList();

    lista.sort((a, b) {
      final fa = _fechaDate(a);
      final fb = _fechaDate(b);

      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;

      final aActivo = _estaPendiente(a) || _estaAceptado(a) || _estaEnCurso(a);
      final bActivo = _estaPendiente(b) || _estaAceptado(b) || _estaEnCurso(b);

      if (aActivo != bActivo) return aActivo ? -1 : 1;

      if (aActivo && bActivo) return fa.compareTo(fb);

      return fb.compareTo(fa);
    });

    return lista;
  }

  int _conteoPorEstado(String filtro) {
    if (filtro == 'Todos') return _paseos.length;

    final normalizado = _normalizarEstado(filtro);

    return _paseos.where((paseo) {
      return _normalizarEstado(_estado(paseo)) == normalizado;
    }).length;
  }

  int get _conteoActivos {
    return _paseos.where((paseo) {
      return _estaPendiente(paseo) || _estaAceptado(paseo) || _estaEnCurso(paseo);
    }).length;
  }

  int get _conteoEnCurso {
    return _paseos.where(_estaEnCurso).length;
  }


  Map<String, dynamic>? get _proximoPaseo {
    final ahora = DateTime.now();

    final lista = _paseos.where((paseo) {
      final fecha = _fechaDate(paseo);

      if (fecha == null) return false;
      if (_estaFinalizado(paseo) || _estaCancelado(paseo)) return false;

      return fecha.isAfter(ahora.subtract(const Duration(hours: 4)));
    }).toList();

    if (lista.isEmpty) return null;

    lista.sort((a, b) {
      final fa = _fechaDate(a);
      final fb = _fechaDate(b);

      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;

      return fa.compareTo(fb);
    });

    return lista.first;
  }

  Map<String, dynamic>? get _paseoEnCurso {
    final lista = _paseos.where(_estaEnCurso).toList();

    if (lista.isEmpty) return null;

    lista.sort((a, b) {
      final fa = _fechaDate(a);
      final fb = _fechaDate(b);

      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;

      return fb.compareTo(fa);
    });

    return lista.first;
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _ejecutarAccion({
    required Future<Map<String, dynamic>> Function() accion,
    required String mensajeExito,
  }) async {
    if (_accionando) return;

    setState(() {
      _accionando = true;
    });

    try {
      final result = await accion();

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(result['message']?.toString() ?? mensajeExito);
        await _cargarPaseos();
      } else {
        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudo completar la acción.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Ocurrió un error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _accionando = false;
        });
      }
    }
  }

  Future<void> _aceptar(int id) async {
    await _ejecutarAccion(
      accion: () => PaseosService.aceptarPaseo(id),
      mensajeExito: 'Paseo aceptado correctamente.',
    );
  }

  Future<void> _rechazar(int id) async {
    await _ejecutarAccion(
      accion: () => PaseosService.rechazarPaseo(id),
      mensajeExito: 'Paseo rechazado correctamente.',
    );
  }

  Future<void> _iniciar(int id) async {
    await _ejecutarAccion(
      accion: () => PaseosService.iniciarPaseo(id),
      mensajeExito: 'Paseo iniciado correctamente.',
    );
  }

  Future<void> _finalizar(int id) async {
    await _ejecutarAccion(
      accion: () => PaseosService.finalizarPaseo(id),
      mensajeExito: 'Paseo finalizado correctamente.',
    );
  }

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
          title: Text(
            'Cancelar paseo',
            style: DogGoTheme.title(size: 22),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Motivo de cancelación',
              hintText: 'Ej. Cambio de horario, lluvia, emergencia...',
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
              label: const Text('Cancelar paseo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        );
      },
    );

    final motivo = controller.text.trim();
    controller.dispose();

    if (confirmar != true) return;

    if (motivo.isEmpty) {
      _mostrarMensaje('Escribe el motivo de cancelación.');
      return;
    }

    await _ejecutarAccion(
      accion: () => PaseosService.cancelarPaseo(id, motivo: motivo),
      mensajeExito: 'Paseo cancelado correctamente.',
    );
  }

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

    if (mounted) {
      await _cargarPaseos();
    }
  }

  void _abrirMapa(Map<String, dynamic> paseo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaPaseoScreen(
          paseo: paseo,
        ),
      ),
    );
  }

  void _abrirChat(Map<String, dynamic> paseo) {
    final id = _idPaseo(paseo);

    if (id == null) {
      _mostrarMensaje('No se encontró el ID del paseo.');
      return;
    }

    final nombreOtroUsuario = _esPaseador ? _nombreDuenio(paseo) : _nombrePaseador(paseo);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPaseoScreen(
          paseoId: id,
          nombrePerro: _nombrePerro(paseo),
          nombreOtroUsuario: nombreOtroUsuario,
        ),
      ),
    );
  }

  void _abrirCalendario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarioPaseosScreen(
          paseos: _paseos,
          rol: _rolUsuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paseosFiltrados = _paseosFiltrados;

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarPaseos,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: DogGoTheme.cream2,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      toolbarHeight: 72,
                      flexibleSpace: _buildTopBar(),
                    ),
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildResumen()),
                    if (_paseoEnCurso != null)
                      SliverToBoxAdapter(
                        child: _buildPaseoEnCursoBanner(_paseoEnCurso!),
                      ),
                    SliverToBoxAdapter(child: _buildBuscador()),
                    SliverToBoxAdapter(child: _buildFiltros()),
                    if (_accionando)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: LinearProgressIndicator(),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: _error != null
                            ? _buildError()
                            : paseosFiltrados.isEmpty
                                ? _buildVacio()
                                : _buildListaPaseos(paseosFiltrados),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 36)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2.withOpacity(.96),
        border: Border(
          bottom: BorderSide(color: DogGoTheme.border.withOpacity(.72)),
        ),
      ),
      child: Row(
        children: [
          _TopIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Volver',
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.body(
                    size: 15,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SessionService.normalizarRol(_rolUsuario),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.subtitle(size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TopIconButton(
            icon: Icons.calendar_month_rounded,
            tooltip: 'Calendario',
            onTap: _abrirCalendario,
          ),
          const SizedBox(width: 8),
          _TopIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onTap: _cargarPaseos,
          ),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    final titulo = _esPaseador ? 'Panel de paseos' : 'Tus paseos';

    final subtitulo = _esPaseador
        ? 'Solicitudes, servicios activos, mapa y comunicación con dueños en un solo flujo.'
        : 'Reservas, estados, ubicación de recogida, mapa, chat y seguimiento de tus perros.';

    final proximo = _proximoPaseo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Container(
        width: double.infinity,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'SEGUIMIENTO',
                    style: DogGoTheme.label(size: 10.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    proximo == null ? 'Sin próximo paseo activo' : 'Próximo: ${_fechaCompacta(proximo)} · ${_horaCompacta(proximo)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: DogGoTheme.subtitle(size: 11.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              style: DogGoTheme.title(size: 31),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: DogGoTheme.subtitle(size: 14.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeaderAction(
                    icon: Icons.calendar_month_rounded,
                    title: 'Calendario',
                    subtitle: 'Vista mensual',
                    color: DogGoTheme.teal,
                    onTap: _abrirCalendario,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderAction(
                    icon: Icons.refresh_rounded,
                    title: 'Actualizar',
                    subtitle: 'Sincronizar',
                    color: DogGoTheme.orange,
                    onTap: _cargarPaseos,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildResumen() {
    final pendientes = _conteoPorEstado('Pendiente');
    final aceptados = _conteoPorEstado('Aceptado');
    final enCurso = _conteoPorEstado('EnCurso');
    final finalizados = _conteoPorEstado('Finalizado');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DogGoTheme.ink,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: DogGoTheme.ink.withOpacity(.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_paseos.length} paseos registrados',
                        style: DogGoTheme.title(size: 23, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _conteoEnCurso > 0
                            ? '$_conteoEnCurso servicio en seguimiento activo.'
                            : 'Todo en orden. No hay paseos corriendo ahora.',
                        style: DogGoTheme.subtitle(
                          size: 12.5,
                          color: Colors.white.withOpacity(.76),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(.08)),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ResumenItem(
                    value: _conteoActivos.toString(),
                    label: 'Activos',
                    color: DogGoTheme.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResumenItem(
                    value: pendientes.toString(),
                    label: 'Pend.',
                    color: DogGoTheme.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResumenItem(
                    value: aceptados.toString(),
                    label: 'Acept.',
                    color: DogGoTheme.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResumenItem(
                    value: enCurso.toString(),
                    label: 'Curso',
                    color: DogGoTheme.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResumenItem(
                    value: finalizados.toString(),
                    label: 'Listos',
                    color: DogGoTheme.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPaseoEnCursoBanner(Map<String, dynamic> paseo) {
    final foto = _fotoPerro(paseo);
    final id = _idPaseo(paseo);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DogGoTheme.green.withOpacity(.10),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: DogGoTheme.green.withOpacity(.22)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildFotoPerro(
                  foto,
                  DogGoTheme.green,
                  Colors.white.withOpacity(.76),
                  size: 64,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: DogGoTheme.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'EN CURSO',
                            style: DogGoTheme.body(
                              size: 11,
                              color: DogGoTheme.green,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _nombrePerro(paseo),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.title(size: 21),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _esPaseador
                            ? 'Dueño: ${_nombreDuenio(paseo)}'
                            : 'Paseador: ${_nombrePaseador(paseo)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(size: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BotonPaseo(
                    texto: 'Mapa',
                    icono: Icons.my_location_rounded,
                    primary: true,
                    onPressed: () => _abrirMapa(paseo),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BotonPaseo(
                    texto: 'Chat',
                    icono: Icons.chat_rounded,
                    primary: false,
                    onPressed: () => _abrirChat(paseo),
                  ),
                ),
                if (_esPaseador && id != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BotonAccionChico(
                      texto: 'Finalizar',
                      icono: Icons.flag_rounded,
                      color: DogGoTheme.purple,
                      onPressed: _accionando ? null : () => _finalizar(id),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DogGoTheme.border.withOpacity(.82)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.025),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _busquedaController,
          decoration: InputDecoration(
            hintText: 'Buscar perro, persona, estado o ubicación',
            hintStyle: DogGoTheme.subtitle(size: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: DogGoTheme.muted),
            suffixIcon: _busquedaController.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: _busquedaController.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }


  Widget _buildFiltros() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final seleccionado = filtro == _filtroEstado;
          final conteo = _conteoPorEstado(filtro);
          final color = filtro == 'Todos' ? DogGoTheme.ink : _colorEstado(filtro);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _filtroEstado = filtro;
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: seleccionado ? color : DogGoTheme.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: seleccionado ? color : DogGoTheme.border.withOpacity(.85),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filtro != 'Todos') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: seleccionado ? Colors.white : color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      '${_estadoLegible(filtro)} · $conteo',
                      style: DogGoTheme.body(
                        size: 12,
                        color: seleccionado ? Colors.white : DogGoTheme.ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildListaPaseos(List<Map<String, dynamic>> paseosFiltrados) {
    final busquedaActiva = _busquedaController.text.trim().isNotEmpty;

    if (_filtroEstado != 'Todos' || busquedaActiva) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ListaHeader(
            titulo: 'Resultados',
            subtitulo: '${paseosFiltrados.length} paseo(s) encontrados',
            icono: Icons.manage_search_rounded,
            color: DogGoTheme.teal,
          ),
          const SizedBox(height: 12),
          ...paseosFiltrados.map(_buildPaseoCard),
        ],
      );
    }

    final enCurso = paseosFiltrados.where(_estaEnCurso).toList();
    final aceptados = paseosFiltrados.where(_estaAceptado).toList();
    final pendientes = paseosFiltrados.where(_estaPendiente).toList();
    final finalizados = paseosFiltrados.where(_estaFinalizado).toList();
    final cancelados = paseosFiltrados.where(_estaCancelado).toList();
    final otros = paseosFiltrados.where((paseo) {
      return !_estaEnCurso(paseo) &&
          !_estaAceptado(paseo) &&
          !_estaPendiente(paseo) &&
          !_estaFinalizado(paseo) &&
          !_estaCancelado(paseo);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (enCurso.isNotEmpty)
          _buildSeccionPaseos(
            titulo: 'En curso',
            subtitulo: 'Seguimiento activo y mapa en vivo',
            icono: Icons.my_location_rounded,
            color: DogGoTheme.green,
            paseos: enCurso,
          ),
        if (aceptados.isNotEmpty)
          _buildSeccionPaseos(
            titulo: 'Aceptados',
            subtitulo: 'Listos para iniciar',
            icono: Icons.verified_rounded,
            color: DogGoTheme.purple,
            paseos: aceptados,
          ),
        if (pendientes.isNotEmpty)
          _buildSeccionPaseos(
            titulo: 'Pendientes',
            subtitulo: _esPaseador ? 'Solicitudes por responder' : 'Esperando respuesta del paseador',
            icono: Icons.schedule_rounded,
            color: DogGoTheme.orange,
            paseos: pendientes,
          ),
        if (finalizados.isNotEmpty)
          _buildSeccionPaseos(
            titulo: 'Finalizados',
            subtitulo: 'Historial de servicios completados',
            icono: Icons.flag_rounded,
            color: DogGoTheme.teal,
            paseos: finalizados,
          ),
        if (cancelados.isNotEmpty)
          _buildSeccionPaseos(
            titulo: 'Cancelados',
            subtitulo: 'Servicios que no se completaron',
            icono: Icons.cancel_rounded,
            color: DogGoTheme.red,
            paseos: cancelados,
          ),
        if (otros.isNotEmpty)
          _buildSeccionPaseos(
            titulo: 'Otros estados',
            subtitulo: 'Paseos con estado diferente',
            icono: Icons.info_outline_rounded,
            color: DogGoTheme.muted,
            paseos: otros,
          ),
      ],
    );
  }

  Widget _buildSeccionPaseos({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required List<Map<String, dynamic>> paseos,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ListaHeader(
            titulo: '$titulo (${paseos.length})',
            subtitulo: subtitulo,
            icono: icono,
            color: color,
          ),
          const SizedBox(height: 12),
          ...paseos.map(_buildPaseoCard),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: DogGoTheme.redLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: DogGoTheme.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los paseos',
            style: DogGoTheme.title(size: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: DogGoTheme.subtitle(size: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _cargarPaseos,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: DogGoTheme.primaryButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.route_rounded,
              size: 52,
              color: DogGoTheme.teal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay paseos para mostrar',
            style: DogGoTheme.title(size: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba con otro filtro, limpia la búsqueda o actualiza la lista.',
            style: DogGoTheme.subtitle(size: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _busquedaController.clear();
              setState(() {
                _filtroEstado = 'Todos';
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

  Widget _buildPaseoCard(Map<String, dynamic> paseo) {
    final id = _idPaseo(paseo);
    final estado = _estado(paseo);
    final color = _colorEstado(estado);
    final surface = _surfaceEstado(estado);
    final foto = _fotoPerro(paseo);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrirDetalle(paseo),
          borderRadius: BorderRadius.circular(26),
          child: Container(
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: DogGoTheme.border.withOpacity(.86)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.038),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    color: color,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFotoPerro(foto, color, surface, size: 66),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _nombrePerro(paseo),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: DogGoTheme.title(size: 21),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _EstadoBadge(
                                          estado: _estadoLegible(estado),
                                          color: color,
                                          surface: surface,
                                          icono: _iconoEstado(estado),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _esPaseador
                                          ? 'Dueño: ${_nombreDuenio(paseo)}'
                                          : 'Paseador: ${_nombrePaseador(paseo)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: DogGoTheme.subtitle(size: 12.8),
                                    ),
                                    const SizedBox(height: 9),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _InlineMetric(
                                            icono: Icons.calendar_today_rounded,
                                            texto: _fechaCompacta(paseo),
                                            color: DogGoTheme.teal,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _InlineMetric(
                                            icono: Icons.schedule_rounded,
                                            texto: _horaCompacta(paseo),
                                            color: DogGoTheme.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildInfoPaseo(paseo),
                          const SizedBox(height: 12),
                          _buildUbicacionPreview(paseo),
                          const SizedBox(height: 10),
                          _buildEstadoPreview(paseo, color, surface),
                          const SizedBox(height: 12),
                          _buildBotonesBase(paseo),
                          if (id != null && _tieneAccionesRapidas(paseo)) ...[
                            const SizedBox(height: 10),
                            _buildAccionesRapidas(id: id, paseo: paseo),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildPaseoHero(
    Map<String, dynamic> paseo,
    String? foto,
    Color color,
    Color surface,
  ) {
    final tieneUrl = foto != null && (foto.startsWith('http://') || foto.startsWith('https://'));

    return SizedBox(
      height: 155,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (tieneUrl)
            Image.network(
              foto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _HeroPlaceholder(color: color, surface: surface);
              },
            )
          else
            _HeroPlaceholder(color: color, surface: surface),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.04),
                    Colors.black.withOpacity(.46),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 15,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _nombrePerro(paseo),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.title(size: 27, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _esPaseador
                            ? 'Dueño: ${_nombreDuenio(paseo)}'
                            : 'Paseador: ${_nombrePaseador(paseo)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(
                          size: 13,
                          color: Colors.white.withOpacity(.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _EstadoBadge(
                  estado: _estadoLegible(_estado(paseo)),
                  color: color,
                  surface: Colors.white.withOpacity(.94),
                  icono: _iconoEstado(_estado(paseo)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPerro(
    String? foto,
    Color color,
    Color surface, {
    double size = 74,
  }) {
    final tieneUrl = foto != null && (foto.startsWith('http://') || foto.startsWith('https://'));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(size * .30),
      ),
      clipBehavior: Clip.antiAlias,
      child: tieneUrl
          ? Image.network(
              foto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.pets_rounded,
                  color: color,
                  size: size * .48,
                );
              },
            )
          : Icon(
              Icons.pets_rounded,
              color: color,
              size: size * .48,
            ),
    );
  }

  Widget _buildInfoPaseo(Map<String, dynamic> paseo) {
    return Row(
      children: [
        Expanded(
          child: _InfoBlock(
            icono: Icons.timer_rounded,
            label: 'Duración',
            value: _duracion(paseo),
            color: DogGoTheme.purple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoBlock(
            icono: Icons.attach_money_rounded,
            label: 'Precio',
            value: _precio(paseo),
            color: DogGoTheme.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoBlock(
            icono: Icons.place_rounded,
            label: 'Zona',
            value: _zonaRecogida(paseo),
            color: DogGoTheme.teal,
          ),
        ),
      ],
    );
  }


  Widget _buildUbicacionPreview(Map<String, dynamic> paseo) {
    final tieneUbicacion = _tieneCoordenadasRecogida(paseo);
    final direccion = _direccionRecogida(paseo);
    final color = tieneUbicacion ? DogGoTheme.teal : DogGoTheme.orange;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DogGoTheme.border.withOpacity(.78)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tieneUbicacion ? Icons.home_work_rounded : Icons.location_off_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tieneUbicacion ? 'Recogida' : 'Ubicación pendiente',
                  style: DogGoTheme.body(
                    size: 12,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tieneUbicacion ? direccion : 'Este paseo todavía no tiene coordenadas de recogida.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.subtitle(size: 12.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEstadoPreview(
    Map<String, dynamic> paseo,
    Color color,
    Color surface,
  ) {
    String texto;
    IconData icono;

    if (_estaEnCurso(paseo)) {
      texto = 'Tracking activo. Abre el mapa para revisar la ruta en vivo.';
      icono = Icons.my_location_rounded;
    } else if (_estaFinalizado(paseo)) {
      texto = 'Servicio completado. El detalle conserva evidencias e historial.';
      icono = Icons.flag_rounded;
    } else if (_estaCancelado(paseo)) {
      texto = 'Cancelado. Se mantiene como historial del servicio.';
      icono = Icons.cancel_rounded;
    } else if (_estaAceptado(paseo)) {
      texto = _esPaseador
          ? 'Aceptado. Cuando sea momento puedes iniciarlo.'
          : 'Aceptado por el paseador. Mantente atento al inicio.';
      icono = Icons.verified_rounded;
    } else {
      texto = _esPaseador
          ? 'Solicitud nueva. Responde para confirmar disponibilidad.'
          : 'Solicitud enviada. Esperando respuesta del paseador.';
      icono = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface.withOpacity(.70),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: DogGoTheme.body(
                size: 12.2,
                color: DogGoTheme.ink,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBotonesBase(Map<String, dynamic> paseo) {
    return Row(
      children: [
        Expanded(
          child: _BotonPaseo(
            texto: 'Detalle',
            icono: Icons.visibility_rounded,
            primary: false,
            onPressed: () => _abrirDetalle(paseo),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BotonPaseo(
            texto: _estaEnCurso(paseo) ? 'Ruta' : 'Mapa',
            icono: _estaEnCurso(paseo) ? Icons.my_location_rounded : Icons.map_rounded,
            primary: true,
            onPressed: () => _abrirMapa(paseo),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BotonPaseo(
            texto: 'Chat',
            icono: Icons.chat_bubble_rounded,
            primary: false,
            onPressed: () => _abrirChat(paseo),
          ),
        ),
      ],
    );
  }


  Widget _buildAccionesRapidas({
    required int id,
    required Map<String, dynamic> paseo,
  }) {
    final acciones = <Widget>[];

    void agregarSeparador() {
      if (acciones.isNotEmpty) acciones.add(const SizedBox(width: 8));
    }

    if (_puedeAceptar(paseo)) {
      acciones.add(
        Expanded(
          child: _BotonAccionChico(
            texto: 'Aceptar',
            icono: Icons.check_rounded,
            color: DogGoTheme.green,
            onPressed: _accionando ? null : () => _aceptar(id),
          ),
        ),
      );
    }

    if (_puedeRechazar(paseo)) {
      agregarSeparador();
      acciones.add(
        Expanded(
          child: _BotonAccionChico(
            texto: 'Rechazar',
            icono: Icons.close_rounded,
            color: DogGoTheme.red,
            outlined: true,
            onPressed: _accionando ? null : () => _rechazar(id),
          ),
        ),
      );
    }

    if (_puedeIniciar(paseo)) {
      agregarSeparador();
      acciones.add(
        Expanded(
          child: _BotonAccionChico(
            texto: 'Iniciar',
            icono: Icons.play_arrow_rounded,
            color: DogGoTheme.green,
            onPressed: _accionando ? null : () => _iniciar(id),
          ),
        ),
      );
    }

    if (_puedeFinalizar(paseo)) {
      agregarSeparador();
      acciones.add(
        Expanded(
          child: _BotonAccionChico(
            texto: 'Finalizar',
            icono: Icons.flag_rounded,
            color: DogGoTheme.purple,
            onPressed: _accionando ? null : () => _finalizar(id),
          ),
        ),
      );
    }

    if (_puedeCancelar(paseo)) {
      agregarSeparador();
      acciones.add(
        Expanded(
          child: _BotonAccionChico(
            texto: 'Cancelar',
            icono: Icons.cancel_rounded,
            color: DogGoTheme.red,
            outlined: true,
            onPressed: _accionando ? null : () => _cancelar(id),
          ),
        ),
      );
    }

    if (acciones.isEmpty) return const SizedBox.shrink();

    return Row(children: acciones);
  }
}


class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DogGoTheme.border.withOpacity(.78)),
            ),
            child: Icon(icon, color: DogGoTheme.ink, size: 21),
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(.13)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.66),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 12.6,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(size: 10.6),
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

class _InlineMetric extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _InlineMetric({
    required this.icono,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DogGoTheme.border.withOpacity(.65)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.body(
                size: 11.2,
                color: DogGoTheme.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ResumenItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.07)),
      ),
      child: Column(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: DogGoTheme.title(size: 19, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.subtitle(
              size: 9.4,
              color: Colors.white.withOpacity(.72),
            ),
          ),
        ],
      ),
    );
  }
}


class _ListaHeader extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;

  const _ListaHeader({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icono, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: DogGoTheme.title(size: 19),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.subtitle(size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _EstadoBadge extends StatelessWidget {
  final String estado;
  final Color color;
  final Color surface;
  final IconData icono;

  const _EstadoBadge({
    required this.estado,
    required this.color,
    required this.surface,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              estado,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.body(
                size: 10,
                color: color,
                weight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _InfoBlock extends StatelessWidget {
  final IconData icono;
  final String label;
  final String value;
  final Color color;

  const _InfoBlock({
    required this.icono,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DogGoTheme.border.withOpacity(.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icono, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.subtitle(size: 9.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 11.5,
              color: DogGoTheme.ink,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}


class _HeroPlaceholder extends StatelessWidget {
  final Color color;
  final Color surface;

  const _HeroPlaceholder({
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -34,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.34),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.pets_rounded,
              color: color,
              size: 66,
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    if (primary) {
      return SizedBox(
        height: 42,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icono, size: 16),
          label: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.6, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: DogGoTheme.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            shape: shape,
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 16),
        label: Text(
          texto,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.6, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: DogGoTheme.ink,
          backgroundColor: DogGoTheme.cream2,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          side: BorderSide(color: DogGoTheme.border.withOpacity(.9), width: 1.1),
          shape: shape,
        ),
      ),
    );
  }
}


class _BotonAccionChico extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback? onPressed;
  final bool outlined;

  const _BotonAccionChico({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    if (outlined) {
      return SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icono, size: 16),
          label: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.4, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            backgroundColor: Colors.white.withOpacity(.62),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            side: BorderSide(color: color.withOpacity(.85), width: 1.05),
            shape: shape,
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 16),
        label: Text(
          texto,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.4, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          elevation: 0,
          shape: shape,
        ),
      ),
    );
  }
}

