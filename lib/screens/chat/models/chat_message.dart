class ChatMessage {
  final int? id;
  final int? senderId;
  final String senderName;
  final String content;
  final String type;
  final String? mediaUrl;
  final String? metadataJson;
  final int? replyToId;
  final DateTime? sentAt;
  final bool read;
  final bool systemMessage;
  final Map<String, dynamic> rawData;

  const ChatMessage({
    this.id,
    this.senderId,
    required this.senderName,
    required this.content,
    this.type = 'Texto',
    this.mediaUrl,
    this.metadataJson,
    this.replyToId,
    this.sentAt,
    this.read = false,
    this.systemMessage = false,
    this.rawData = const {},
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: _integer(map['id']),
      senderId: _integer(map['emisorId']),
      senderName: _text(map['emisorNombreCompleto'], fallback: 'Usuario'),
      content: _text(map['contenido']),
      type: _text(map['tipo'], fallback: 'Texto'),
      mediaUrl: _nullableText(map['mediaUrl']),
      metadataJson: _nullableText(map['metadatosJson']),
      replyToId: _integer(map['respuestaAId']),
      sentAt: _dateTime(map['fechaEnvio']),
      read: _boolean(map['leido']),
      systemMessage:
          _text(map['tipo']).toLowerCase() == 'sistema' ||
          _boolean(map['mensajeSistema']),
      rawData: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(map),
      ),
    );
  }

  String get timeLabel {
    final date = sentAt?.toLocal();

    if (date == null) {
      return '';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String get fullDateLabel {
    final date = sentAt?.toLocal();

    if (date == null) {
      return '';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  String get dayLabel {
    final date = sentAt?.toLocal();

    if (date == null) {
      return 'Chat del paseo';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return 'Hoy';
    }

    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  bool occursOnSameDay(ChatMessage other) {
    final first = sentAt?.toLocal();
    final second = other.sentAt?.toLocal();

    if (first == null || second == null) {
      return false;
    }

    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool belongsTo(int? currentUserId) {
    if (currentUserId != null && senderId != null) {
      return senderId == currentUserId;
    }

    final normalized = senderName.trim().toLowerCase();

    return normalized == 'yo' || normalized == 'tú' || normalized == 'tu';
  }

  String get stableKey {
    if (id != null) {
      return 'id:$id';
    }

    return '${senderId ?? senderName}|'
        '${sentAt?.toIso8601String() ?? ''}|'
        '$content|${mediaUrl ?? ''}|$type';
  }

  bool get isImage => type.toLowerCase() == 'imagen' && mediaUrl != null;

  bool get isQuick => type.toLowerCase() == 'rapido';

  bool get isLocation => type.toLowerCase() == 'ubicacion';

  static List<ChatMessage> listFrom(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final messages = value
        .whereType<Map>()
        .map((item) => ChatMessage.fromMap(Map<String, dynamic>.from(item)))
        .where(
          (message) =>
              message.content.trim().isNotEmpty || message.mediaUrl != null,
        )
        .toList();

    messages.sort((first, second) {
      final firstDate = first.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondDate =
          second.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return firstDate.compareTo(secondDate);
    });

    return List<ChatMessage>.unmodifiable(messages);
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  static int? _integer(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().trim());
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }

  static bool _boolean(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();

    return const {'true', '1', 'sí', 'si', 'yes'}.contains(text);
  }
}
