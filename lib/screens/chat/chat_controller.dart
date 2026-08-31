import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/session_service.dart';
import 'chat_repository.dart';
import 'chat_state.dart';
import 'models/chat_message.dart';

class ChatSendResult {
  final bool success;
  final String message;

  const ChatSendResult({required this.success, required this.message});

  const ChatSendResult.success([this.message = 'Mensaje enviado.'])
    : success = true;

  const ChatSendResult.failure(this.message) : success = false;
}

class ChatController extends ChangeNotifier {
  static const int maximumMessageLength = 1000;

  final int walkId;
  final ChatRepository _repository;

  ChatState _state = const ChatState();

  Timer? _timer;
  bool _disposed = false;
  bool _loadInProgress = false;
  bool _sendInProgress = false;

  ChatController({required this.walkId, ChatRepository? repository})
    : _repository = repository ?? ChatRepository();

  ChatState get state => _state;

  Future<void> initialize() async {
    try {
      final userId = await SessionService.obtenerUsuarioId();

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          currentUserId: userId,
          clearCurrentUserId: userId == null,
        ),
      );
    } catch (_) {
      // Los mensajes también pueden identificarse
      // por el nombre cuando no existe un ID local.
    }

    await loadMessages();

    if (_disposed) {
      return;
    }

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_disposed && !_state.sending) {
        loadMessages(silent: true);
      }
    });
  }

  Future<void> refresh() {
    return loadMessages();
  }

  Future<void> loadMessages({bool silent = false}) async {
    if (_loadInProgress || _disposed) {
      return;
    }

    _loadInProgress = true;

    if (silent) {
      _setState(_state.copyWith(refreshing: true, clearBackgroundError: true));
    } else {
      _setState(
        _state.copyWith(
          loading: _state.messages.isEmpty,
          refreshing: _state.messages.isNotEmpty,
          clearError: true,
          clearBackgroundError: true,
        ),
      );
    }

    try {
      final messages = await _repository.getMessages(walkId);

      if (_disposed) {
        return;
      }

      final changed = _messagesChanged(_state.messages, messages);

      _setState(
        _state.copyWith(
          loading: false,
          refreshing: false,
          messages: messages,
          revision: changed ? _state.revision + 1 : _state.revision,
          clearError: true,
          clearBackgroundError: true,
        ),
      );

      try {
        await _repository.markAsRead(walkId);
      } catch (_) {
        // Leer mensajes no debe fallar si el
        // endpoint de confirmación aún no existe.
      }
    } catch (error) {
      if (_disposed) {
        return;
      }

      if (silent || _state.messages.isNotEmpty) {
        _setState(
          _state.copyWith(
            loading: false,
            refreshing: false,
            backgroundError: _cleanError(error),
          ),
        );
      } else {
        _setState(
          _state.copyWith(
            loading: false,
            refreshing: false,
            error: _cleanError(error),
          ),
        );
      }
    } finally {
      _loadInProgress = false;
    }
  }

  Future<ChatSendResult> send(
    String content, {
    String type = 'Texto',
    String? metadataJson,
    int? replyToId,
  }) async {
    if (_sendInProgress) {
      return const ChatSendResult.failure('El mensaje ya se está enviando.');
    }

    final text = content.trim();

    if (text.isEmpty) {
      return const ChatSendResult.failure(
        'Escribe un mensaje antes de enviarlo.',
      );
    }

    if (text.length > maximumMessageLength) {
      return const ChatSendResult.failure('El mensaje es demasiado largo.');
    }

    _sendInProgress = true;

    _setState(_state.copyWith(sending: true, clearBackgroundError: true));

    try {
      await _repository.send(
        walkId: walkId,
        content: text,
        type: type,
        metadataJson: metadataJson,
        replyToId: replyToId,
      );

      await loadMessages(silent: true);

      return const ChatSendResult.success();
    } catch (error) {
      return ChatSendResult.failure(_cleanError(error));
    } finally {
      _sendInProgress = false;

      _setState(_state.copyWith(sending: false));
    }
  }

  Future<ChatSendResult> sendImage(String path) async {
    if (_sendInProgress) {
      return const ChatSendResult.failure('El archivo ya se está enviando.');
    }
    _sendInProgress = true;
    _setState(_state.copyWith(sending: true, clearBackgroundError: true));
    try {
      await _repository.sendImage(walkId: walkId, path: path);
      await loadMessages(silent: true);
      return const ChatSendResult.success('Fotografía enviada.');
    } catch (error) {
      return ChatSendResult.failure(_cleanError(error));
    } finally {
      _sendInProgress = false;
      _setState(_state.copyWith(sending: false));
    }
  }

  bool _messagesChanged(List<ChatMessage> previous, List<ChatMessage> next) {
    if (previous.length != next.length) {
      return true;
    }

    for (var index = 0; index < previous.length; index++) {
      if (previous[index].stableKey != next[index].stableKey) {
        return true;
      }

      if (previous[index].read != next[index].read) {
        return true;
      }
    }

    return false;
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

    return message.isEmpty ? 'No se pudo actualizar el chat.' : message;
  }

  void _setState(ChatState newState) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
