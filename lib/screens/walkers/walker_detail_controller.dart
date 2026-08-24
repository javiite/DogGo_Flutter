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

  WalkerDetailController({required Map<String, dynamic> walkerData})
    : _state = WalkerDetailState(walker: Walker.fromMap(walkerData));

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
      final baseUrl = await StorageService.obtenerBaseUrl();

      if (_disposed) {
        return;
      }

      _setState(_state.copyWith(baseUrl: baseUrl));
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

    _setState(_state.copyWith(loadingReviews: true, clearReviewsError: true));

    try {
      final response = await ApiService.getAuth(
        '/api/paseadores/${_state.walker.id}/resenas',
      );

      if (_disposed) {
        return;
      }

      if (!_isSuccessful(response)) {
        throw Exception(
          _responseMessage(
            response,
            fallback: 'No se pudieron cargar las reseñas.',
          ),
        );
      }

      final reviews = WalkerReview.listFrom(_extractList(response));

      _setState(
        _state.copyWith(
          loadingReviews: false,
          reviews: reviews,
          clearReviewsError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loadingReviews: false,
          reviewsError: _cleanError(error),
        ),
      );
    } finally {
      _reviewsRequestInProgress = false;
    }
  }

  bool _isSuccessful(Map<String, dynamic> response) {
    final statusCode = response['statusCode'];

    if (statusCode is int) {
      return statusCode >= 200 && statusCode < 300;
    }

    if (response['success'] is bool) {
      return response['success'] == true;
    }

    return true;
  }

  dynamic _extractList(Map<String, dynamic> response) {
    dynamic data = response['body'] ?? response;

    if (data is Map) {
      data = data['data'];
    }

    if (data is Map) {
      data = data['resenas'];
    }

    return data is List ? data : const [];
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    dynamic source = response['body'] ?? response;

    if (source is Map) {
      final value = source['message'];

      final message = value?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final value = response['message'];

    final message = value?.toString().trim();

    return message == null || message.isEmpty ? fallback : message;
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

  void _setState(WalkerDetailState newState) {
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
