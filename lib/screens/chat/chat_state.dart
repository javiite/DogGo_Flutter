import 'models/chat_message.dart';

class ChatState {
  final bool loading;
  final bool refreshing;
  final bool sending;
  final String? error;
  final String? backgroundError;
  final int? currentUserId;
  final List<ChatMessage> messages;
  final int revision;

  const ChatState({
    this.loading = true,
    this.refreshing = false,
    this.sending = false,
    this.error,
    this.backgroundError,
    this.currentUserId,
    this.messages = const [],
    this.revision = 0,
  });

  bool get isEmpty {
    return !loading && messages.isEmpty;
  }

  bool get hasMessages {
    return messages.isNotEmpty;
  }

  int get messageCount {
    return messages.length;
  }

  int get unreadIncomingCount {
    return messages.where((message) {
      return !message.read &&
          !message.belongsTo(currentUserId);
    }).length;
  }

  bool isMine(ChatMessage message) {
    return message.belongsTo(currentUserId);
  }

  bool shouldShowDateSeparator(
    int index,
  ) {
    if (index < 0 ||
        index >= messages.length) {
      return false;
    }

    if (index == 0) {
      return true;
    }

    return !messages[index].occursOnSameDay(
      messages[index - 1],
    );
  }

  ChatState copyWith({
    bool? loading,
    bool? refreshing,
    bool? sending,
    String? error,
    bool clearError = false,
    String? backgroundError,
    bool clearBackgroundError = false,
    int? currentUserId,
    bool clearCurrentUserId = false,
    List<ChatMessage>? messages,
    int? revision,
  }) {
    return ChatState(
      loading: loading ?? this.loading,
      refreshing:
          refreshing ?? this.refreshing,
      sending: sending ?? this.sending,
      error:
          clearError ? null : error ?? this.error,
      backgroundError: clearBackgroundError
          ? null
          : backgroundError ??
              this.backgroundError,
      currentUserId: clearCurrentUserId
          ? null
          : currentUserId ??
              this.currentUserId,
      messages: messages ?? this.messages,
      revision: revision ?? this.revision,
    );
  }
}