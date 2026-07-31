import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/calificaciones_service.dart';
import 'models/rating_option.dart';
import 'rating_state.dart';

enum RatingResultCode {
  submitted,
  invalidWalk,
  invalidComment,
  alreadyRated,
  failed,
}

class RatingResult {
  final bool success;
  final String message;
  final RatingResultCode code;

  const RatingResult({
    required this.success,
    required this.message,
    required this.code,
  });

  const RatingResult.success(
    this.message,
  )   : success = true,
        code = RatingResultCode.submitted;

  const RatingResult.failure(
    this.message, {
    this.code = RatingResultCode.failed,
  }) : success = false;
}

class RatingController
    extends ChangeNotifier {
  static const int minimumCommentLength = 3;
  static const int maximumCommentLength = 250;

  final CalificacionesService _service;

  RatingState _state;

  bool _disposed = false;
  bool _submitInProgress = false;

  RatingController({
    required int walkId,
    required String petName,
    required String walkerName,
    CalificacionesService? service,
  })  : _service =
            service ?? CalificacionesService(),
        _state = RatingState(
          walkId: walkId,
          petName: petName,
          walkerName: walkerName,
        );

  RatingState get state => _state;

  Future<void> initialize() async {
    if (_state.walkId <= 0) {
      _setState(
        _state.copyWith(
          checking: false,
          error:
              'No se pudo identificar el paseo.',
        ),
      );
      return;
    }

    _setState(
      _state.copyWith(
        checking: true,
        clearError: true,
      ),
    );

    try {
      final alreadyRated =
          await _service.paseoYaCalificado(
        _state.walkId,
      );

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          checking: false,
          alreadyRated: alreadyRated,
          clearError: true,
        ),
      );
    } catch (_) {
      if (_disposed) {
        return;
      }

      // Si el backend no tiene disponible el
      // endpoint de consulta, permitimos que el
      // endpoint de envío valide duplicados.
      _setState(
        _state.copyWith(
          checking: false,
          alreadyRated: false,
          clearError: true,
        ),
      );
    }
  }

  void selectScore(int score) {
    if (_state.busy) {
      return;
    }

    if (score < 1 || score > 5) {
      return;
    }

    _setState(
      _state.copyWith(
        selectedRating:
            RatingOptionData.fromScore(score),
        clearError: true,
      ),
    );
  }

  Future<RatingResult> submit(
    String comment,
  ) async {
    if (_submitInProgress) {
      return const RatingResult.failure(
        'La calificación ya se está enviando.',
      );
    }

    if (_state.walkId <= 0) {
      return const RatingResult.failure(
        'No se pudo identificar el paseo.',
        code: RatingResultCode.invalidWalk,
      );
    }

    if (_state.alreadyRated) {
      return const RatingResult.failure(
        'Este paseo ya fue calificado.',
        code: RatingResultCode.alreadyRated,
      );
    }

    final cleanComment = comment.trim();

    if (cleanComment.length <
        minimumCommentLength) {
      return const RatingResult.failure(
        'Escribe un comentario más completo.',
        code: RatingResultCode.invalidComment,
      );
    }

    if (cleanComment.length >
        maximumCommentLength) {
      return const RatingResult.failure(
        'El comentario supera los 250 caracteres.',
        code: RatingResultCode.invalidComment,
      );
    }

    _submitInProgress = true;

    _setState(
      _state.copyWith(
        submitting: true,
        clearError: true,
      ),
    );

    try {
      await _service.calificarPaseo(
        paseoId: _state.walkId,
        puntaje: _state.score,
        comentario: cleanComment,
      );

      if (_disposed) {
        return const RatingResult.failure(
          'La pantalla ya no está disponible.',
        );
      }

      _setState(
        _state.copyWith(
          submitting: false,
          alreadyRated: true,
          clearError: true,
        ),
      );

      return const RatingResult.success(
        'Calificación enviada correctamente.',
      );
    } catch (error) {
      final message = _cleanError(error);

      if (!_disposed) {
        _setState(
          _state.copyWith(
            submitting: false,
            error: message,
          ),
        );
      }

      return RatingResult.failure(
        message,
      );
    } finally {
      _submitInProgress = false;

      if (!_disposed &&
          _state.submitting) {
        _setState(
          _state.copyWith(
            submitting: false,
          ),
        );
      }
    }
  }

  String _cleanError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty
        ? 'No se pudo enviar la calificación.'
        : message;
  }

  void _setState(
    RatingState newState,
  ) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}