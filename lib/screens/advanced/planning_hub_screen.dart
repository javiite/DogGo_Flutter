import 'package:flutter/material.dart';

import '../../services/paseos_service.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../theme/doggo_theme.dart';
import '../calendario_paseos_screen.dart';
import '../detalle_paseo_screen.dart';
import '../mis_paseos_screen.dart';
import '../paseadores_screen.dart';
import 'walk_planning_screen.dart';

class PlanningHubScreen extends StatefulWidget {
  final String role;

  const PlanningHubScreen({super.key, required this.role});

  @override
  State<PlanningHubScreen> createState() => _PlanningHubScreenState();
}

class _PlanningHubScreenState extends State<PlanningHubScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _walks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await PaseosService.obtenerMisPaseos();
      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'No se pudieron cargar los paseos.',
        );
      }
      final raw = response['data'];
      final walks = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _walks = walks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    await _load();
  }

  int? _id(Map<String, dynamic> value) =>
      int.tryParse('${value['id'] ?? value['paseoId'] ?? ''}');

  bool _active(Map<String, dynamic> walk) {
    final state = '${walk['estado'] ?? ''}'.toLowerCase();
    return state != 'finalizado' && state != 'cancelado';
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Planificación avanzada',
      body: _loading
          ? const DogGoLoadingView(message: 'Cargando agenda...')
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: DogGoErrorView(message: _error!, onRetry: _load),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  _PlanningHero(upcoming: _walks.where(_active).length),
                  const SizedBox(height: 18),
                  _ActionCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Calendario visual',
                    subtitle:
                        'Mes, día, filtros, recordatorios y programaciones.',
                    onTap: () => _push(
                      CalendarioPaseosScreen(paseos: _walks, rol: widget.role),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.event_repeat_rounded,
                    title: 'Crear paseos semanales',
                    subtitle:
                        'Elige paseador y mascotas; agrega 4 u 8 semanas con un toque.',
                    onTap: () => _push(const PaseadoresScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.history_rounded,
                    title: 'Repetir un paseo',
                    subtitle:
                        'Abre un paseo finalizado y usa “Repetir paseo” para recuperar sus datos.',
                    onTap: () => _push(const MisPaseosScreen()),
                  ),
                  const SizedBox(height: 24),
                  Text('Próximos paseos', style: DogGoTheme.title(size: 20)),
                  const SizedBox(height: 10),
                  ..._walks.where(_active).take(8).map((walk) {
                    final id = _id(walk);
                    final pet =
                        '${walk['nombrePerro'] ?? walk['mascotaNombre'] ?? 'Paseo DogGo'}';
                    final date = DateTime.tryParse(
                      '${walk['fechaProgramada'] ?? ''}',
                    )?.toLocal();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WalkCard(
                        pet: pet,
                        state: '${walk['estado'] ?? 'Pendiente'}',
                        date: date,
                        onOpen: id == null
                            ? null
                            : () => _push(
                                DetallePaseoScreen(
                                  paseoId: id,
                                  paseo: walk,
                                  rol: widget.role,
                                ),
                              ),
                        onPlan: id == null
                            ? null
                            : () => _push(
                                WalkPlanningScreen(
                                  walkId: id,
                                  role: widget.role,
                                ),
                              ),
                      ),
                    );
                  }),
                  if (_walks.where(_active).isEmpty) const _EmptyAgenda(),
                ],
              ),
            ),
    );
  }
}

class _PlanningHero extends StatelessWidget {
  final int upcoming;
  const _PlanningHero({required this.upcoming});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DogGoTheme.teal,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const Icon(Icons.route_rounded, size: 44, color: Colors.white),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$upcoming próximos',
                style: DogGoTheme.title(size: 22, color: Colors.white),
              ),
              Text(
                'Todo listo antes de salir.',
                style: DogGoTheme.body(
                  color: Colors.white.withValues(alpha: .78),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: DogGoTheme.tealLight,
        child: Icon(icon, color: DogGoTheme.teal),
      ),
      title: Text(title, style: DogGoTheme.body(weight: FontWeight.w800)),
      subtitle: Text(subtitle, style: DogGoTheme.subtitle(size: 12.5)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _WalkCard extends StatelessWidget {
  final String pet;
  final String state;
  final DateTime? date;
  final VoidCallback? onOpen;
  final VoidCallback? onPlan;
  const _WalkCard({
    required this.pet,
    required this.state,
    required this.date,
    this.onOpen,
    this.onPlan,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: DogGoTheme.orangeLight,
                child: Icon(Icons.pets_rounded, color: DogGoTheme.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet, style: DogGoTheme.body(weight: FontWeight.w800)),
                    Text(
                      date == null
                          ? state
                          : '${_two(date!.day)}/${_two(date!.month)} · ${_two(date!.hour)}:${_two(date!.minute)} · $state',
                      style: DogGoTheme.subtitle(size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpen,
                  child: const Text('Ver paseo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlan,
                  icon: const Icon(Icons.checklist_rounded, size: 18),
                  label: const Text('Preparar'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: DogGoTheme.tealLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      children: [
        Icon(Icons.event_available_rounded, color: DogGoTheme.teal, size: 38),
        SizedBox(height: 10),
        Text('Tu agenda está libre por ahora.'),
      ],
    ),
  );
}
