import 'package:flutter/material.dart';

import '../../services/advanced_experience_service.dart';
import '../../services/session_service.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../shared/widgets/doggo_section_card.dart';
import '../../theme/doggo_theme.dart';

class WalkPlanningScreen extends StatefulWidget {
  final int walkId;
  final String role;

  const WalkPlanningScreen({
    super.key,
    required this.walkId,
    required this.role,
  });

  @override
  State<WalkPlanningScreen> createState() => _WalkPlanningScreenState();
}

class _WalkPlanningScreenState extends State<WalkPlanningScreen> {
  final _instructions = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _plan = const {};
  int? _userId;
  DateTime? _meeting;
  String _meetingState = 'SinProgramar';
  final Map<String, bool> _checklist = {
    'correaLista': false,
    'identificacionLista': false,
    'aguaLista': false,
    'bolsasListas': false,
    'indicacionesRevisadas': false,
  };

  bool get _isWalker => SessionService.esPaseadorRol(widget.role);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<dynamic>([
        AdvancedExperienceService.walkPlan(widget.walkId),
        SessionService.obtenerUsuarioId(),
      ]);
      final data = Map<String, dynamic>.from(values[0] as Map);
      if (!mounted) return;
      setState(() {
        _plan = data;
        _userId = values[1] as int?;
        for (final key in _checklist.keys) {
          _checklist[key] = data[key] == true;
        }
        _instructions.text = data['instruccionesEspeciales']?.toString() ?? '';
        _meeting = DateTime.tryParse(
          '${data['encuentroPrevioUtc'] ?? ''}',
        )?.toLocal();
        _meetingState =
            data['estadoEncuentroPrevio']?.toString() ?? 'SinProgramar';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _clean(error);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AdvancedExperienceService.saveWalkPlan(widget.walkId, {
        ..._checklist,
        'instruccionesEspeciales': _instructions.text.trim(),
        'encuentroPrevioUtc': _meeting?.toUtc().toIso8601String(),
        'estadoEncuentroPrevio': _meetingState,
      });
      if (mounted) _message('Preparación actualizada.', success: true);
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickMeeting() async {
    final value = await _pickDateTime(
      _meeting ?? DateTime.now().add(const Duration(days: 1)),
    );
    if (value == null) return;
    setState(() {
      _meeting = value;
      _meetingState = 'Propuesto';
    });
  }

  Future<void> _requestReschedule() async {
    final date = await _pickDateTime(
      DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final reason = await _askText(
      title: 'Proponer nueva fecha',
      hint: 'Motivo de la reprogramación',
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await AdvancedExperienceService.requestReschedule(
        widget.walkId,
        proposedDate: date,
        reason: reason,
      );
      if (mounted) {
        _message('Propuesta enviada a la otra parte.', success: true);
      }
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _answer(bool accept) async {
    setState(() => _saving = true);
    try {
      await AdvancedExperienceService.answerReschedule(
        widget.walkId,
        accept: accept,
      );
      if (mounted) {
        _message(
          accept ? 'Nueva fecha aceptada.' : 'Propuesta rechazada.',
          success: accept,
        );
      }
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _arrival(String state, [int? eta]) async {
    setState(() => _saving = true);
    try {
      await AdvancedExperienceService.updateArrival(
        widget.walkId,
        state: state,
        etaMinutes: eta,
      );
      if (mounted) _message('Aviso enviado al dueño.', success: true);
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<String?> _askText({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Preparar paseo',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _loading
          ? const DogGoLoadingView(message: 'Cargando preparación...')
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: DogGoErrorView(message: _error!, onRetry: _load),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: [
                _ProgressHeader(
                  percent:
                      int.tryParse('${_plan['preparacionPorcentaje'] ?? 0}') ??
                      0,
                  arrival: '${_plan['estadoLlegada'] ?? 'Pendiente'}',
                  eta: int.tryParse('${_plan['etaMinutos'] ?? ''}'),
                ),
                const SizedBox(height: 16),
                DogGoSectionCard(
                  title: 'Checklist por mascota',
                  subtitle: 'Cinco puntos esenciales antes de la recogida.',
                  icon: Icons.checklist_rounded,
                  child: Column(
                    children: [
                      _check(
                        'correaLista',
                        'Correa o arnés listo',
                        Icons.pets_rounded,
                      ),
                      _check(
                        'identificacionLista',
                        'Identificación visible',
                        Icons.badge_outlined,
                      ),
                      _check(
                        'aguaLista',
                        'Agua preparada',
                        Icons.water_drop_outlined,
                      ),
                      _check(
                        'bolsasListas',
                        'Bolsas disponibles',
                        Icons.shopping_bag_outlined,
                      ),
                      _check(
                        'indicacionesRevisadas',
                        'Indicaciones revisadas',
                        Icons.fact_check_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                DogGoSectionCard(
                  title: 'Instrucciones específicas',
                  subtitle:
                      'Correa, alimento, medicina, conducta o contactos importantes.',
                  icon: Icons.notes_rounded,
                  child: TextField(
                    controller: _instructions,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText:
                          'Ej. usar arnés verde; evitar perros grandes; medicina a las 18:00…',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DogGoSectionCard(
                  title: 'Encuentro previo',
                  subtitle:
                      'Agenda una presentación dueño–paseador antes del servicio.',
                  icon: Icons.handshake_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _meeting == null
                            ? 'Sin fecha propuesta'
                            : _format(_meeting!),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pickMeeting,
                        icon: const Icon(Icons.event_rounded),
                        label: const Text('Elegir encuentro'),
                      ),
                      if (_meeting != null) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _meetingState,
                          decoration: const InputDecoration(
                            labelText: 'Estado del encuentro',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'SinProgramar',
                              child: Text('Sin programar'),
                            ),
                            DropdownMenuItem(
                              value: 'Propuesto',
                              child: Text('Propuesto'),
                            ),
                            DropdownMenuItem(
                              value: 'Confirmado',
                              child: Text('Confirmado'),
                            ),
                            DropdownMenuItem(
                              value: 'Realizado',
                              child: Text('Realizado'),
                            ),
                            DropdownMenuItem(
                              value: 'Cancelado',
                              child: Text('Cancelado'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _meetingState = value);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _RescheduleCard(
                  plan: _plan,
                  canRespond:
                      int.tryParse(
                        '${_plan['reprogramacionSolicitadaPorUsuarioId'] ?? ''}',
                      ) !=
                      _userId,
                  disabled: _saving,
                  onRequest: _requestReschedule,
                  onAccept: () => _answer(true),
                  onReject: () => _answer(false),
                ),
                if (_isWalker) ...[
                  const SizedBox(height: 14),
                  DogGoSectionCard(
                    title: 'Avisar llegada',
                    subtitle: 'El dueño recibe el estado y el tiempo estimado.',
                    icon: Icons.directions_walk_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(
                            Icons.navigation_rounded,
                            size: 17,
                          ),
                          label: const Text('Voy en camino · 20 min'),
                          onPressed: _saving
                              ? null
                              : () => _arrival('EnCamino', 20),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.timer_outlined, size: 17),
                          label: const Text('Llego en 10 min'),
                          onPressed: _saving
                              ? null
                              : () => _arrival('LlegoEn10', 10),
                        ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.location_on_rounded,
                            size: 17,
                          ),
                          label: const Text('Ya llegué'),
                          onPressed: _saving
                              ? null
                              : () => _arrival('YaLlegue', 0),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Guardar preparación'),
                ),
              ],
            ),
    );
  }

  Widget _check(String key, String label, IconData icon) => CheckboxListTile(
    value: _checklist[key],
    onChanged: _saving
        ? null
        : (value) => setState(() => _checklist[key] = value ?? false),
    title: Text(label, style: DogGoTheme.body(weight: FontWeight.w700)),
    secondary: Icon(icon, color: DogGoTheme.teal),
    controlAffinity: ListTileControlAffinity.trailing,
    contentPadding: EdgeInsets.zero,
  );

  void _message(String text, {bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  static String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
  static String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _ProgressHeader extends StatelessWidget {
  final int percent;
  final String arrival;
  final int? eta;
  const _ProgressHeader({
    required this.percent,
    required this.arrival,
    this.eta,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DogGoTheme.teal,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Preparación $percent%',
                style: DogGoTheme.title(size: 21, color: Colors.white),
              ),
            ),
            Text(
              eta == null ? arrival : '$arrival · $eta min',
              style: DogGoTheme.caption(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: percent.clamp(0, 100) / 100,
          backgroundColor: Colors.white.withValues(alpha: .18),
          color: DogGoTheme.orange,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    ),
  );
}

class _RescheduleCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool disabled;
  final bool canRespond;
  final VoidCallback onRequest;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _RescheduleCard({
    required this.plan,
    required this.disabled,
    required this.canRespond,
    required this.onRequest,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${plan['estadoReprogramacion'] ?? 'SinPropuesta'}';
    final date = DateTime.tryParse(
      '${plan['reprogramacionFechaPropuestaUtc'] ?? ''}',
    )?.toLocal();
    return DogGoSectionCard(
      title: 'Reprogramación acordada',
      subtitle:
          'La fecha sólo cambia después de la aceptación de la otra parte.',
      icon: Icons.update_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status != 'SinPropuesta') ...[
            Text(
              'Estado: $status',
              style: DogGoTheme.body(weight: FontWeight.w800),
            ),
            if (date != null)
              Text('Propuesta: ${_WalkPlanningScreenState._format(date)}'),
            if ('${plan['motivoReprogramacion'] ?? ''}'.isNotEmpty)
              Text('Motivo: ${plan['motivoReprogramacion']}'),
            const SizedBox(height: 10),
          ],
          if (status == 'Pendiente' && canRespond)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: disabled ? null : onReject,
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: disabled ? null : onAccept,
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            )
          else if (status == 'Pendiente')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DogGoTheme.orangeLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Esperando la respuesta de la otra parte.',
                textAlign: TextAlign.center,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: disabled ? null : onRequest,
              icon: const Icon(Icons.edit_calendar_rounded),
              label: const Text('Proponer nueva fecha'),
            ),
        ],
      ),
    );
  }
}
