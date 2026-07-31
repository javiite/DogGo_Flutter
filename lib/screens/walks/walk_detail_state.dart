import '../home/models/home_walk_status.dart';
import 'models/walk_detail.dart';

enum WalkDetailRecommendedAction {
  waitForWalker,
  reviewRequest,
  preparePet,
  startWalk,
  uploadStartEvidence,
  activateTracking,
  followRoute,
  uploadEndEvidence,
  finishWalk,
  rateExperience,
  completed,
  cancelled,
  unavailable,
}

class WalkDetailState {
  final bool loading;
  final bool acting;
  final String? error;
  final String? baseUrl;
  final String role;
  final int? requestedId;
  final WalkDetail? walk;

  const WalkDetailState({
    this.loading = true,
    this.acting = false,
    this.error,
    this.baseUrl,
    this.role = '',
    this.requestedId,
    this.walk,
  });

  bool get hasWalk => walk != null;

  bool get isWalker {
    final value = _normalizeRole(role);

    return value == 'paseador' ||
        value == 'walker' ||
        value == 'dogwalker';
  }

  bool get isOwner {
    final value = _normalizeRole(role);

    return value == 'duenio' ||
        value == 'owner' ||
        value == 'cliente';
  }

  bool get isAdmin {
    final value = _normalizeRole(role);

    return value == 'admin' ||
        value == 'administrador';
  }

  int? get walkId {
    final currentId = walk?.id;

    if (currentId != null && currentId > 0) {
      return currentId;
    }

    return requestedId;
  }

  bool get canAccept {
    return !acting &&
        isWalker &&
        walk?.isPending == true;
  }

  bool get canReject {
    return !acting &&
        isWalker &&
        walk?.isPending == true;
  }

  bool get canStart {
    return !acting &&
        isWalker &&
        walk?.isAccepted == true;
  }

  bool get canFinish {
    return !acting &&
        isWalker &&
        walk?.isInProgress == true &&
        walk?.hasEndEvidence == true;
  }

  bool get needsEndEvidence {
    return isWalker &&
        walk?.isInProgress == true &&
        walk?.hasEndEvidence == false;
  }

  bool get canCancel {
    final current = walk;

    if (acting || current == null) {
      return false;
    }

    if (current.isFinished) {
      return false;
    }

    return isWalker || isOwner;
  }

  bool get canRate {
    return !acting &&
        isOwner &&
        walk?.isCompleted == true &&
        walk?.rated != true;
  }

  bool get canOpenChat {
    final current = walk;

    if (current == null ||
        !current.hasValidId ||
        current.isCancelled ||
        current.isRejected) {
      return false;
    }

    return isOwner || isWalker;
  }

  bool get canOpenMap {
    final current = walk;

    if (current == null ||
        !current.hasValidId) {
      return false;
    }

    return current.hasPickupCoordinates ||
        current.isInProgress ||
        current.isCompleted;
  }

  bool get canUploadStartEvidence {
    return isWalker &&
        walk?.isInProgress == true &&
        walk?.hasStartEvidence == false;
  }

  bool get canUploadEndEvidence {
    return isWalker &&
        walk?.isInProgress == true &&
        walk?.hasEndEvidence == false;
  }

  bool get canOpenTracking {
    return isWalker &&
        walk?.isInProgress == true;
  }

  String get statusMessage {
    final current = walk;

    if (current == null) {
      return 'No hay información disponible.';
    }

    switch (current.status) {
      case HomeWalkStatus.pending:
        return isWalker
            ? 'Revisa la solicitud y decide si puedes realizar el paseo.'
            : 'La solicitud fue enviada y está esperando respuesta del paseador.';

      case HomeWalkStatus.accepted:
        return isWalker
            ? 'El servicio está confirmado. Inícialo cuando llegues con la mascota.'
            : 'El paseador aceptó la solicitud y el servicio está confirmado.';

      case HomeWalkStatus.inProgress:
        if (!current.hasStartEvidence) {
          return 'El paseo está activo. Falta registrar la evidencia inicial.';
        }

        if (!current.hasEndEvidence) {
          return isWalker
              ? 'Mantén el seguimiento activo y registra la evidencia al terminar.'
              : 'El paseo está activo. Puedes consultar el recorrido y comunicarte por chat.';
        }

        return isWalker
            ? 'La evidencia final está lista. Ya puedes finalizar el paseo.'
            : 'El paseo está por terminar. La evidencia final ya fue registrada.';

      case HomeWalkStatus.completed:
        return isOwner && !current.rated
            ? 'El servicio terminó correctamente. Ahora puedes calificar la experiencia.'
            : 'El paseo finalizó correctamente.';

      case HomeWalkStatus.cancelled:
        return current.cancellationReason == null
            ? 'Este paseo fue cancelado.'
            : 'Este paseo fue cancelado: ${current.cancellationReason}';

      case HomeWalkStatus.rejected:
        return 'La solicitud fue rechazada por el paseador.';

      case HomeWalkStatus.none:
      case HomeWalkStatus.unknown:
        return 'El estado del paseo está pendiente de confirmación.';
    }
  }

