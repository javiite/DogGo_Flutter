class WalkerSchedule {
  final int weekday;
  final String startTime;
  final String endTime;
  final bool active;

  const WalkerSchedule({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.active,
  });

  factory WalkerSchedule.fromMap(Map<String, dynamic> map) {
    return WalkerSchedule(
      weekday: _integer(map['diaSemana']) ?? 0,
      startTime: _time(map['horaInicio']),
      endTime: _time(map['horaFin']),
      active: _boolean(map['activo'], fallback: true),
    );
  }

  String get dayLabel => const [
    'Domingo',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ][weekday.clamp(0, 6)];

  String get shortDayLabel => const [
    'Dom',
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
  ][weekday.clamp(0, 6)];

  String get timeRange => '$startTime–$endTime';

  DateTime nextStart([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final currentWeekday = now.weekday % 7;
    var offset = (weekday - currentWeekday + 7) % 7;
    final parts = startTime.split(':');
    final hour = parts.isEmpty ? 0 : int.tryParse(parts.first) ?? 0;
    final minute = parts.length < 2 ? 0 : int.tryParse(parts[1]) ?? 0;
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: offset));
    if (!next.isAfter(now)) {
      offset += 7;
      next = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).add(Duration(days: offset));
    }
    return next;
  }

  String nextDateLabel([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final next = nextStart(now);
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(next.year, next.month, next.day);
    final days = date.difference(today).inDays;
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Mañana';
    const months = [
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
    return '$shortDayLabel ${next.day} ${months[next.month - 1]}';
  }

  static int? _integer(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  static String _time(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.length >= 5) return text.substring(0, 5);
    return text.isEmpty ? '--:--' : text;
  }

  static bool _boolean(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return fallback;
  }
}

class WalkerBusyBlock {
  final DateTime start;
  final DateTime end;

  const WalkerBusyBlock({required this.start, required this.end});

  factory WalkerBusyBlock.fromMap(Map<String, dynamic> map) {
    return WalkerBusyBlock(
      start: _dateTime(map['inicioUtc']),
      end: _dateTime(map['finUtc']),
    );
  }

  bool get isValid => end.isAfter(start);

  String get dateLabel {
    const months = [
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
    return '${start.day} ${months[start.month - 1]}';
  }

  String get timeRange => '${_clock(start)}–${_clock(end)}';

  static DateTime _dateTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return (parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        .toLocal();
  }

  static String _clock(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class WalkerAvailability {
  final bool available;
  final String timeZone;
  final List<WalkerSchedule> schedules;
  final List<WalkerBusyBlock> busyBlocks;

  const WalkerAvailability({
    required this.available,
    required this.timeZone,
    required this.schedules,
    required this.busyBlocks,
  });

  const WalkerAvailability.empty()
    : available = false,
      timeZone = '',
      schedules = const [],
      busyBlocks = const [];

  factory WalkerAvailability.fromMap(Map<String, dynamic> map) {
    final rawSchedules = map['horarios'];
    final schedules = rawSchedules is List
        ? rawSchedules
              .whereType<Map>()
              .map(
                (item) =>
                    WalkerSchedule.fromMap(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.active)
              .toList(growable: false)
        : const <WalkerSchedule>[];

    final rawBusy = <dynamic>[
      if (map['bloqueos'] is List) ...(map['bloqueos'] as List),
      if (map['ocupaciones'] is List) ...(map['ocupaciones'] as List),
    ];
    final busyBlocks =
        rawBusy
            .whereType<Map>()
            .map(
              (item) =>
                  WalkerBusyBlock.fromMap(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.isValid && item.end.isAfter(DateTime.now()))
            .toList(growable: false)
          ..sort((a, b) => a.start.compareTo(b.start));

    return WalkerAvailability(
      available: map['disponible'] == true,
      timeZone: map['zonaHoraria']?.toString().trim() ?? '',
      schedules: schedules,
      busyBlocks: busyBlocks,
    );
  }

  bool get hasSchedules => schedules.isNotEmpty;

  bool get hasBusyBlocks => busyBlocks.isNotEmpty;

  List<WalkerSchedule> get upcomingSchedules {
    final result = [...schedules];
    result.sort((a, b) => a.nextStart().compareTo(b.nextStart()));
    return result;
  }
}
