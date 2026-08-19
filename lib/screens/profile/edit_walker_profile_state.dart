import 'dart:io';

import '../location/models/mexico_location.dart';

class EditWalkerProfileState {
  final bool loading;
  final bool saving;
  final bool available;
  final String? error;
  final String? baseUrl;
  final String? currentPhotoUrl;
  final File? selectedPhoto;
  final bool profileLoaded;
  final List<MexicoState> states;
  final List<MexicoMunicipality> municipalities;
  final String? selectedStateCode;
  final String? selectedMunicipalityCode;
  final int serviceRadiusKm;
  final bool loadingMunicipalities;
  final double? latitude;
  final double? longitude;
  final bool locatingCoverage;

  const EditWalkerProfileState({
    this.loading = true,
    this.saving = false,
    this.available = true,
    this.error,
    this.baseUrl,
    this.currentPhotoUrl,
    this.selectedPhoto,
    this.profileLoaded = false,
    this.states = const [],
    this.municipalities = const [],
    this.selectedStateCode,
    this.selectedMunicipalityCode,
    this.serviceRadiusKm = 10,
    this.loadingMunicipalities = false,
    this.latitude,
    this.longitude,
    this.locatingCoverage = false,
  });

  bool get hasPhoto {
    return selectedPhoto != null ||
        (currentPhotoUrl != null && currentPhotoUrl!.trim().isNotEmpty);
  }

  EditWalkerProfileState copyWith({
    bool? loading,
    bool? saving,
    bool? available,
    String? error,
    bool clearError = false,
    String? baseUrl,
    String? currentPhotoUrl,
    bool clearCurrentPhoto = false,
    File? selectedPhoto,
    bool clearSelectedPhoto = false,
    bool? profileLoaded,
    List<MexicoState>? states,
    List<MexicoMunicipality>? municipalities,
    String? selectedStateCode,
    bool clearSelectedState = false,
    String? selectedMunicipalityCode,
    bool clearSelectedMunicipality = false,
    int? serviceRadiusKm,
    bool? loadingMunicipalities,
    double? latitude,
    bool clearLatitude = false,
    double? longitude,
    bool clearLongitude = false,
    bool? locatingCoverage,
  }) {
    return EditWalkerProfileState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      available: available ?? this.available,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      currentPhotoUrl: clearCurrentPhoto
          ? null
          : currentPhotoUrl ?? this.currentPhotoUrl,
      selectedPhoto: clearSelectedPhoto
          ? null
          : selectedPhoto ?? this.selectedPhoto,
      profileLoaded: profileLoaded ?? this.profileLoaded,
      states: states ?? this.states,
      municipalities: municipalities ?? this.municipalities,
      selectedStateCode: clearSelectedState
          ? null
          : selectedStateCode ?? this.selectedStateCode,
      selectedMunicipalityCode: clearSelectedMunicipality
          ? null
          : selectedMunicipalityCode ?? this.selectedMunicipalityCode,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      loadingMunicipalities:
          loadingMunicipalities ?? this.loadingMunicipalities,
      latitude: clearLatitude ? null : latitude ?? this.latitude,
      longitude: clearLongitude ? null : longitude ?? this.longitude,
      locatingCoverage: locatingCoverage ?? this.locatingCoverage,
    );
  }

  String? publicUrl(dynamic value) {
    final path = value?.toString().trim();

    if (path == null || path.isEmpty || path.toLowerCase() == 'null') {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final server = baseUrl?.trim() ?? '';

    if (server.isEmpty) return path;

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  static bool safeBool(dynamic value, {bool fallback = true}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    if (text == null || text.isEmpty || text == 'null') {
      return fallback;
    }

    if (const {
      'false',
      '0',
      'no',
      'inactivo',
      'no disponible',
    }.contains(text)) {
      return false;
    }

    if (const {
      'true',
      '1',
      'sí',
      'si',
      'activo',
      'disponible',
    }.contains(text)) {
      return true;
    }

    return fallback;
  }

  static String decimalText(dynamic value) {
    if (value == null) return '';

    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().replaceAll(',', '.'));

    if (number == null || number <= 0) return '';

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  static String integerText(dynamic value) {
    if (value == null) return '';

    final number = value is int ? value : int.tryParse(value.toString());

    if (number == null || number < 0) return '';

    return number.toString();
  }
}
