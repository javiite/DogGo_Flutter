import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../models/walker_availability.dart';

class WeeklyScheduleEditor extends StatelessWidget {
  final List<WalkerScheduleSlot> schedules;
  final bool enabled;
  final ValueChanged<List<WalkerScheduleSlot>> onChanged;

  const WeeklyScheduleEditor({
    super.key,
    required this.schedules,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          for (var day = 0; day < 7; day++) ...[
            _DaySection(
              key: ValueKey('availability-day-$day'),
              weekday: day,
              slots: schedules.where((item) => item.weekday == day).toList(),
              enabled: enabled,
              onToggle: (value) => _toggleDay(day, value),
              onUpdate: _updateSlot,
              onAdd: () => _addSlot(day),
              onDelete: _deleteSlot,
            ),
            if (day < 6) const Divider(height: 1, indent: 18, endIndent: 18),
          ],
        ],
      ),
    );
  }

  void _toggleDay(int day, bool active) {
    onChanged(
      schedules
          .map(
            (item) =>
                item.weekday == day ? item.copyWith(active: active) : item,
          )
          .toList(),
    );
  }

  void _updateSlot(WalkerScheduleSlot current, WalkerScheduleSlot updated) {
    final items = [...schedules];
    final index = items.indexOf(current);
    if (index >= 0) items[index] = updated;
    onChanged(items);
  }

  void _addSlot(int day) {
    final items = [...schedules];
    final matches = items.where((item) => item.weekday == day).toList();
    final last = matches.isEmpty ? null : matches.last;
    items.add(
      WalkerScheduleSlot(
        weekday: day,
        start: last?.end ?? '09:00',
        end: last == null ? '18:00' : _plusHour(last.end),
      ),
    );
    onChanged(items);
  }

  void _deleteSlot(WalkerScheduleSlot slot) {
    if (schedules.where((item) => item.weekday == slot.weekday).length <= 1) {
      _toggleDay(slot.weekday, false);
    } else {
      onChanged([...schedules]..remove(slot));
    }
  }

  static String _plusHour(String value) {
    final parts = value.split(':');
    final hour = ((int.tryParse(parts.first) ?? 17) + 1).clamp(0, 23);
    return '${hour.toString().padLeft(2, '0')}:'
        '${parts.length > 1 ? parts[1] : '00'}';
  }
}

class _DaySection extends StatelessWidget {
  final int weekday;
  final List<WalkerScheduleSlot> slots;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final void Function(WalkerScheduleSlot, WalkerScheduleSlot) onUpdate;
  final VoidCallback onAdd;
  final ValueChanged<WalkerScheduleSlot> onDelete;

  const _DaySection({
    super.key,
    required this.weekday,
    required this.slots,
    required this.enabled,
    required this.onToggle,
    required this.onUpdate,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = slots.any((item) => item.active);
    final activeSlots = slots.where((item) => item.active).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _names[weekday],
                  style: TextStyle(
                    color: active ? DogGoTheme.ink : DogGoTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (active)
                TextButton.icon(
                  onPressed: enabled && activeSlots.length < 4 ? onAdd : null,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Otro horario'),
                ),
              Switch.adaptive(
                value: active,
                onChanged: enabled ? onToggle : null,
              ),
            ],
          ),
          if (!active)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No disponible',
                style: TextStyle(color: DogGoTheme.muted, fontSize: 12),
              ),
            )
          else
            for (final slot in activeSlots)
              Padding(
                key: ObjectKey(slot),
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: DogGoTheme.teal,
                    ),
                    const SizedBox(width: 9),
                    _TimeButton(
                      value: slot.start,
                      enabled: enabled,
                      onTap: () => _pick(
                        context,
                        slot.start,
                        (value) => onUpdate(slot, slot.copyWith(start: value)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        'a',
                        style: TextStyle(color: DogGoTheme.muted),
                      ),
                    ),
                    _TimeButton(
                      value: slot.end,
                      enabled: enabled,
                      onTap: () => _pick(
                        context,
                        slot.end,
                        (value) => onUpdate(slot, slot.copyWith(end: value)),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Quitar horario',
                      onPressed: enabled ? () => onDelete(slot) : null,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    String current,
    ValueChanged<String> select,
  ) async {
    final parts = current.split(':');
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (value == null || !context.mounted) return;

    // Espera a que la ruta del selector termine de salir antes de reconstruir
    // los controles de horario que permanecen debajo de ella.
    await Future<void>.delayed(kThemeAnimationDuration);
    if (!context.mounted) return;
    select(
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}',
    );
  }

  static const _names = [
    'Domingo',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];
}

class _TimeButton extends StatelessWidget {
  final String value;
  final bool enabled;
  final VoidCallback onTap;
  const _TimeButton({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: DogGoTheme.tealLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: DogGoTheme.tealDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
