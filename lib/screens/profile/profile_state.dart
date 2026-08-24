enum ProfileRole { owner, walker, administrator, unknown }

class ProfileState {
  final bool loading;
  final String? error;
  final String? baseUrl;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? ownerProfile;
  final Map<String, dynamic>? walkerProfile;

  const ProfileState({
    this.loading = true,
    this.error,
    this.baseUrl,
    this.user = const {},
    this.ownerProfile,
    this.walkerProfile,
  });

  ProfileState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    String? baseUrl,
    Map<String, dynamic>? user,
    Map<String, dynamic>? ownerProfile,
    Map<String, dynamic>? walkerProfile,
    bool clearOwnerProfile = false,
    bool clearWalkerProfile = false,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      user: user ?? this.user,
      ownerProfile: clearOwnerProfile
          ? null
          : ownerProfile ?? this.ownerProfile,
      walkerProfile: clearWalkerProfile
          ? null
          : walkerProfile ?? this.walkerProfile,
    );
  }

  dynamic _value(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;

    for (final key in keys) {
      final value = source[key];

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _text(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  bool _safeBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    if (text == null || text.isEmpty || text == 'null') {
      return fallback;
    }

    return const {
      'true',
      '1',
      'si',
      'sí',
      'yes',
      'activo',
      'disponible',
    }.contains(text);
  }

  String get firstName {
    return _text(
      _value(user, const ['nombre']),
    );
  }

  String get lastName {
    return _text(
      _value(user, const ['apellido']),
    );
  }

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? 'Usuario DogGo' : value;
  }

  String get email {
    return _text(
      _value(user, const ['email']),
      fallback: 'Correo no disponible',
    );
  }

  String get phone {
    return _text(
      _value(user, const ['telefono']),
      fallback: 'No registrado',
    );
  }

  String get rawRole {
    return _text(
      _value(user, const ['rol']),
      fallback: 'Usuario',
    );
  }

  ProfileRole get role {
    final normalized = rawRole.toLowerCase().trim();

    if (normalized == 'paseador') {
      return ProfileRole.walker;
    }

    if (normalized == 'duenio') {
      return ProfileRole.owner;
    }

    if (normalized == 'admin' || normalized == 'superadmin') {
      return ProfileRole.administrator;
    }

    return ProfileRole.unknown;
  }

  bool get isOwner => role == ProfileRole.owner;

  bool get isWalker => role == ProfileRole.walker;

  bool get isAdministrator => role == ProfileRole.administrator;

  String get roleLabel {
    switch (role) {
      case ProfileRole.owner:
        return 'Dueño';
      case ProfileRole.walker:
        return 'Paseador';
      case ProfileRole.administrator:
        return 'Administrador';
      case ProfileRole.unknown:
        return rawRole;
    }
  }

  String? publicUrl(dynamic value) {
    final path = _text(value);

    if (path.isEmpty) return null;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final server = _text(baseUrl);

    if (server.isEmpty) return path;

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  String? get profilePhotoUrl {
    final walkerPhoto = _value(walkerProfile, const ['fotoUrl']);

    final ownerPhoto = _value(ownerProfile, const ['fotoUrl']);

    final userPhoto = _value(user, const ['fotoUrl']);

    return publicUrl(walkerPhoto ?? ownerPhoto ?? userPhoto);
  }

  String get ownerAddress {
    return _text(
      _value(ownerProfile, const ['direccion']),
    );
  }

  String get ownerZone {
    return _text(_value(ownerProfile, const ['zona']));
  }

  String get ownerReferences {
    return _text(
      _value(ownerProfile, const ['referenciasDireccion']),
    );
  }

  String get ownerDescription {
    return _text(
      _value(ownerProfile, const ['descripcion']),
    );
  }

  String get walkingPreferences {
    return _text(
      _value(ownerProfile, const ['preferenciasPaseo']),
    );
  }

  double? get ownerLatitude {
    return _safeDouble(
      _value(ownerProfile, const ['latitud']),
    );
  }

  double? get ownerLongitude {
    return _safeDouble(
      _value(ownerProfile, const ['longitud']),
    );
  }

  bool get hasOwnerLocation {
    return ownerLatitude != null && ownerLongitude != null;
  }

  String get walkerDescription {
    return _text(
      _value(walkerProfile, const ['descripcion']),
    );
  }

  String get walkerZone {
    return _text(
      _value(walkerProfile, const ['zonaServicio']),
    );
  }

  double? get walkerHourlyRate {
    return _safeDouble(
      _value(walkerProfile, const ['tarifaPorHora']),
    );
  }

  String get walkerRateLabel {
    final rate = walkerHourlyRate;

    if (rate == null) return 'Tarifa no registrada';

    return '\$${rate.toStringAsFixed(2)} / hora';
  }

  int? get walkerExperienceYears {
    final value = _value(walkerProfile, const ['experienciaAnios']);

    if (value is int) return value;
    if (value is double) return value.round();

    return int.tryParse(value?.toString() ?? '');
  }

  String get walkerExperienceLabel {
    final years = walkerExperienceYears;

    if (years == null) {
      return 'Experiencia no registrada';
    }

    if (years == 1) return '1 año';

    return '$years años';
  }

  bool get walkerAvailable {
    return _safeBool(
      _value(walkerProfile, const ['disponible']),
      fallback: true,
    );
  }

  bool get hasWalkerProfile => walkerProfile != null;

  bool get walkerProfileComplete {
    return profilePhotoUrl != null &&
        walkerDescription.isNotEmpty &&
        walkerZone.isNotEmpty &&
        walkerHourlyRate != null &&
        walkerExperienceYears != null;
  }

  int get walkerCompletionPercentage {
    var completed = 0;

    if (profilePhotoUrl != null) completed++;
    if (walkerDescription.isNotEmpty) completed++;
    if (walkerZone.isNotEmpty) completed++;
    if (walkerHourlyRate != null) completed++;
    if (walkerExperienceYears != null) completed++;

    return ((completed / 5) * 100).round();
  }

  bool get hasOwnerExtraInformation {
    return ownerAddress.isNotEmpty ||
        ownerZone.isNotEmpty ||
        ownerReferences.isNotEmpty ||
        ownerDescription.isNotEmpty ||
        walkingPreferences.isNotEmpty ||
        hasOwnerLocation;
  }
}
