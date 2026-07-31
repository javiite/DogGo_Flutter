import 'models/tracking_session.dart';

class LiveTrackingState {
  final int walkId;
  final String petName;
  final String walkerName;
  final bool loading;
  final bool processing;
  final bool serviceRunning;
  final bool changed;
  final String? error;
  final TrackingSession? session;
  final int successfulUpdates;
  final double? accuracy;
  final double? speed;
  final double? altitude;

  const LiveTrackingState({
    required this.walkId,
    required this.petName,
    required this.walkerName,
    this.loading = true,
    this.processing = false,
    this.serviceRunning = false,
    this.changed = false,
    this.error,
    this.session,
    this.successfulUpdates = 0,
    this.accuracy,
    this.speed,
    this.altitude,
  });

  bool get isCurrentWalkActive {
    return serviceRunning &&
        session?.active == true &&
        session?.walkId == walkId;
  }

  bool get anotherWalkIsActive {
    return serviceRunning &&
        session?.active == true &&
        session?.walkId != walkId;
  }

  bool get hasLocation {
    return session?.hasCoordinates == true;
  }

  String get coordinatesLabel {
    return session?.coordinatesLabel ??
        'Sin ubicación registrada';
  }

  String get lastSentLabel {
    return session?.timeLabel ??
        'Aún no enviada';
  }

  String get accuracyLabel {
    final value = accuracy;

    if (value == null ||
        value <= 0 ||
        !value.isFinite) {
      return 'N/D';
    }

    return '${value.toStringAsFixed(1)} m';
  }

  String get speedLabel {
    final value = speed;

    if (value == null ||
        value < 0 ||
        !value.isFinite) {
      return 'N/D';
    }

    return '${(value * 3.6).toStringAsFixed(1)} km/h';
  }

  String get altitudeLabel {
    final value = altitude;

    if (value == null ||
        value == 0 ||
        !value.isFinite) {
      return 'N/D';
    }

    return '${value.toStringAsFixed(1)} m';
  }

  String get statusTitle {
    if (anotherWalkIsActive) {
      return 'Otro paseo está compartiendo ubicación';
    }

    if (isCurrentWalkActive) {
      return 'Ubicación en vivo activa';
    }

    if (hasLocation) {
      return 'Última ubicación registrada';
    }

    return 'Ubicación sin iniciar';
  }

  String get statusDescription {
    if (anotherWalkIsActive) {
      return 'Detén el seguimiento del otro paseo antes de activar este servicio.';
    }

    if (isCurrentWalkActive) {
      return 'DogGo continúa enviando la ubicación aunque salgas de esta pantalla.';
    }

    if (hasLocation) {
      return 'La última posición permanece visible en el mapa del paseo.';
    }

    return 'Activa la ubicación para compartir el avance con el dueño.';
  }

  LiveTrackingState copyWith({
    int? walkId,
    String? petName,
    String? walkerName,
    bool? loading,
    bool? processing,
    bool? serviceRunning,
    bool? changed,
    String? error,
    bool clearError = false,
    TrackingSession? session,
    bool clearSession = false,
    int? successfulUpdates,
    double? accuracy,
    bool clearAccuracy = false,
    double? speed,
    bool clearSpeed = false,
    double? altitude,
    bool clearAltitude = false,
  }) {
    return LiveTrackingState(
      walkId: walkId ?? this.walkId,
      petName: petName ?? this.petName,
      walkerName:
          walkerName ?? this.walkerName,
      loading: loading ?? this.loading,
      processing:
          processing ?? this.processing,
      serviceRunning:
          serviceRunning ?? this.serviceRunning,
      changed: changed ?? this.changed,
      error:
          clearError ? null : error ?? this.error,
      session:
          clearSession ? null : session ?? this.session,
      successfulUpdates:
          successfulUpdates ??
              this.successfulUpdates,
      accuracy: clearAccuracy
          ? null
          : accuracy ?? this.accuracy,
      speed:
          clearSpeed ? null : speed ?? this.speed,
      altitude: clearAltitude
          ? null
          : altitude ?? this.altitude,
    );
  }
}