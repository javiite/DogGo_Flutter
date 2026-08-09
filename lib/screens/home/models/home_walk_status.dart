enum HomeWalkStatus {
  none,
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected,
  unknown;

  bool get hasWalk => this != HomeWalkStatus.none;

  bool get isActive {
    return this == HomeWalkStatus.accepted ||
        this == HomeWalkStatus.inProgress;
  }

  bool get isFinished {
    return this == HomeWalkStatus.completed ||
        this == HomeWalkStatus.cancelled ||
        this == HomeWalkStatus.rejected;
  }

  String get label {
    switch (this) {
      case HomeWalkStatus.none:
        return 'Disponible';
      case HomeWalkStatus.pending:
        return 'Pendiente';
      case HomeWalkStatus.accepted:
        return 'Aceptado';
      case HomeWalkStatus.inProgress:
        return 'En curso';
      case HomeWalkStatus.completed:
        return 'Finalizado';
      case HomeWalkStatus.cancelled:
        return 'Cancelado';
      case HomeWalkStatus.rejected:
        return 'Rechazado';
      case HomeWalkStatus.unknown:
        return 'Por confirmar';
    }
  }

  String get eyebrow {
    switch (this) {
      case HomeWalkStatus.none:
        return 'LISTO PARA SALIR';
      case HomeWalkStatus.pending:
        return 'SOLICITUD PENDIENTE';
      case HomeWalkStatus.accepted:
        return 'PASEO CONFIRMADO';
      case HomeWalkStatus.inProgress:
        return 'PASEO EN CURSO';
      case HomeWalkStatus.completed:
        return 'PASEO FINALIZADO';
      case HomeWalkStatus.cancelled:
        return 'PASEO CANCELADO';
      case HomeWalkStatus.rejected:
        return 'SOLICITUD RECHAZADA';
      case HomeWalkStatus.unknown:
        return 'PRÓXIMO PASEO';
    }
  }

  static HomeWalkStatus fromValue(dynamic value) {
    final normalized = _normalize(
      value?.toString() ?? '',
    );

    switch (normalized) {
      case '':
        return HomeWalkStatus.none;

      case 'pendiente':
      case 'pending':
      case 'solicitado':
      case 'solicitudpendiente':

      // Mientras el dueño responde, el paseo continúa
      // siendo una solicitud pendiente y no se puede iniciar.
      case 'cambiopropuesto':
      case 'cambiodemascotaspropuesto':
      case 'petchangeproposed':
      case 'changeproposed':
      case 'propuestapendiente':
        return HomeWalkStatus.pending;

      case 'aceptado':
      case 'accepted':
      case 'confirmado':
      case 'confirmed':
        return HomeWalkStatus.accepted;

      case 'encurso':
      case 'inprogress':
      case 'iniciado':
      case 'started':
      case 'activo':
      case 'active':
        return HomeWalkStatus.inProgress;

      case 'finalizado':
      case 'finalizada':
      case 'completado':
      case 'completada':
      case 'completed':
      case 'finished':
        return HomeWalkStatus.completed;

      case 'cancelado':
      case 'cancelada':
      case 'cancelled':
      case 'canceled':
        return HomeWalkStatus.cancelled;

      case 'rechazado':
      case 'rechazada':
      case 'rejected':
        return HomeWalkStatus.rejected;

      default:
        return HomeWalkStatus.unknown;
    }
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[\s_\-]'), '');
  }
}