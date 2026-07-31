import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'models/walker.dart';
import 'models/walker_review.dart';
import 'walker_detail_state.dart';

class WalkerDetailController extends ChangeNotifier {
  WalkerDetailState _state;

  bool _disposed = false;
  bool _reviewsRequestInProgress = false;

  WalkerDetailController({
    required Map<String, dynamic> walkerData,
  }) : _state = WalkerDetailState(
          walker: Walker.fromMap(walkerData),
        );

  WalkerDetailState get state => _state;

  Future<void> initialize() async {
    await _loadBaseUrl();

    if (_disposed) {
      return;
    }

    await loadReviews();
  }

  Future<void> refresh() {
    return loadReviews();
  }

  Future<void> _loadBaseUrl() async {
    try {
      final baseUrl =
          await StorageService.obtenerBaseUrl();

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          baseUrl: baseUrl,
        ),
      );
    } catch (_) {
      // El perfil puede mostrarse aunque no se consiga
      // recuperar la URL del servidor.
    }
  }

  Future<void> loadReviews() async {
    if (_reviewsRequestInProgress) {
      return;
    }

    if (!_state.walker.hasValidId) {
      _setState(
        _state.copyWith(
          loadingReviews: false,
          reviews: const [],
          clearReviewsError: true,
        ),
      );
      return;
    }

    _reviewsRequestInProgress = true;

    _setState(
      _state.copyWith(
        loadingReviews: true,
        clearReviewsError: true,
      ),
    );

    Object? lastError;

    for (final endpoint in _reviewEndpoints) {
      try {
        final response =
            await ApiService.getAuth(endpoint);

        if (_disposed) {
          return;
        }

        if (!_isSuccessful(response)) {
          lastError = Exception(
            _responseMessage(
              response,
              fallback:
                  'No se pudieron cargar las reseñas.',
            ),
          );
          continue;
        }

        final reviews = WalkerReview.listFrom(
          _extractList(response),
        );

        _setState(
          _state.copyWith(
            loadingReviews: false,
            reviews: reviews,
            clearReviewsError: true,
          ),
        );

        return;
      } catch (error) {
        lastError = error;
      }
    }

    if (_disposed) {
      return;
    }

    _setState(
      _state.copyWith(
        loadingReviews: false,
        reviewsError: _cleanError(lastError),
      ),
    );

    _reviewsRequestInProgress = false;
  }

  List<String> get _reviewEndpoints {
    final id = _state.walker.id;

    return [
      '/api/paseadores/$id/calificaciones',
      '/api/Paseadores/$id/calificaciones',
      '/api/calificaciones/paseador/$id',
      '/api/Calificaciones/paseador/$id',
      '/api/paseadores/$id/reviews',
      '/api/Paseadores/$id/reviews',
    ];
  }

  bool _isSuccessful(
    Map<String, dynamic> response,
  ) {
    final statusCode = response['statusCode'];

    if (statusCode is int) {
      return statusCode >= 200 && statusCode < 300;
    }

    if (response['success'] is bool) {
      return response['success'] == true;
    }

    return true;
  }

  dynamic _extractList(
    Map<String, dynamic> response,
  ) {
    dynamic data = response['body'] ?? response;

    if (data is Map) {
      data = data['data'] ??
          data['calificaciones'] ??
          data['reviews'] ??
          data['resenas'] ??
          data['reseñas'] ??
          data['items'] ??
          data['resultado'] ??
          data['result'] ??
          data['value'];
    }

    if (data is Map) {
      data = data['data'] ??
          data['calificaciones'] ??
          data['reviews'] ??
          data['resenas'] ??
          data['reseñas'] ??
          data['items'] ??
          data['value'];
    }

    return data is List ? data : const [];
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    dynamic source =
        response['body'] ?? response;

    if (source is Map) {
      final value = source['message'] ??
          source['mensaje'] ??
          source['error'];

      final message = value?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final value = response['message'] ??
        response['mensaje'] ??
        response['error'];

    final message = value?.toString().trim();

    return message == null || message.isEmpty
        ? fallback
        : message;
  }

  String _cleanError(Object? error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        ?.toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    if (message == null || message.isEmpty) {
      return 'No pudimos cargar las reseñas.';
    }

    return message;
  }

  void _setState(
    WalkerDetailState newState,
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