class MapaHelperService {
  static double? extraerDouble(dynamic valor) {
    if (valor == null) return null;

    if (valor is num) return valor.toDouble();

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return double.tryParse(texto);
  }

  static String formatearCoordenadas({
    required double? latitud,
    required double? longitud,
  }) {
    if (latitud == null || longitud == null) {
      return 'Coordenadas no disponibles';
    }

    return '${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
  }

  static String formatearFecha(dynamic valor) {
    if (valor == null) return 'No disponible';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return valor.toString();

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  static bool estadoEsEnCurso(String? estado) {
    final e = estado?.replaceAll(' ', '').toLowerCase() ?? '';
    return e == 'encurso';
  }

  static bool estadoEsFinalizado(String? estado) {
    final e = estado?.replaceAll(' ', '').toLowerCase() ?? '';
    return e == 'finalizado';
  }

  static bool estadoEsCancelado(String? estado) {
    final e = estado?.replaceAll(' ', '').toLowerCase() ?? '';
    return e == 'cancelado';
  }
}