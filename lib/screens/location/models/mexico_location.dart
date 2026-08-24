class MexicoState {
  final String code;
  final String name;

  const MexicoState({required this.code, required this.name});

  factory MexicoState.fromMap(Map<String, dynamic> map) => MexicoState(
    code: (map['clave'] ?? '').toString(),
    name: (map['nombre'] ?? '').toString(),
  );
}

class MexicoMunicipality {
  final String code;
  final String stateCode;
  final String localCode;
  final String name;

  const MexicoMunicipality({
    required this.code,
    required this.stateCode,
    required this.localCode,
    required this.name,
  });

  factory MexicoMunicipality.fromMap(Map<String, dynamic> map) =>
      MexicoMunicipality(
        code: (map['claveGeoestadistica'] ?? '').toString(),
        stateCode: (map['estadoClave'] ?? '').toString(),
        localCode: (map['clave'] ?? '').toString(),
        name: (map['nombre'] ?? '').toString(),
      );
}
