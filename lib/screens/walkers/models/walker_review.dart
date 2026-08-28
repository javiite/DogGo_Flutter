class WalkerReview {
  final int? id;
  final String authorName;
  final String comment;
  final double rating;
  final DateTime? createdAt;
  final String? authorPhotoPath;
  final Map<String, dynamic> rawData;

  const WalkerReview({
    this.id,
    required this.authorName,
    required this.comment,
    required this.rating,
    this.createdAt,
    this.authorPhotoPath,
    this.rawData = const {},
  });

  factory WalkerReview.fromMap(Map<String, dynamic> map) {
    return WalkerReview(
      id: _integer(map['id']),
      authorName: _text(map['duenioNombreCompleto'], fallback: 'Dueño DogGo'),
      comment: _text(map['comentario'], fallback: 'Sin comentario escrito.'),
      rating: _decimal(map['puntaje']) ?? 0,
      createdAt: _dateTime(map['fecha']),
      authorPhotoPath: _nullableText(map['duenioFotoUrl']),
      rawData: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(map),
      ),
    );
  }

  String get ratingLabel {
    if (rating <= 0) {
      return 'Sin calificación';
    }

    return rating.toStringAsFixed(1);
  }

  String get dateLabel {
    final date = createdAt;

    if (date == null) {
      return '';
    }

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get authorInitials {
    final words = authorName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'DG';
    }

    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words.first.substring(0, 1)}'
            '${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  String? publicPhotoUrl(String? baseUrl) {
    final path = authorPhotoPath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = baseUrl?.trim();
    if (base == null || base.isEmpty) return null;
    return '${base.replaceFirst(RegExp(r'/+$'), '')}/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static List<WalkerReview> listFrom(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => WalkerReview.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
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

  static double? _decimal(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }
}
