import 'package:flutter/material.dart';

import '../services/paseos_service.dart';
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
  final PaseosService _paseosService = PaseosService();
  final TextEditingController _busquedaController = TextEditingController();

  List<Map<String, dynamic>> _paseos = [];
  bool _cargando = true;
  bool _accionando = false;
  String? _error;
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
    _cargarPaseos();

    _busquedaController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPaseos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await _obtenerMisPaseosCompatible();

      if (!mounted) return;

      setState(() {
        _paseos = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerMisPaseosCompatible() async {
    final dynamic service = _paseosService;
    dynamic respuesta;

    try {
      respuesta = await service.obtenerMisPaseos();
      return _normalizarLista(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.listarMisPaseos();
      return _normalizarLista(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.obtenerPaseos();
      return _normalizarLista(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.listarPaseos();
      return _normalizarLista(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.getMisPaseos();
      return _normalizarLista(respuesta);
    } on NoSuchMethodError catch (_) {}

    try {
      respuesta = await service.getPaseos();
      return _normalizarLista(respuesta);
    } on NoSuchMethodError catch (_) {}

    if (widget.usuarioId != null) {
      try {
        respuesta = await service.obtenerMisPaseos(widget.usuarioId);
        return _normalizarLista(respuesta);
      } on NoSuchMethodError catch (_) {}

      try {
        respuesta = await service.listarMisPaseos(widget.usuarioId);
        return _normalizarLista(respuesta);
      } on NoSuchMethodError catch (_) {}
    }

    throw Exception(
      'No encontré un método compatible para listar paseos en PaseosService.',
    );
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      datos = respuesta['data'] ??
          respuesta['paseos'] ??
          respuesta['items'] ??
          respuesta['resultado'] ??
          respuesta['result'] ??
          respuesta['value'];
    }

    if (datos is! List) return [];

    return datos
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  int? _idPaseo(Map<String, dynamic> paseo) {
    final valor = paseo['id'] ?? paseo['Id'] ?? paseo['paseoId'] ?? paseo['PaseoId'];

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

  String _estado(Map<String, dynamic> paseo) {
    return _texto(
      paseo['estado'] ?? paseo['Estado'],
      fallback: 'Pendiente',
    );
  }

  String _normalizarEstado(String estado) {
    return estado.replaceAll(' ', '').toLowerCase();
  }

  Color _colorEstado(String estado) {
    switch (_normalizarEstado(estado)) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptado':
        return Colors.blue;
      case 'encurso':
        return Colors.green;
      case 'finalizado':
        return Colors.purple;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _nombrePerro(Map<String, dynamic> paseo) {
    return _texto(
      paseo['perroNombre'] ??
          paseo['nombrePerro'] ??
          paseo['perro']?['nombre'] ??
          paseo['Perro']?['Nombre'],
      fallback: 'Perro',
    );
  }

  String _nombrePaseador(Map<String, dynamic> paseo) {
    final nombre = paseo['paseadorNombre'] ??
        paseo['nombrePaseador'] ??
        paseo['paseador']?['nombre'] ??
        paseo['paseador']?['usuario']?['nombre'] ??
        paseo['Paseador']?['Usuario']?['Nombre'];

    final apellido = paseo['paseadorApellido'] ??
        paseo['apellidoPaseador'] ??
        paseo['paseador']?['usuario']?['apellido'] ??
        paseo['Paseador']?['Usuario']?['Apellido'];

    final nombreTxt = _texto(nombre, fallback: '');
    final apellidoTxt = _texto(apellido, fallback: '');

    final completo = '$nombreTxt $apellidoTxt'.trim();

    return completo.isEmpty ? 'Paseador no asignado' : completo;
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
        paseo['FechaInicio'];

    return _fechaBonita(valor);
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
        paseo['perro']?['fotoUrl'] ??
        paseo['perro']?['FotoUrl'] ??
        paseo['Perro']?['FotoUrl'];

    final texto = valor?.toString().trim();

    if (texto == null || texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  List<Map<String, dynamic>> get _paseosFiltrados {
    final busqueda = _busquedaController.text.trim().toLowerCase();

    return _paseos.where((paseo) {
      final estado = _estado(paseo);
      final estadoNormalizado = _normalizarEstado(estado);
      final filtroNormalizado = _normalizarEstado(_filtroEstado);

      final coincideEstado = _filtroEstado == 'Todos' ||
          estadoNormalizado == filtroNormalizado;

      final textoBusqueda = [
        _nombrePerro(paseo),
        _nombrePaseador(paseo),
        estado,
        _fechaPrincipal(paseo),
        _precio(paseo),
      ].join(' ').toLowerCase();

      final coincideBusqueda =
          busqueda.isEmpty || textoBusqueda.contains(busqueda);

      return coincideEstado && coincideBusqueda;
    }).toList();
  }

  int _conteoPorEstado(String filtro) {
    if (filtro == 'Todos') return _paseos.length;

    final normalizado = _normalizarEstado(filtro);

    return _paseos.where((paseo) {
      return _normalizarEstado(_estado(paseo)) == normalizado;
    }).length;
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _ejecutarAccion({
    required Future<void> Function() accion,
    required String mensajeExito,
  }) async {
    if (_accionando) return;

    setState(() {
      _accionando = true;
    });

    try {
      await accion();

      if (!mounted) return;

      _mostrarMensaje(mensajeExito);
      await _cargarPaseos();
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
      accion: () async {
        final dynamic service = _paseosService;

        try {
          await service.aceptarPaseo(id);
          return;
        } on NoSuchMethodError catch (_) {}

        try {
          await service.aceptar(id);
          return;
        } on NoSuchMethodError catch (_) {}

        throw Exception('No encontré método para aceptar paseo.');
      },
      mensajeExito: 'Paseo aceptado correctamente.',
    );
  }

  Future<void> _rechazar(int id) async {
    await _ejecutarAccion(
      accion: () async {
        final dynamic service = _paseosService;

        try {
          await service.rechazarPaseo(id);
          return;
        } on NoSuchMethodError catch (_) {}

        try {
          await service.rechazar(id);
          return;
        } on NoSuchMethodError catch (_) {}

        throw Exception('No encontré método para rechazar paseo.');
      },
      mensajeExito: 'Paseo rechazado correctamente.',
    );
  }

  Future<void> _iniciar(int id) async {
    await _ejecutarAccion(
      accion: () async {
        final dynamic service = _paseosService;

        try {
          await service.iniciarPaseo(id);
          return;
        } on NoSuchMethodError catch (_) {}

        try {
          await service.iniciar(id);
          return;
        } on NoSuchMethodError catch (_) {}

        throw Exception('No encontré método para iniciar paseo.');
      },
      mensajeExito: 'Paseo iniciado correctamente.',
    );
  }

  Future<void> _finalizar(int id) async {
    await _ejecutarAccion(
      accion: () async {
        final dynamic service = _paseosService;

        try {
          await service.finalizarPaseo(id);
          return;
        } on NoSuchMethodError catch (_) {}

        try {
          await service.finalizar(id);
          return;
        } on NoSuchMethodError catch (_) {}

        throw Exception('No encontré método para finalizar paseo.');
      },
      mensajeExito: 'Paseo finalizado correctamente.',
    );
  }

  Future<void> _cancelar(int id) async {
    final controller = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar paseo'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo de cancelación',
              hintText: 'Ej. El dueño canceló, lluvia, cambio de horario...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancelar paseo'),
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
      accion: () async {
        final dynamic service = _paseosService;

        try {
          await service.cancelarPaseo(id, motivo);
          return;
        } on NoSuchMethodError catch (_) {}

        try {
          await service.cancelar(id, motivo);
          return;
        } on NoSuchMethodError catch (_) {}

        throw Exception('No encontré método para cancelar paseo.');
      },
      mensajeExito: 'Paseo cancelado correctamente.',
    );
  }

  void _abrirDetalle(Map<String, dynamic> paseo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePaseoScreen(
          paseo: paseo,
          onPaseoActualizado: _cargarPaseos,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final paseosFiltrados = _paseosFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Mis paseos'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarPaseos,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildResumen(),
                  const SizedBox(height: 16),
                  _buildBuscador(),
                  const SizedBox(height: 14),
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  if (_accionando) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null)
                    _buildError()
                  else if (paseosFiltrados.isEmpty)
                    _buildVacio()
                  else
                    ...paseosFiltrados.map(_buildPaseoCard),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildResumen() {
    final pendientes = _conteoPorEstado('Pendiente');
    final enCurso = _conteoPorEstado('EnCurso');
    final finalizados = _conteoPorEstado('Finalizado');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F8A70),
            Color(0xFF35A98A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seguimiento de paseos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Revisa solicitudes, tracking visual y estado de cada paseo.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ResumenItem(
                  titulo: 'Total',
                  valor: _paseos.length.toString(),
                  icono: Icons.list_alt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResumenItem(
                  titulo: 'Pendientes',
                  valor: pendientes.toString(),
                  icono: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResumenItem(
                  titulo: 'En curso',
                  valor: enCurso.toString(),
                  icono: Icons.directions_walk_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResumenItem(
                  titulo: 'Finalizados',
                  valor: finalizados.toString(),
                  icono: Icons.flag_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return TextField(
      controller: _busquedaController,
      decoration: InputDecoration(
        hintText: 'Buscar por perro, paseador o estado',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _busquedaController.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _busquedaController.clear();
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final seleccionado = filtro == _filtroEstado;
          final conteo = _conteoPorEstado(filtro);

          return ChoiceChip(
            selected: seleccionado,
            label: Text('$filtro ($conteo)'),
            onSelected: (_) {
              setState(() {
                _filtroEstado = filtro;
              });
            },
            selectedColor: const Color(0xFF1F8A70),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: seleccionado ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            side: BorderSide(
              color: seleccionado
                  ? const Color(0xFF1F8A70)
                  : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudieron cargar los paseos.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarPaseos,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F8A70),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pets_rounded,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay paseos para mostrar.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Prueba con otro filtro o actualiza la lista.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaseoCard(Map<String, dynamic> paseo) {
    final id = _idPaseo(paseo);
    final estado = _estado(paseo);
    final estadoNorm = _normalizarEstado(estado);
    final color = _colorEstado(estado);
    final foto = _fotoPerro(paseo);

    final esPendiente = estadoNorm == 'pendiente';
    final esAceptado = estadoNorm == 'aceptado';
    final esEnCurso = estadoNorm == 'encurso';
    final esFinalizado = estadoNorm == 'finalizado';
    final esCancelado = estadoNorm == 'cancelado';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFotoPerro(foto),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombrePerro(paseo),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paseador: ${_nombrePaseador(paseo)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniDato(
                          icono: Icons.calendar_month_rounded,
                          texto: _fechaPrincipal(paseo),
                        ),
                        _MiniDato(
                          icono: Icons.timer_rounded,
                          texto: _duracion(paseo),
                        ),
                        _MiniDato(
                          icono: Icons.attach_money_rounded,
                          texto: _precio(paseo),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _EstadoBadge(
                estado: estado,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTrackingPreview(
            esEnCurso: esEnCurso,
            esFinalizado: esFinalizado,
            esCancelado: esCancelado,
            color: color,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BotonSecundario(
                  texto: 'Detalle',
                  icono: Icons.visibility_rounded,
                  onPressed: () => _abrirDetalle(paseo),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BotonPrincipal(
                  texto: 'Mapa',
                  icono: Icons.map_rounded,
                  onPressed: () => _abrirMapa(paseo),
                ),
              ),
            ],
          ),
          if (id != null &&
              !esFinalizado &&
              !esCancelado &&
              (esPendiente || esAceptado || esEnCurso)) ...[
            const SizedBox(height: 10),
            _buildAccionesRapidas(
              id: id,
              esPendiente: esPendiente,
              esAceptado: esAceptado,
              esEnCurso: esEnCurso,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFotoPerro(String? foto) {
    final tieneUrlAbsoluta =
        foto != null && (foto.startsWith('http://') || foto.startsWith('https://'));

    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFF1F8A70).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: tieneUrlAbsoluta
          ? Image.network(
              foto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.pets_rounded,
                  color: Color(0xFF1F8A70),
                  size: 34,
                );
              },
            )
          : const Icon(
              Icons.pets_rounded,
              color: Color(0xFF1F8A70),
              size: 34,
            ),
    );
  }

  Widget _buildTrackingPreview({
    required bool esEnCurso,
    required bool esFinalizado,
    required bool esCancelado,
    required Color color,
  }) {
    String texto;
    IconData icono;

    if (esEnCurso) {
      texto = 'Tracking visual activo. Puedes revisar el mapa del paseo.';
      icono = Icons.my_location_rounded;
    } else if (esFinalizado) {
      texto = 'Paseo finalizado. Puedes ver la última ubicación registrada.';
      icono = Icons.flag_rounded;
    } else if (esCancelado) {
      texto = 'Este paseo fue cancelado. El tracking ya no está disponible.';
      icono = Icons.cancel_rounded;
    } else {
      texto = 'El tracking se activará cuando el paseo inicie.';
      icono = Icons.location_searching_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesRapidas({
    required int id,
    required bool esPendiente,
    required bool esAceptado,
    required bool esEnCurso,
  }) {
    final acciones = <Widget>[];

    if (esPendiente) {
      acciones.addAll([
        Expanded(
          child: _BotonAccionChico(
            texto: 'Aceptar',
            icono: Icons.check_rounded,
            color: Colors.green,
            onPressed: _accionando ? null : () => _aceptar(id),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BotonAccionChico(
            texto: 'Rechazar',
            icono: Icons.close_rounded,
            color: Colors.red,
            onPressed: _accionando ? null : () => _rechazar(id),
          ),
        ),
      ]);
    }

    if (esAceptado) {
      acciones.add(
        Expanded(
          child: _BotonAccionChico(
            texto: 'Iniciar',
            icono: Icons.play_arrow_rounded,
            color: Colors.green,
            onPressed: _accionando ? null : () => _iniciar(id),
          ),
        ),
      );
    }

    if (esEnCurso) {
      acciones.add(
        Expanded(
          child: _BotonAccionChico(
            texto: 'Finalizar',
            icono: Icons.flag_rounded,
            color: Colors.purple,
            onPressed: _accionando ? null : () => _finalizar(id),
          ),
        ),
      );
    }

    if (acciones.isNotEmpty) {
      acciones.add(const SizedBox(width: 8));
    }

    acciones.add(
      Expanded(
        child: _BotonAccionChico(
          texto: 'Cancelar',
          icono: Icons.cancel_rounded,
          color: Colors.red,
          outlined: true,
          onPressed: _accionando ? null : () => _cancelar(id),
        ),
      ),
    );

    return Row(children: acciones);
  }
}

class _ResumenItem extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _ResumenItem({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icono,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
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

  const _EstadoBadge({
    required this.estado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MiniDato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _MiniDato({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 15,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPrincipal extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onPressed;

  const _BotonPrincipal({
    required this.texto,
    required this.icono,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 19),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F8A70),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onPressed;

  const _BotonSecundario({
    required this.texto,
    required this.icono,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 19),
        label: Text(texto),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F8A70),
          side: const BorderSide(
            color: Color(0xFF1F8A70),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
    if (outlined) {
      return SizedBox(
        height: 42,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icono, size: 17),
          label: Text(
            texto,
            style: const TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(
              color: color,
              width: 1.1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 17),
        label: Text(
          texto,
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}