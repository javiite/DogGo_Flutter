import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class AvailableDateSelector extends StatefulWidget {
  final List<DateTime> dates;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  const AvailableDateSelector({
    super.key,
    required this.dates,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<AvailableDateSelector> createState() => _AvailableDateSelectorState();
}

class _AvailableDateSelectorState extends State<AvailableDateSelector> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(widget.selected ?? _firstDate);
  }

  @override
  void didUpdateWidget(covariant AvailableDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != null &&
        !_sameDay(widget.selected, oldWidget.selected)) {
      _weekStart = _mondayOf(widget.selected!);
    }
  }

  DateTime get _firstDate => widget.dates.isEmpty
      ? DateTime.now()
      : widget.dates.reduce((a, b) => a.isBefore(b) ? a : b);
  DateTime get _lastDate => widget.dates.isEmpty
      ? DateTime.now()
      : widget.dates.reduce((a, b) => a.isAfter(b) ? a : b);

  @override
  Widget build(BuildContext context) {
    if (widget.dates.isEmpty) return const SizedBox.shrink();
    final days = List.generate(
      7,
      (index) => _weekStart.add(Duration(days: index)),
    );
    final canBack = _weekStart.isAfter(_mondayOf(_firstDate));
    final canForward = _weekStart
        .add(const Duration(days: 7))
        .isBefore(_lastDate.add(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_months[_weekStart.month - 1]} ${_weekStart.year}',
                  style: const TextStyle(
                    color: DogGoTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Calendario',
                onPressed: _openCalendar,
                icon: const Icon(Icons.calendar_month_rounded),
              ),
              IconButton(
                tooltip: 'Semana anterior',
                onPressed: canBack ? () => _moveWeek(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Semana siguiente',
                onPressed: canForward ? () => _moveWeek(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DayButton(
                      date: day,
                      enabled: _contains(day),
                      selected: _sameDay(day, widget.selected),
                      onTap: () => widget.onSelected(day),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _moveWeek(int direction) => setState(
    () => _weekStart = _weekStart.add(Duration(days: 7 * direction)),
  );

  Future<void> _openCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selected ?? _firstDate,
      firstDate: _firstDate,
      lastDate: _lastDate,
      selectableDayPredicate: _contains,
      helpText: 'Selecciona el día del paseo',
    );
    if (picked == null || !mounted) return;
    setState(() => _weekStart = _mondayOf(picked));
    widget.onSelected(picked);
  }

  bool _contains(DateTime date) =>
      widget.dates.any((item) => _sameDay(item, date));
  static DateTime _mondayOf(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    return clean.subtract(Duration(days: clean.weekday - 1));
  }

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
  static const _months = [
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
}

class _DayButton extends StatelessWidget {
  final DateTime date;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;
  const _DayButton({
    required this.date,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = DogGoTheme.muted.withValues(alpha: .4);
    return Material(
      color: selected ? DogGoTheme.teal : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 70,
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
                _days[date.weekday - 1],
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: .85)
                      : enabled
                      ? DogGoTheme.muted
                      : muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : enabled
                      ? DogGoTheme.ink
                      : muted,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
}
