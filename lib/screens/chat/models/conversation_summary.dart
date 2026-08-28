class ConversationSummary {
  final int walkId;
  final int? programId;
  final String walkStatus;
  final bool isActive;
  final DateTime? scheduledAt;
  final String pets;
  final String otherPerson;
  final String? otherPersonPhotoUrl;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastActivityAt;
  final int unreadCount;
  final bool hasMessages;

  const ConversationSummary({
    required this.walkId,
    required this.programId,
    required this.walkStatus,
    required this.isActive,
    required this.scheduledAt,
    required this.pets,
    required this.otherPerson,
    required this.otherPersonPhotoUrl,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastActivityAt,
    required this.unreadCount,
    required this.hasMessages,
  });

  factory ConversationSummary.fromJson(
    Map<String, dynamic> json, {
    String? baseUrl,
  }) {
    final walkId = _asInt(json['paseoId']);
    final status = json['estadoPaseo']?.toString().trim() ?? '';

    return ConversationSummary(
      walkId: walkId,
      programId: _asNullableInt(json['programacionId']),
      walkStatus: status.isEmpty ? 'Pendiente' : status,
      isActive: json['esActiva'] == true,
      scheduledAt: _asDateTime(json['fechaProgramada']),
      pets: _nonEmpty(json['mascotas'], 'Paseo DogGo'),
      otherPerson: _nonEmpty(json['otraPersona'], 'Usuario DogGo'),
      otherPersonPhotoUrl: _resolveUrl(
        json['otraPersonaFotoUrl']?.toString(),
        baseUrl,
      ),
      lastMessage: _nullableText(json['ultimoMensaje']),
      lastMessageType: _nullableText(json['ultimoMensajeTipo']),
      lastActivityAt: _asDateTime(json['ultimaActividadUtc']),
      unreadCount: _asInt(json['noLeidos']),
      hasMessages: json['tieneMensajes'] == true,
    );
  }

  String get preview {
    if (!hasMessages) return 'Inicia la conversación sobre este paseo.';
    if (lastMessageType?.toLowerCase() == 'imagen') {
      return 'Fotografía compartida';
    }
    return lastMessage ?? 'Tienes actividad en este paseo.';
  }

  String get initials {
    final words = otherPerson
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return 'DG';
    return words.map((word) => word[0].toUpperCase()).join();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal();
  }

  static String _nonEmpty(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _resolveUrl(String? value, String? baseUrl) {
    final path = value?.trim() ?? '';
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = baseUrl?.trim().replaceFirst(RegExp(r'/+$'), '') ?? '';
    if (base.isEmpty) return null;
    return path.startsWith('/') ? '$base$path' : '$base/$path';
  }
}
