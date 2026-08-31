class WalkerScheduleSlot {
  final int weekday;
  final String start;
  final String end;
  final bool active;

  const WalkerScheduleSlot({
    required this.weekday,
    required this.start,
    required this.end,
    this.active = true,
  });

  factory WalkerScheduleSlot.fromMap(Map<String, dynamic> map) {
    return WalkerScheduleSlot(
      weekday: _int(map['diaSemana']),
      start: _time(map['horaInicio'], '09:00'),
      end: _time(map['horaFin'], '18:00'),
      active: _bool(map['activo'], true),
    );
  }

  WalkerScheduleSlot copyWith({
    int? weekday,
    String? start,
    String? end,
    bool? active,
  }) {
    return WalkerScheduleSlot(
      weekday: weekday ?? this.weekday,
      start: start ?? this.start,
      end: end ?? this.end,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => {
    'diaSemana': weekday,
    'horaInicio': start,
    'horaFin': end,
    'activo': active,
  };

  static int _int(dynamic value) => int.tryParse('$value') ?? 0;
  static bool _bool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true' ? true : fallback;
  }

  static String _time(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    if (text.length < 5) return fallback;
    return text.substring(0, 5);
  }
}

class WalkerCalendarBlock {
  final int id;
  final DateTime startUtc;
  final DateTime endUtc;
  final String? reason;

  const WalkerCalendarBlock({
    required this.id,
    required this.startUtc,
    required this.endUtc,
    this.reason,
  });

  factory WalkerCalendarBlock.fromMap(Map<String, dynamic> map) {
    return WalkerCalendarBlock(
      id: int.tryParse('${map['id']}') ?? 0,
      startUtc: _date(map['inicioUtc']),
      endUtc: _date(map['finUtc']),
      reason: map['motivo']?.toString(),
    );
  }

  DateTime get localStart => startUtc.toLocal();
  DateTime get localEnd => endUtc.toLocal();

  static DateTime _date(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class EditableWalkerAvailability {
  final int walkerId;
  final bool available;
  final String timeZone;
  final List<WalkerScheduleSlot> schedules;
  final List<WalkerCalendarBlock> blocks;
  final List<WalkerCalendarBlock> occupations;

  const EditableWalkerAvailability({
    required this.walkerId,
    required this.available,
    required this.timeZone,
    required this.schedules,
    required this.blocks,
    required this.occupations,
  });

  factory EditableWalkerAvailability.fromMap(Map<String, dynamic> map) {
    return EditableWalkerAvailability(
      walkerId: int.tryParse('${map['paseadorId']}') ?? 0,
      available: _bool(map['disponible'], true),
      timeZone: map['zonaHoraria']?.toString() ?? 'America/Mexico_City',
      schedules: _maps(
        map['horarios'],
      ).map(WalkerScheduleSlot.fromMap).toList(),
      blocks: _maps(map['bloqueos']).map(WalkerCalendarBlock.fromMap).toList(),
      occupations: _maps(
        map['ocupaciones'],
      ).map(WalkerCalendarBlock.fromMap).toList(),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static bool _bool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true' ? true : fallback;
  }
}
