import 'package:flutter/foundation.dart';

import '../../services/paseador_disponibilidad_service.dart';
import 'availability_state.dart';
import 'models/walker_availability.dart';

class AvailabilityController extends ChangeNotifier {
  AvailabilityState _state = const AvailabilityState();
  bool _disposed = false;

  AvailabilityState get state => _state;

  Future<void> load() async {
    _set(_state.copyWith(loading: true, clearError: true));
    try {
      final now = DateTime.now();
      final map = await PaseadorDisponibilidadService.obtenerMiAgenda(
        desdeUtc: now.subtract(const Duration(days: 7)),
        hastaUtc: now.add(const Duration(days: 60)),
      );
      final data = WalkerAvailability.fromMap(map);
      _set(
        _state.copyWith(
          loading: false,
          available: data.available,
          timeZone: data.timeZone,
          schedules: _completeWeek(data.schedules),
          blocks: data.blocks,
          occupations: data.occupations,
          clearError: true,
        ),
      );
    } catch (error) {
      _set(
        _state.copyWith(
          loading: false,
          error: _message(error, 'No se pudo cargar tu agenda.'),
        ),
      );
    }
  }

  void setAvailable(bool value) {
    _set(_state.copyWith(available: value, clearError: true));
  }

  void updateDay(WalkerScheduleSlot slot) {
    final items = [..._state.schedules];
    final index = items.indexWhere((item) => item.weekday == slot.weekday);
    if (index < 0) {
      items.add(slot);
    } else {
      items[index] = slot;
    }
    items.sort((a, b) => a.weekday.compareTo(b.weekday));
    _set(_state.copyWith(schedules: items, clearError: true));
  }

  void setSchedules(List<WalkerScheduleSlot> schedules) {
    _set(_state.copyWith(schedules: schedules, clearError: true));
  }

  Future<String?> save() async {
    if (_state.saving) return null;
    for (final slot in _state.schedules.where((item) => item.active)) {
      if (_minutes(slot.start) >= _minutes(slot.end)) {
        return 'En ${_dayName(slot.weekday)}, la hora final debe ser posterior a la inicial.';
      }
    }
    _set(_state.copyWith(saving: true, clearError: true));
    try {
      await PaseadorDisponibilidadService.guardarMiAgenda(
        disponible: _state.available,
        zonaHoraria: _state.timeZone,
        horarios: _state.schedules.map((item) => item.toMap()).toList(),
      );
      _set(_state.copyWith(saving: false, clearError: true));
      return 'Tu disponibilidad quedó guardada.';
    } catch (error) {
      final message = _message(error, 'No se pudo guardar tu disponibilidad.');
      _set(_state.copyWith(saving: false, error: message));
      return message;
    }
  }

  Future<String?> createBlock({
    required DateTime start,
    required DateTime end,
    String? reason,
  }) async {
    if (!end.isAfter(start)) return 'El final debe ser posterior al inicio.';
    _set(_state.copyWith(saving: true, clearError: true));
    try {
      await PaseadorDisponibilidadService.crearBloqueo(
        inicioUtc: start.toUtc(),
        finUtc: end.toUtc(),
        motivo: reason,
      );
      await load();
      _set(_state.copyWith(saving: false, clearError: true));
      return 'El bloqueo quedó agregado a tu agenda.';
    } catch (error) {
      final message = _message(error, 'No se pudo crear el bloqueo.');
      _set(_state.copyWith(saving: false, error: message));
      return message;
    }
  }

  Future<String?> deleteBlock(int id) async {
    _set(_state.copyWith(saving: true, clearError: true));
    try {
      await PaseadorDisponibilidadService.eliminarBloqueo(id);
      await load();
      _set(_state.copyWith(saving: false, clearError: true));
      return 'Bloqueo eliminado.';
    } catch (error) {
      final message = _message(error, 'No se pudo eliminar el bloqueo.');
      _set(_state.copyWith(saving: false, error: message));
      return message;
    }
  }

  static List<WalkerScheduleSlot> _completeWeek(
    List<WalkerScheduleSlot> source,
  ) {
    final result = [...source];
    for (var weekday = 0; weekday < 7; weekday++) {
      if (!result.any((item) => item.weekday == weekday)) {
        result.add(
          WalkerScheduleSlot(
            weekday: weekday,
            start: '09:00',
            end: '18:00',
            active: weekday != 0,
          ),
        );
      }
    }
    result.sort((a, b) => a.weekday.compareTo(b.weekday));
    return result;
  }

  static int _minutes(String value) {
    final parts = value.split(':');
    return (int.tryParse(parts.first) ?? 0) * 60 +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  static String _dayName(int day) => const [
    'domingo',
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
  ][day.clamp(0, 6)];

  static String _message(Object error, String fallback) {
    final value = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();
    return value.isEmpty ? fallback : value;
  }

  void _set(AvailabilityState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
