import 'models/walker_availability.dart';

class AvailabilityState {
  final bool loading;
  final bool saving;
  final bool available;
  final String timeZone;
  final List<WalkerScheduleSlot> schedules;
  final List<WalkerCalendarBlock> blocks;
  final List<WalkerCalendarBlock> occupations;
  final String? error;

  const AvailabilityState({
    this.loading = true,
    this.saving = false,
    this.available = true,
    this.timeZone = 'America/Mexico_City',
    this.schedules = const [],
    this.blocks = const [],
    this.occupations = const [],
    this.error,
  });

  AvailabilityState copyWith({
    bool? loading,
    bool? saving,
    bool? available,
    String? timeZone,
    List<WalkerScheduleSlot>? schedules,
    List<WalkerCalendarBlock>? blocks,
    List<WalkerCalendarBlock>? occupations,
    String? error,
    bool clearError = false,
  }) {
    return AvailabilityState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      available: available ?? this.available,
      timeZone: timeZone ?? this.timeZone,
      schedules: schedules ?? this.schedules,
      blocks: blocks ?? this.blocks,
      occupations: occupations ?? this.occupations,
      error: clearError ? null : error ?? this.error,
    );
  }
}
