enum EvidenceType {
  start,
  end,
}

extension EvidenceTypeData on EvidenceType {
  String get apiValue {
    switch (this) {
      case EvidenceType.start:
        return 'inicio';
      case EvidenceType.end:
        return 'fin';
    }
  }

  String get title {
    switch (this) {
      case EvidenceType.start:
        return 'Evidencia inicial';
      case EvidenceType.end:
        return 'Evidencia final';
    }
  }

  String get shortTitle {
    switch (this) {
      case EvidenceType.start:
        return 'Foto de inicio';
      case EvidenceType.end:
        return 'Foto de fin';
    }
  }

  String get description {
    switch (this) {
      case EvidenceType.start:
        return 'Registra cómo recibiste a la mascota antes de comenzar el recorrido.';
      case EvidenceType.end:
        return 'Registra la entrega de la mascota al terminar el servicio.';
    }
  }

  String get confirmationMessage {
    switch (this) {
      case EvidenceType.start:
        return 'La fotografía confirmará la recepción de la mascota.';
      case EvidenceType.end:
        return 'La fotografía confirmará que la mascota fue entregada correctamente.';
    }
  }

  List<String> get instructions {
    switch (this) {
      case EvidenceType.start:
        return const [
          'La mascota debe verse claramente.',
          'Procura mostrar el collar o arnés.',
          'Evita imágenes oscuras o borrosas.',
        ];

      case EvidenceType.end:
        return const [
          'La mascota debe verse claramente.',
          'Toma la fotografía en el punto de entrega.',
          'Evita incluir información privada innecesaria.',
        ];
    }
  }

  static EvidenceType fromValue(
    String value,
  ) {
    final normalized =
        value.trim().toLowerCase();

    if (normalized == 'inicio' ||
        normalized == 'start' ||
        normalized == 'inicial') {
      return EvidenceType.start;
    }

    return EvidenceType.end;
  }
}