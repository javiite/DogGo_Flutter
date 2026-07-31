enum RatingOption {
  veryBad,
  bad,
  regular,
  good,
  excellent,
}

extension RatingOptionData on RatingOption {
  int get score {
    switch (this) {
      case RatingOption.veryBad:
        return 1;
      case RatingOption.bad:
        return 2;
      case RatingOption.regular:
        return 3;
      case RatingOption.good:
        return 4;
      case RatingOption.excellent:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case RatingOption.veryBad:
        return 'Muy mala';
      case RatingOption.bad:
        return 'Mala';
      case RatingOption.regular:
        return 'Regular';
      case RatingOption.good:
        return 'Buena';
      case RatingOption.excellent:
        return 'Excelente';
    }
  }

  String get question {
    switch (this) {
      case RatingOption.veryBad:
        return '¿Qué salió mal durante el servicio?';
      case RatingOption.bad:
        return '¿Qué podría mejorar el paseador?';
      case RatingOption.regular:
        return 'Cuéntanos qué estuvo bien y qué podría mejorar.';
      case RatingOption.good:
        return '¿Qué fue lo que más te gustó?';
      case RatingOption.excellent:
        return 'Cuéntanos por qué recomendarías este servicio.';
    }
  }

  String get summary {
    switch (this) {
      case RatingOption.veryBad:
        return 'La experiencia no cumplió tus expectativas.';
      case RatingOption.bad:
        return 'La experiencia necesita varias mejoras.';
      case RatingOption.regular:
        return 'La experiencia fue aceptable.';
      case RatingOption.good:
        return 'Tuviste una buena experiencia.';
      case RatingOption.excellent:
        return 'Tuviste una experiencia excelente.';
    }
  }

  static RatingOption fromScore(int value) {
    switch (value) {
      case 1:
        return RatingOption.veryBad;
      case 2:
        return RatingOption.bad;
      case 3:
        return RatingOption.regular;
      case 4:
        return RatingOption.good;
      default:
        return RatingOption.excellent;
    }
  }
}