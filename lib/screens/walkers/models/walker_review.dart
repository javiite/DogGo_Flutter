class WalkerReview {
  final int? id;
  final String authorName;
  final String comment;
  final double rating;
  final DateTime? createdAt;
  final Map<String, dynamic> rawData;

  const WalkerReview({
    this.id,
    required this.authorName,
    required this.comment,
    required this.rating,
    this.createdAt,
    this.rawData = const {},
  });

  factory WalkerReview.fromMap(
    Map<String, dynamic> map,
  ) {
    final owner = _safeMap(
      _firstValue(
        map,
        const [
          'duenio',
          'Dueño',
          'dueno',
          'Dueno',
          'usuario',
          'Usuario',
          'cliente',
          'Cliente',
        ],
      ),
    );

    final authorValue = _firstValue(
          map,
          const [
            'duenioNombre',
            'DueñoNombre',
            'duenoNombre',
            'DuenoNombre',
            'clienteNombre',
            'ClienteNombre',
            'autor',
            'Autor',
            'authorName',
            'AuthorName',
          ],
        ) ??
        _firstValue(
          owner,
          const [
            'nombreCompleto',
            'NombreCompleto',
            'nombre',
            'Nombre',
            'name',
            'Name',
          ],
        );

    return WalkerReview(
      id: _integer(
        _firstValue(
          map,
          const [
            'id',
            'Id',
            'calificacionId',
            'CalificacionId',
            'reviewId',
            'ReviewId',
          ],
        ),
      ),
      authorName: _text(
        authorValue,
        fallback: 'Dueño DogGo',
      ),
      comment: _text(
        _firstValue(
          map,
          const [
            'comentario',
            'Comentario',
            'resena',
            'Resena',
            'reseña',
            'Reseña',
            'mensaje',
            'Mensaje',
            'comment',
            'Comment',
          ],
        ),
        fallback: 'Sin comentario escrito.',
      ),
      rating: _decimal(
            _firstValue(
              map,
              const [
                'puntaje',
                'Puntaje',
                'rating',
                'Rating',
                'calificacion',
                'Calificacion',
                'calificación',
                'Calificación',
              ],
            ),
          ) ??
          0,
      createdAt: _dateTime(
        _firstValue(
          map,
          const [
            'fecha',
            'Fecha',
            'fechaCreacion',
            'FechaCreacion',
            'createdAt',
            'CreatedAt',
          ],
        ),
      ),
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
      return words.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${words.first.substring(0, 1)}'
            '${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  static List<WalkerReview> listFrom(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => WalkerReview.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  static dynamic _firstValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static Map<String, dynamic> _safeMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }

  static String _text(
    dynamic value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
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

    return int.tryParse(
      value.toString().trim(),
    );
  }

  static double? _decimal(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value
          .toString()
          .trim()
          .replaceAll(',', '.'),
    );
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value?.toString() ?? '',
    );
  }
}