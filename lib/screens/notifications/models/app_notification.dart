enum AppNotificationCategory {
  walk,
  request,
  message,
  cancelled,
  profile,
  rating,
  evidence,
  general,
}

enum AppNotificationGroup { today, yesterday, earlier }

class AppNotification {
  final int? id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;
  final bool isRead;
  final int? referenceId;
  final String dogName;
  final String otherUserName;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.referenceId,
    required this.dogName,
    required this.otherUserName,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _readInt(json, const ['id']),
      title: _readText(json, const ['titulo'], fallback: 'Notificación'),
      message: _readText(
        json,
        const ['mensaje'],
        fallback: 'Tienes una actualización nueva.',
      ),
      type: _readText(json, const ['tipo'], fallback: 'General'),
      createdAt: _readDate(json, const ['fechaCreacion']),
      isRead: _readBool(json, const ['leida']),
      referenceId: _readInt(json, const ['referenciaId']),
      dogName: 'Paseo DogGo',
      otherUserName: 'Usuario DogGo',
    );
  }

  AppNotificationCategory get category {
    final value = type.toLowerCase();

    if (value.contains('cancel') || value.contains('rechaz')) {
      return AppNotificationCategory.cancelled;
    }

    if (value.contains('chat') || value.contains('mensaje')) {
      return AppNotificationCategory.message;
    }

    if (value.contains('solicitud')) {
      return AppNotificationCategory.request;
    }

    if (value.contains('evidencia') || value.contains('foto')) {
      return AppNotificationCategory.evidence;
    }

    if (value.contains('calificacion') ||
        value.contains('calificación') ||
        value.contains('reseña') ||
        value.contains('resena')) {
      return AppNotificationCategory.rating;
    }

    if (value.contains('perfil') || value.contains('cuenta')) {
      return AppNotificationCategory.profile;
    }

    if (value.contains('paseo') ||
        value.contains('aceptado') ||
        value.contains('iniciado') ||
        value.contains('finalizado')) {
      return AppNotificationCategory.walk;
    }

    return AppNotificationCategory.general;
  }

  AppNotificationGroup get group {
    final date = createdAt;

    if (date == null) {
      return AppNotificationGroup.earlier;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(notificationDay).inDays;

    if (difference <= 0) {
      return AppNotificationGroup.today;
    }

    if (difference == 1) {
      return AppNotificationGroup.yesterday;
    }

    return AppNotificationGroup.earlier;
  }

  bool get opensChat {
    return category == AppNotificationCategory.message &&
        referenceId != null &&
        referenceId! > 0;
  }

  bool get opensRouteMap {
    final normalizedType = type.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    return normalizedType == 'rutapaseo' &&
        referenceId != null &&
        referenceId! > 0;
  }

  bool get opensWalks {
    return category == AppNotificationCategory.walk ||
        category == AppNotificationCategory.request ||
        category == AppNotificationCategory.cancelled ||
        category == AppNotificationCategory.evidence ||
        category == AppNotificationCategory.rating;
  }

  bool get opensProgram {
    final normalized = type.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return normalized == 'programacion' &&
        referenceId != null &&
        referenceId! > 0;
  }

  String get formattedDate {
    final date = createdAt;

    if (date == null) {
      return '';
    }

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    final now = DateTime.now();
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    if (isToday) {
      return '${twoDigits(date.hour)}:'
          '${twoDigits(date.minute)}';
    }

    return '${twoDigits(date.day)}/'
        '${twoDigits(date.month)}/'
        '${date.year}';
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    int? referenceId,
    String? dogName,
    String? otherUserName,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      referenceId: referenceId ?? this.referenceId,
      dogName: dogName ?? this.dogName,
      otherUserName: otherUserName ?? this.otherUserName,
    );
  }

  static String _readText(
    Map<String, dynamic> json,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return fallback;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      final parsed = int.tryParse(value?.toString() ?? '');

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value is bool) {
        return value;
      }

      if (value is num) {
        return value != 0;
      }

      final text = value?.toString().trim().toLowerCase();

      if (text == 'true' || text == '1' || text == 'si' || text == 'sí') {
        return true;
      }
    }

    return false;
  }

  static DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value == null) {
        continue;
      }

      if (value is DateTime) {
        return value.toLocal();
      }

      if (value is int) {
        final milliseconds = value < 1000000000000 ? value * 1000 : value;

        return DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
          isUtc: true,
        ).toLocal();
      }

      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return null;
  }
}
