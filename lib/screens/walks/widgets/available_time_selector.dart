import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../models/walk_request_availability.dart';

class AvailableTimeSelector extends StatelessWidget {
  final List<WalkTimeSlotOption> times;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  const AvailableTimeSelector({
    super.key,
    required this.times,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (times.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'El paseador no trabaja este día o ya terminó su jornada.',
          style: TextStyle(color: DogGoTheme.muted),
        ),
      );
    }
    final selectedOption = times
        .where((item) => item.start == selected)
        .firstOrNull;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openSelector(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedOption == null
                          ? 'Elegir horario'
                          : _time(selectedOption.start),
                      style: const TextStyle(
                        color: DogGoTheme.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedOption == null
                          ? '${_availableCount()} horarios disponibles'
                          : 'Horario seleccionado · Toca para cambiar',
                      style: const TextStyle(
                        color: DogGoTheme.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                selectedOption == null ? 'Ver horarios' : 'Cambiar',
                style: const TextStyle(
                  color: DogGoTheme.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: DogGoTheme.teal),
            ],
          ),
        ),
      ),
    );
  }

  int _availableCount() =>
      times.where((item) => item.status == WalkTimeSlotStatus.available).length;

  Future<void> _openSelector(BuildContext context) async {
    final value = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimeSelectorSheet(times: times, initial: selected),
    );
    if (value != null) onSelected(value);
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _TimeSelectorSheet extends StatefulWidget {
  final List<WalkTimeSlotOption> times;
  final DateTime? initial;
  const _TimeSelectorSheet({required this.times, required this.initial});

  @override
  State<_TimeSelectorSheet> createState() => _TimeSelectorSheetState();
}

class _TimeSelectorSheetState extends State<_TimeSelectorSheet> {
  DateTime? _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final morning = widget.times.where((item) => item.start.hour < 12).toList();
    final afternoon = widget.times
        .where((item) => item.start.hour >= 12 && item.start.hour < 19)
        .toList();
    final night = widget.times.where((item) => item.start.hour >= 19).toList();
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        decoration: const BoxDecoration(
          color: DogGoTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DogGoTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Elige un horario',
                              style: TextStyle(
                                color: DogGoTheme.ink,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Los horarios ocupados no se pueden seleccionar.',
                              style: TextStyle(
                                color: DogGoTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _Legend(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                children: [
                  if (morning.isNotEmpty)
                    _TimeGroup(
                      title: 'Mañana',
                      icon: Icons.wb_sunny_outlined,
                      times: morning,
                      selected: _draft,
                      onSelected: _select,
                    ),
                  if (afternoon.isNotEmpty)
                    _TimeGroup(
                      title: 'Tarde',
                      icon: Icons.light_mode_outlined,
                      times: afternoon,
                      selected: _draft,
                      onSelected: _select,
                    ),
                  if (night.isNotEmpty)
                    _TimeGroup(
                      title: 'Noche',
                      icon: Icons.nightlight_outlined,
                      times: night,
                      selected: _draft,
                      onSelected: _select,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: DogGoTheme.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _draft == null
                      ? null
                      : () => Navigator.pop(context, _draft),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    _draft == null
                        ? 'Selecciona una hora'
                        : 'Confirmar ${AvailableTimeSelector._time(_draft!)}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _select(DateTime value) => setState(() => _draft = value);
}

class _TimeGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<WalkTimeSlotOption> times;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  const _TimeGroup({
    required this.title,
    required this.icon,
    required this.times,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: DogGoTheme.teal),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: DogGoTheme.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final width = (constraints.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: times
                    .map(
                      (option) => SizedBox(
                        width: width,
                        child: _TimeButton(
                          option: option,
                          selected: selected == option.start,
                          onSelected: onSelected,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final WalkTimeSlotOption option;
  final bool selected;
  final ValueChanged<DateTime> onSelected;
  const _TimeButton({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = option.status == WalkTimeSlotStatus.available;
    final label = switch (option.status) {
      WalkTimeSlotStatus.available => 'Disponible',
      WalkTimeSlotStatus.occupied => 'Ocupado',
      WalkTimeSlotStatus.blocked => 'Bloqueado',
    };
    final foreground = selected
        ? Colors.white
        : enabled
        ? DogGoTheme.teal
        : DogGoTheme.muted;
    return Material(
      color: selected
          ? DogGoTheme.teal
          : enabled
          ? Colors.white
          : const Color(0xFFF0F1F1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? () => onSelected(option.start) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? DogGoTheme.teal : DogGoTheme.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AvailableTimeSelector._time(option.start),
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                selected ? 'Seleccionado' : label,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: .82)
                      : DogGoTheme.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      _LegendItem(color: DogGoTheme.teal, text: 'Disponible'),
      _LegendItem(color: Color(0xFF9A9EA3), text: 'Ocupado'),
      _LegendItem(color: Color(0xFFD7D9DA), text: 'Bloqueado'),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: DogGoTheme.muted, fontSize: 10)),
    ],
  );
}
