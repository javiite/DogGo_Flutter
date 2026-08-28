import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../services/app_preferences_service.dart';
import '../services/walk_reminder_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'detalle_paseo_screen.dart';
import 'programacion_paseos_screen.dart';

class CalendarioPaseosScreen extends StatefulWidget {
  final List<Map<String, dynamic>> paseos;
  final String rol;

  const CalendarioPaseosScreen({
    super.key,
    required this.paseos,
    required this.rol,
  });

  @override
  State<CalendarioPaseosScreen> createState() => _CalendarioPaseosScreenState();
}

class _CalendarioPaseosScreenState extends State<CalendarioPaseosScreen> {
  late DateTime _mesVisible;
  late DateTime _diaSeleccionado;

  String _filtro = 'Todos';
  String _petFilter = 'Todas';
  bool _listMode = false;
  DogGoPreferences _preferences = const DogGoPreferences();

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

    final ahora = DateTime.now();
    _mesVisible = DateTime(ahora.year, ahora.month, 1);
    _diaSeleccionado = DateTime(ahora.year, ahora.month, ahora.day);
    AppPreferencesService.load().then((value) {
      if (mounted) setState(() => _preferences = value);
    });
    WalkReminderService.sync(widget.paseos);
  }

  bool get _esPaseador {
    return SessionService.esPaseadorRol(widget.rol);
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  int? _programacionId(Map<String, dynamic> paseo) {
    final value = paseo['programacionId'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _estado(Map<String, dynamic> paseo) {
    return _texto(paseo['estado'], fallback: 'Pendiente');
  }

  String _normalizarEstado(String estado) {
    return estado.replaceAll(' ', '').toLowerCase();
  }

  DateTime? _fechaPaseo(Map<String, dynamic> paseo) {
    final valor =
        paseo['fechaProgramada'] ?? paseo['fechaInicio'] ?? paseo['fechaFin'];

    if (valor == null) return null;

    final fecha = DateTime.tryParse(valor.toString());

    return fecha?.toLocal();
  }

  String _nombrePerro(Map<String, dynamic> paseo) {
    final perros = paseo['perros'];
    if (perros is! List) return 'Mascota';
    final nombres = perros
        .whereType<Map>()
        .map((perro) => _texto(perro['nombre'], fallback: ''))
        .where((nombre) => nombre.isNotEmpty)
        .toList(growable: false);
    return nombres.isEmpty ? 'Mascota' : nombres.join(', ');
  }

  String _nombrePaseador(Map<String, dynamic> paseo) {
    final completo = _texto(paseo['paseadorNombreCompleto'], fallback: '');
    if (completo.isNotEmpty) return completo;
    final nombre = paseo['paseadorNombre'];
    final apellido = paseo['paseadorApellido'];

    final nombreTxt = _texto(nombre, fallback: '');
    final apellidoTxt = _texto(apellido, fallback: '');

    final nombreCompleto = '$nombreTxt $apellidoTxt'.trim();
    return nombreCompleto.isEmpty ? 'Paseador no asignado' : nombreCompleto;
  }

  String _nombreDuenio(Map<String, dynamic> paseo) {
    final completo = _texto(paseo['duenioNombreCompleto'], fallback: '');
    if (completo.isNotEmpty) return completo;
    final nombre = paseo['duenioNombre'];
    final apellido = paseo['duenioApellido'];

    final nombreTxt = _texto(nombre, fallback: '');
    final apellidoTxt = _texto(apellido, fallback: '');

    final nombreCompleto = '$nombreTxt $apellidoTxt'.trim();
    return nombreCompleto.isEmpty ? 'Dueño' : nombreCompleto;
  }

  String _hora(DateTime? fecha) {
    if (fecha == null) return 'Sin hora';

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  String _nombreMes(DateTime fecha) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  bool _mismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _mismoMes(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
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

  List<Map<String, dynamic>> get _paseosFiltrados {
    return widget.paseos.where((paseo) {
      final stateMatches =
          _filtro == 'Todos' ||
          _normalizarEstado(_estado(paseo)) == _normalizarEstado(_filtro);
      final petMatches =
          _petFilter == 'Todas' ||
          _nombrePerro(
            paseo,
          ).split(',').map((name) => name.trim()).contains(_petFilter);
      return stateMatches && petMatches;
    }).toList();
  }

  List<String> get _petNames {
    final names =
        widget.paseos
            .expand((paseo) => _nombrePerro(paseo).split(','))
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty && name != 'Mascota')
            .toSet()
            .toList()
          ..sort();
    return ['Todas', ...names];
  }

  List<Map<String, dynamic>> _paseosDelDia(DateTime dia) {
    final walks =
        _paseosFiltrados.where((paseo) {
          final fecha = _fechaPaseo(paseo);

          if (fecha == null) return false;

          return _mismoDia(fecha, dia);
        }).toList()..sort((a, b) {
          final fa = _fechaPaseo(a);
          final fb = _fechaPaseo(b);

          if (fa == null && fb == null) return 0;
          if (fa == null) return 1;
          if (fb == null) return -1;

          return fa.compareTo(fb);
        });

    final visible = <Map<String, dynamic>>[];
    final programs = <int>{};
    for (final walk in walks) {
      final programId = _programacionId(walk);
      if (programId != null && programId > 0 && !programs.add(programId)) {
        continue;
      }
      visible.add(walk);
    }
    return visible;
  }

  bool _diaTienePaseos(DateTime dia) {
    return _paseosFiltrados.any((paseo) {
      final fecha = _fechaPaseo(paseo);

      if (fecha == null) return false;

      return _mismoDia(fecha, dia);
    });
  }

  int _conteoDelDia(DateTime dia) {
    return _paseosFiltrados.where((paseo) {
      final fecha = _fechaPaseo(paseo);

      if (fecha == null) return false;

      return _mismoDia(fecha, dia);
    }).length;
  }

  List<DateTime?> _diasCalendario() {
    final primerDia = DateTime(_mesVisible.year, _mesVisible.month, 1);
    final ultimoDia = DateTime(_mesVisible.year, _mesVisible.month + 1, 0);

    final offsetInicio = primerDia.weekday - 1;
    final totalDias = offsetInicio + ultimoDia.day;
    final filas = (totalDias / 7).ceil();
    final totalCeldas = filas * 7;

    final dias = <DateTime?>[];

    for (var i = 0; i < totalCeldas; i++) {
      final numeroDia = i - offsetInicio + 1;

      if (numeroDia < 1 || numeroDia > ultimoDia.day) {
        dias.add(null);
      } else {
        dias.add(DateTime(_mesVisible.year, _mesVisible.month, numeroDia));
      }
    }

    return dias;
  }

  void _mesAnterior() {
    setState(() {
      _mesVisible = DateTime(_mesVisible.year, _mesVisible.month - 1, 1);
    });
  }

  void _mesSiguiente() {
    setState(() {
      _mesVisible = DateTime(_mesVisible.year, _mesVisible.month + 1, 1);
    });
  }

  Future<void> _abrirDetalle(Map<String, dynamic> paseo) async {
    final programId = _programacionId(paseo);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => programId != null && programId > 0
            ? ProgramacionPaseosScreen(
                programacionId: programId,
                rol: widget.rol,
              )
            : DetallePaseoScreen(paseo: paseo, rol: widget.rol),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paseosSeleccionados = _paseosDelDia(_diaSeleccionado);

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildFiltros()),
            SliverToBoxAdapter(child: _buildAgendaTools()),
            if (!_listMode) SliverToBoxAdapter(child: _buildCalendario()),
            SliverToBoxAdapter(
              child: _listMode
                  ? _buildAgendaList()
                  : _buildListaDia(paseosSeleccionados),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 34)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        border: Border(
          bottom: BorderSide(color: DogGoTheme.border.withValues(alpha: .8)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: DogGoTheme.ink),
          ),
          const SizedBox(width: 4),
          const DogGoLogo(size: 38),
          const Spacer(),
          IconButton(
            tooltip: _listMode ? 'Vista calendario' : 'Vista lista',
            onPressed: () => setState(() => _listMode = !_listMode),
            icon: Icon(
              _listMode
                  ? Icons.calendar_month_rounded
                  : Icons.view_agenda_rounded,
              color: DogGoTheme.ink,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                final ahora = DateTime.now();
                _mesVisible = DateTime(ahora.year, ahora.month, 1);
                _diaSeleccionado = DateTime(ahora.year, ahora.month, ahora.day);
              });
            },
            icon: const Icon(Icons.today_rounded, color: DogGoTheme.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalMes = _paseosFiltrados.where((paseo) {
      final fecha = _fechaPaseo(paseo);

      if (fecha == null) return false;

      return _mismoMes(fecha, _mesVisible);
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📅 AGENDA DOGGO', style: DogGoTheme.label(size: 11)),
          const SizedBox(height: 10),
          Text('Calendario de paseos', style: DogGoTheme.title(size: 32)),
          const SizedBox(height: 10),
          Text(
            _esPaseador
                ? 'Aquí ves tus paseos asignados, activos y terminados.'
                : 'Aquí ves los paseos programados para tus perros y tu historial.',
            style: DogGoTheme.subtitle(size: 15),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DogGoTheme.teal,
              borderRadius: BorderRadius.circular(24),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ResumenCalendario(
                    label: 'Mes',
                    value: totalMes.toString(),
                  ),
                ),
                Expanded(
                  child: _ResumenCalendario(
                    label: 'Día',
                    value: _conteoDelDia(_diaSeleccionado).toString(),
                  ),
                ),
                Expanded(
                  child: _ResumenCalendario(label: 'Vista', value: _filtro),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final selected = filtro == _filtro;

          return ChoiceChip(
            selected: selected,
            label: Text(filtro),
            onSelected: (_) {
              setState(() {
                _filtro = filtro;
              });
            },
            selectedColor: DogGoTheme.teal,
            backgroundColor: DogGoTheme.card,
            labelStyle: TextStyle(
              color: selected ? Colors.white : DogGoTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
            side: BorderSide(
              color: selected ? DogGoTheme.teal : DogGoTheme.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgendaTools() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 2),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _petNames.contains(_petFilter) ? _petFilter : 'Todas',
            decoration: const InputDecoration(
              labelText: 'Mascota',
              prefixIcon: Icon(Icons.pets_rounded),
            ),
            items: _petNames
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (value) => setState(() => _petFilter = value ?? 'Todas'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _preferences.walkRemindersEnabled
                  ? DogGoTheme.tealLight
                  : DogGoTheme.cream2,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Row(
              children: [
                Icon(
                  _preferences.walkRemindersEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: DogGoTheme.teal,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _preferences.walkRemindersEnabled
                        ? 'Recordatorios activados ${_preferences.reminderMinutes} min antes.'
                        : 'Los recordatorios de paseo están desactivados.',
                    style: DogGoTheme.body(size: 11.5, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaList() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));
    final future = _paseosFiltrados.where((walk) {
      final date = _fechaPaseo(walk);
      return date != null && !date.isBefore(today);
    }).toList()..sort((a, b) => _fechaPaseo(a)!.compareTo(_fechaPaseo(b)!));

    List<Map<String, dynamic>> group(DateTime start, DateTime end) =>
        future.where((walk) {
          final date = _fechaPaseo(walk)!;
          return !date.isBefore(start) && date.isBefore(end);
        }).toList();

    final todayWalks = group(today, tomorrow);
    final tomorrowWalks = group(
      tomorrow,
      tomorrow.add(const Duration(days: 1)),
    );
    final weekWalks = group(tomorrow.add(const Duration(days: 1)), weekEnd);
    final later = future
        .where((walk) => !_fechaPaseo(walk)!.isBefore(weekEnd))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AgendaGroup(
            title: 'Hoy',
            walks: todayWalks,
            builder: _buildPaseoDiaCard,
          ),
          _AgendaGroup(
            title: 'Mañana',
            walks: tomorrowWalks,
            builder: _buildPaseoDiaCard,
          ),
          _AgendaGroup(
            title: 'Esta semana',
            walks: weekWalks,
            builder: _buildPaseoDiaCard,
          ),
          _AgendaGroup(
            title: 'Más adelante',
            walks: later,
            builder: _buildPaseoDiaCard,
          ),
          if (future.isEmpty)
            Text(
              'No hay paseos próximos con estos filtros.',
              style: DogGoTheme.subtitle(size: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendario() {
    final dias = _diasCalendario();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _mesAnterior,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _nombreMes(_mesVisible),
                  textAlign: TextAlign.center,
                  style: DogGoTheme.title(size: 21),
                ),
              ),
              IconButton(
                onPressed: _mesSiguiente,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _DiaSemana('L'),
              _DiaSemana('M'),
              _DiaSemana('M'),
              _DiaSemana('J'),
              _DiaSemana('V'),
              _DiaSemana('S'),
              _DiaSemana('D'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dias.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final dia = dias[index];

              if (dia == null) {
                return const SizedBox.shrink();
              }

              final seleccionado = _mismoDia(dia, _diaSeleccionado);
              final hoy = _mismoDia(dia, DateTime.now());
              final tienePaseos = _diaTienePaseos(dia);
              final conteo = _conteoDelDia(dia);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _diaSeleccionado = dia;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? DogGoTheme.teal
                        : tienePaseos
                        ? DogGoTheme.tealLight
                        : DogGoTheme.cream,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: hoy
                          ? DogGoTheme.orange
                          : seleccionado
                          ? DogGoTheme.teal
                          : DogGoTheme.border,
                      width: hoy ? 1.8 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          dia.day.toString(),
                          style: DogGoTheme.body(
                            size: 13,
                            color: seleccionado ? Colors.white : DogGoTheme.ink,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (conteo > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 17,
                            height: 17,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? Colors.white
                                  : DogGoTheme.teal,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conteo.toString(),
                              style: TextStyle(
                                color: seleccionado
                                    ? DogGoTheme.teal
                                    : Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListaDia(List<Map<String, dynamic>> paseos) {
    final fechaTexto =
        '${_diaSeleccionado.day.toString().padLeft(2, '0')}/${_diaSeleccionado.month.toString().padLeft(2, '0')}/${_diaSeleccionado.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paseos del día', style: DogGoTheme.title(size: 24)),
          const SizedBox(height: 4),
          Text(fechaTexto, style: DogGoTheme.subtitle(size: 14)),
          const SizedBox(height: 16),
          if (paseos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: DogGoTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DogGoTheme.border),
                boxShadow: DogGoTheme.softShadow(),
              ),
              child: Column(
                children: [
                  const Text('🐾', style: TextStyle(fontSize: 42)),
                  const SizedBox(height: 10),
                  Text(
                    'No hay paseos este día',
                    style: DogGoTheme.title(size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selecciona otro día o cambia el filtro.',
                    textAlign: TextAlign.center,
                    style: DogGoTheme.subtitle(size: 13),
                  ),
                ],
              ),
            )
          else
            ...paseos.map(_buildPaseoDiaCard),
        ],
      ),
    );
  }

  Widget _buildPaseoDiaCard(Map<String, dynamic> paseo) {
    final estado = _estado(paseo);
    final color = _colorEstado(estado);
    final surface = _surfaceEstado(estado);
    final fecha = _fechaPaseo(paseo);
    final programId = _programacionId(paseo);
    final programCount = programId == null
        ? 0
        : widget.paseos
              .where((item) => _programacionId(item) == programId)
              .length;
    final isProgram = programCount > 1;

    return GestureDetector(
      onTap: () => _abrirDetalle(paseo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DogGoTheme.border),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_iconoEstado(estado), color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProgram
                        ? 'Programación · $programCount paseos'
                        : _nombrePerro(paseo),
                    style: DogGoTheme.title(size: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isProgram
                        ? 'Próximo: ${_nombrePerro(paseo)} · ${_hora(fecha)}'
                        : _esPaseador
                        ? 'Dueño: ${_nombreDuenio(paseo)}'
                        : 'Paseador: ${_nombrePaseador(paseo)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.subtitle(size: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: DogGoTheme.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hora(fecha),
                        style: DogGoTheme.body(
                          size: 12,
                          color: DogGoTheme.muted,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                estado,
                style: DogGoTheme.body(
                  size: 10.5,
                  color: color,
                  weight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaGroup extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> walks;
  final Widget Function(Map<String, dynamic>) builder;
  const _AgendaGroup({
    required this.title,
    required this.walks,
    required this.builder,
  });
  @override
  Widget build(BuildContext context) {
    if (walks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DogGoTheme.title(size: 20)),
          const SizedBox(height: 10),
          ...walks.map(builder),
        ],
      ),
    );
  }
}

class _ResumenCalendario extends StatelessWidget {
  final String label;
  final String value;

  const _ResumenCalendario({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.title(size: 21, color: Colors.white),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: DogGoTheme.subtitle(
            size: 11,
            color: Colors.white.withValues(alpha: .86),
          ),
        ),
      ],
    );
  }
}

class _DiaSemana extends StatelessWidget {
  final String texto;

  const _DiaSemana(this.texto);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: DogGoTheme.body(
          size: 11,
          color: DogGoTheme.muted,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}