  WalkDetailRecommendedAction
      get recommendedAction {
    final current = walk;

    if (current == null) {
      return WalkDetailRecommendedAction.unavailable;
    }

    if (current.isPending) {
      return isWalker
          ? WalkDetailRecommendedAction.reviewRequest
          : WalkDetailRecommendedAction.waitForWalker;
    }

    if (current.isAccepted) {
      return isWalker
          ? WalkDetailRecommendedAction.startWalk
          : WalkDetailRecommendedAction.preparePet;
    }

    if (current.isInProgress) {
      if (!current.hasStartEvidence && isWalker) {
        return WalkDetailRecommendedAction
            .uploadStartEvidence;
      }

      if (!current.hasEndEvidence) {
        return isWalker
            ? WalkDetailRecommendedAction
                .activateTracking
            : WalkDetailRecommendedAction.followRoute;
      }

      return isWalker
          ? WalkDetailRecommendedAction.finishWalk
          : WalkDetailRecommendedAction.followRoute;
    }

    if (current.isCompleted) {
      if (isOwner && !current.rated) {
        return WalkDetailRecommendedAction
            .rateExperience;
      }

      return WalkDetailRecommendedAction.completed;
    }

    if (current.isCancelled ||
        current.isRejected) {
      return WalkDetailRecommendedAction.cancelled;
    }

    return WalkDetailRecommendedAction.unavailable;
  }

  String get recommendedTitle {
    switch (recommendedAction) {
      case WalkDetailRecommendedAction.waitForWalker:
        return 'Esperando confirmación';
      case WalkDetailRecommendedAction.reviewRequest:
        return 'Revisa la solicitud';
      case WalkDetailRecommendedAction.preparePet:
        return 'Prepara a tu mascota';
      case WalkDetailRecommendedAction.startWalk:
        return 'Listo para iniciar';
      case WalkDetailRecommendedAction
            .uploadStartEvidence:
        return 'Registra la entrega';
      case WalkDetailRecommendedAction.activateTracking:
        return 'Mantén activo el seguimiento';
      case WalkDetailRecommendedAction.followRoute:
        return 'Consulta el recorrido';
      case WalkDetailRecommendedAction
            .uploadEndEvidence:
        return 'Registra el final';
      case WalkDetailRecommendedAction.finishWalk:
        return 'Finaliza el servicio';
      case WalkDetailRecommendedAction.rateExperience:
        return 'Califica la experiencia';
      case WalkDetailRecommendedAction.completed:
        return 'Servicio completado';
      case WalkDetailRecommendedAction.cancelled:
        return 'Servicio cerrado';
      case WalkDetailRecommendedAction.unavailable:
        return 'Información no disponible';
    }
  }

  String get recommendedDescription {
    switch (recommendedAction) {
      case WalkDetailRecommendedAction.waitForWalker:
        return 'Te avisaremos cuando el paseador responda a la solicitud.';
      case WalkDetailRecommendedAction.reviewRequest:
        return 'Confirma que el horario, mascota, precio y punto de recogida sean correctos.';
      case WalkDetailRecommendedAction.preparePet:
        return 'Ten listo su collar, correa y cualquier indicación importante.';
      case WalkDetailRecommendedAction.startWalk:
        return 'Inicia el paseo al encontrarte con la mascota y registra la evidencia.';
      case WalkDetailRecommendedAction
            .uploadStartEvidence:
        return 'Sube una fotografía que confirme la recepción de la mascota.';
      case WalkDetailRecommendedAction.activateTracking:
        return 'Comparte la ubicación durante el recorrido y registra la evidencia final.';
      case WalkDetailRecommendedAction.followRoute:
        return 'Revisa la ubicación y utiliza el chat si necesitas comunicarte.';
      case WalkDetailRecommendedAction
            .uploadEndEvidence:
        return 'Sube una fotografía antes de cerrar el servicio.';
      case WalkDetailRecommendedAction.finishWalk:
        return 'La evidencia está completa y el paseo puede finalizar.';
      case WalkDetailRecommendedAction.rateExperience:
        return 'Comparte tu opinión para cerrar correctamente el servicio.';
      case WalkDetailRecommendedAction.completed:
        return 'Toda la información del paseo quedó registrada.';
      case WalkDetailRecommendedAction.cancelled:
        return 'Consulta el motivo y los datos del cierre.';
      case WalkDetailRecommendedAction.unavailable:
        return 'Actualiza la pantalla o intenta nuevamente.';
    }
  }

  String? get petPhotoUrl {
    return walk?.publicPetPhotoUrl(baseUrl);
  }

  String? get startPhotoUrl {
    return walk?.publicStartPhotoUrl(baseUrl);
  }

  String? get endPhotoUrl {
    return walk?.publicEndPhotoUrl(baseUrl);
  }

  WalkDetailState copyWith({
    bool? loading,
    bool? acting,
    String? error,
    bool clearError = false,
    String? baseUrl,
    String? role,
    int? requestedId,
    WalkDetail? walk,
    bool clearWalk = false,
  }) {
    return WalkDetailState(
      loading: loading ?? this.loading,
      acting: acting ?? this.acting,
      error: clearError
          ? null
          : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      role: role ?? this.role,
      requestedId:
          requestedId ?? this.requestedId,
      walk: clearWalk ? null : walk ?? this.walk,
    );
  }

  static String _normalizeRole(String value) {
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