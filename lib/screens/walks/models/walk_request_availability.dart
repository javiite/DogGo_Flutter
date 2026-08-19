class WalkRequestAvailability {
  final bool available;
  final List<WalkAvailabilitySchedule> schedules;
  final List<WalkUnavailablePeriod> unavailablePeriods;

  const WalkRequestAvailability({
    required this.available,
    required this.schedules,
    required this.unavailablePeriods,
  });

  factory WalkRequestAvailability.fromMap(Map<String, dynamic> map) {
    final periods = <WalkUnavailablePeriod>[
      ..._maps(
        map['bloqueos'] ?? map['Bloqueos'],
      ).map((item) => WalkUnavailablePeriod.fromMap(item, occupied: false)),
      ..._maps(
        map['ocupaciones'] ?? map['Ocupaciones'],
      ).map((item) => WalkUnavailablePeriod.fromMap(item, occupied: true)),
    ];
    return WalkRequestAvailability(
      available: _bool(map['disponible'] ?? map['Disponible']),
      schedules: _maps(map['horarios'] ?? map['Horarios'])
          .map(WalkAvailabilitySchedule.fromMap)
          .where((item) => item.active)
          .toList(),
      unavailablePeriods: periods,
    );
  }

  List<DateTime> availableDays(DateTime from, {int count = 30}) {
    if (!available) return const [];
    final first = DateTime(from.year, from.month, from.day);
    return List.generate(count, (index) => first.add(Duration(days: index)))
        .where(
          (day) => schedules.any((item) => item.weekday == day.weekday % 7),
        )
        .toList();
  }

  List<DateTime> slotsFor(DateTime day, int durationMinutes) {
    return slotOptionsFor(day, durationMinutes)
        .where((item) => item.status == WalkTimeSlotStatus.available)
        .map((item) => item.start)
        .toList(growable: false);
  }

  List<WalkTimeSlotOption> slotOptionsFor(
    DateTime day,
    int durationMinutes, {
    List<WalkUnavailablePeriod> localReservations = const [],
  }) {
    if (!available) return const [];
    final result = <WalkTimeSlotOption>[];
    final weekday = day.weekday % 7;
    for (final schedule in schedules.where((item) => item.weekday == weekday)) {
      var cursor = DateTime(
        day.year,
        day.month,
        day.day,
      ).add(Duration(minutes: schedule.startMinutes));
      final limit = DateTime(
        day.year,
        day.month,
        day.day,
      ).add(Duration(minutes: schedule.endMinutes));
      while (!cursor.add(Duration(minutes: durationMinutes)).isAfter(limit)) {
        final end = cursor.add(Duration(minutes: durationMinutes));
        final future = cursor.isAfter(
          DateTime.now().add(const Duration(minutes: 15)),
        );
        final collisions = [...unavailablePeriods, ...localReservations].where(
          (period) =>
              cursor.toUtc().isBefore(period.endUtc) &&
              end.toUtc().isAfter(period.startUtc),
        );
        if (future) {
          final status = collisions.isEmpty
              ? WalkTimeSlotStatus.available
              : collisions.any((period) => period.occupied)
              ? WalkTimeSlotStatus.occupied
              : WalkTimeSlotStatus.blocked;
          result.add(WalkTimeSlotOption(cursor, status));
        }
        cursor = cursor.add(const Duration(minutes: 30));
      }
    }
    return result;
  }

  bool accepts(DateTime start, int durationMinutes) {
    return slotsFor(start, durationMinutes).any((slot) => slot == start);
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }
}

class WalkAvailabilitySchedule {
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final bool active;
  const WalkAvailabilitySchedule(
    this.weekday,
    this.startMinutes,
    this.endMinutes,
    this.active,
  );

  factory WalkAvailabilitySchedule.fromMap(Map<String, dynamic> map) =>
      WalkAvailabilitySchedule(
        int.tryParse('${map['diaSemana'] ?? map['DiaSemana']}') ?? 0,
        _minutes(map['horaInicio'] ?? map['HoraInicio']),
        _minutes(map['horaFin'] ?? map['HoraFin']),
        WalkRequestAvailability._bool(map['activo'] ?? map['Activo']),
      );

  static int _minutes(dynamic value) {
    final parts = value.toString().split(':');
    return (int.tryParse(parts.first) ?? 0) * 60 +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }
}

class WalkUnavailablePeriod {
  final DateTime startUtc;
  final DateTime endUtc;
  final bool occupied;
  const WalkUnavailablePeriod(this.startUtc, this.endUtc, this.occupied);

  factory WalkUnavailablePeriod.fromMap(
    Map<String, dynamic> map, {
    required bool occupied,
  }) => WalkUnavailablePeriod(
    DateTime.parse('${map['inicioUtc'] ?? map['InicioUtc']}').toUtc(),
    DateTime.parse('${map['finUtc'] ?? map['FinUtc']}').toUtc(),
    occupied,
  );
}

enum WalkTimeSlotStatus { available, occupied, blocked }

class WalkTimeSlotOption {
  final DateTime start;
  final WalkTimeSlotStatus status;

  const WalkTimeSlotOption(this.start, this.status);
}
