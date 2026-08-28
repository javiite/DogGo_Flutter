import 'package:flutter/material.dart';

import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../shared/widgets/doggo_sticky_action_bar.dart';
import '../../theme/doggo_theme.dart';
import 'availability_controller.dart';
import 'widgets/availability_blocks_section.dart';
import 'widgets/weekly_schedule_editor.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late final AvailabilityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AvailabilityController();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return DogGoScreenScaffold(
          title: 'Mi disponibilidad',
          actions: [
            IconButton(
              tooltip: 'Actualizar disponibilidad',
              onPressed: state.loading
                  ? null
                  : () => _controller.load(silent: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _controller.load(silent: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RepaintBoundary(
                          child: _AvailabilityHero(
                            available: state.available,
                            saving: state.saving,
                            onChanged: _controller.setAvailable,
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorCard(
                            message: state.error!,
                            onRetry: () => _controller.load(silent: true),
                          ),
                        ],
                        const SizedBox(height: 27),
                        const Text(
                          'Tu semana habitual',
                          style: TextStyle(
                            color: DogGoTheme.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Elige los días y las horas en que puedes recibir solicitudes.',
                          style: TextStyle(
                            color: DogGoTheme.muted,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        RepaintBoundary(
                          child: WeeklyScheduleEditor(
                            schedules: state.schedules,
                            enabled: !state.saving,
                            onChanged: _controller.setSchedules,
                          ),
                        ),
                        const SizedBox(height: 28),
                        RepaintBoundary(
                          child: AvailabilityBlocksSection(
                            blocks: state.blocks,
                            occupations: state.occupations,
                            busy: state.saving,
                            onAdd: _showBlockEditor,
                            onDelete: _confirmDelete,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: state.loading
              ? null
              : DogGoStickyActionBar(
                  primaryLabel: state.saving
                      ? 'Guardando...'
                      : 'Guardar cambios',
                  primaryIcon: Icons.check_rounded,
                  onPrimary: state.saving ? null : _save,
                ),
        );
      },
    );
  }

  Future<void> _save() async {
    final message = await _controller.save();
    if (!mounted || message == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _showMessage(message);
  }

  Future<void> _confirmDelete(int id) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bloqueo'),
        content: const Text(
          'Volverás a aparecer disponible durante ese periodo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (remove == true) {
      final message = await _controller.deleteBlock(id);
      if (mounted && message != null) _showMessage(message);
    }
  }

  Future<void> _showBlockEditor() async {
    final result = await showModalBottomSheet<_BlockDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BlockEditorSheet(),
    );
    if (result == null) return;
    final message = await _controller.createBlock(
      start: result.start,
      end: result.end,
      reason: result.reason,
    );
    if (mounted && message != null) _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AvailabilityHero extends StatelessWidget {
  final bool available;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const _AvailabilityHero({
    required this.available,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006C5B), Color(0xFF07947C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              available
                  ? Icons.event_available_rounded
                  : Icons.pause_circle_outline_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available
                      ? 'Recibiendo solicitudes'
                      : 'Disponibilidad pausada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  available
                      ? 'DogGo respetará tus horarios y bloqueos.'
                      : 'No recibirás nuevas solicitudes por ahora.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: available,
            onChanged: saving ? null : onChanged,
            activeTrackColor: Colors.white,
            activeThumbColor: DogGoTheme.teal,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: DogGoTheme.redLight,
      leading: const Icon(Icons.error_outline_rounded, color: DogGoTheme.red),
      title: Text(message, style: const TextStyle(fontSize: 12.5)),
      trailing: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    );
  }
}

class _BlockDraft {
  final DateTime start;
  final DateTime end;
  final String? reason;
  const _BlockDraft(this.start, this.end, this.reason);
}

class _BlockEditorSheet extends StatefulWidget {
  const _BlockEditorSheet();
  @override
  State<_BlockEditorSheet> createState() => _BlockEditorSheetState();
}

class _BlockEditorSheetState extends State<_BlockEditorSheet> {
  late DateTime _start;
  late DateTime _end;
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day + 1, 9);
    _end = _start.add(const Duration(hours: 8));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: DogGoTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Bloquear un periodo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Durante este tiempo no podrás recibir solicitudes.',
            style: TextStyle(color: DogGoTheme.muted),
          ),
          const SizedBox(height: 20),
          _DateTimeTile(
            label: 'Desde',
            value: _start,
            onTap: () => _selectDateTime(true),
          ),
          const SizedBox(height: 10),
          _DateTimeTile(
            label: 'Hasta',
            value: _end,
            onTap: () => _selectDateTime(false),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              hintText: 'Vacaciones, cita, descanso...',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _end.isAfter(_start)
                  ? () => Navigator.pop(
                      context,
                      _BlockDraft(_start, _end, _reason.text),
                    )
                  : null,
              child: const Text('Agregar a mi agenda'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(bool start) async {
    final current = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = value;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = value;
      }
    });
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String two(int number) => number.toString().padLeft(2, '0');
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DogGoTheme.border),
      ),
      leading: const Icon(Icons.calendar_month_rounded, color: DogGoTheme.teal),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: DogGoTheme.muted),
      ),
      subtitle: Text(
        '${two(value.day)}/${two(value.month)}/${value.year} · ${two(value.hour)}:${two(value.minute)}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: const Icon(Icons.edit_calendar_outlined),
    );
  }
}
