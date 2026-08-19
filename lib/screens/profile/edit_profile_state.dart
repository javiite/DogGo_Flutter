import 'dart:io';

import '../location/models/mexico_location.dart';

class EditProfileState {
  final bool loading;
  final bool saving;
  final String? error;
  final String? baseUrl;
  final String? currentPhotoUrl;
  final File? selectedPhoto;
  final double? latitude;
  final double? longitude;
  final bool ownerProfileLoaded;
  final List<MexicoState> states;
  final List<MexicoMunicipality> municipalities;
  final String? selectedStateCode;
  final String? selectedMunicipalityCode;
  final bool loadingMunicipalities;

  const EditProfileState({
    this.loading = false,
    this.saving = false,
    this.error,
    this.baseUrl,
    this.currentPhotoUrl,
    this.selectedPhoto,
    this.latitude,
    this.longitude,
    this.ownerProfileLoaded = false,
    this.states = const [],
    this.municipalities = const [],
    this.selectedStateCode,
    this.selectedMunicipalityCode,
    this.loadingMunicipalities = false,
  });

  bool get hasLocation {
    return latitude != null &&
        longitude != null &&
        latitude! >= -90 &&
        latitude! <= 90 &&
        longitude! >= -180 &&
        longitude! <= 180;
  }

  bool get hasPhoto {
    return selectedPhoto != null ||
        (currentPhotoUrl != null && currentPhotoUrl!.trim().isNotEmpty);
  }

  EditProfileState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
    String? baseUrl,
    String? currentPhotoUrl,
    bool clearCurrentPhoto = false,
    File? selectedPhoto,
    bool clearSelectedPhoto = false,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    bool? ownerProfileLoaded,
    List<MexicoState>? states,
    List<MexicoMunicipality>? municipalities,
    String? selectedStateCode,
    bool clearSelectedState = false,
    String? selectedMunicipalityCode,
    bool clearSelectedMunicipality = false,
    bool? loadingMunicipalities,
  }) {
    return EditProfileState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      currentPhotoUrl: clearCurrentPhoto
          ? null
          : currentPhotoUrl ?? this.currentPhotoUrl,
      selectedPhoto: clearSelectedPhoto
          ? null
          : selectedPhoto ?? this.selectedPhoto,
      latitude: clearLocation ? null : latitude ?? this.latitude,
      longitude: clearLocation ? null : longitude ?? this.longitude,
      ownerProfileLoaded: ownerProfileLoaded ?? this.ownerProfileLoaded,
      states: states ?? this.states,
      municipalities: municipalities ?? this.municipalities,
      selectedStateCode: clearSelectedState
          ? null
          : selectedStateCode ?? this.selectedStateCode,
      selectedMunicipalityCode: clearSelectedMunicipality
          ? null
          : selectedMunicipalityCode ?? this.selectedMunicipalityCode,
      loadingMunicipalities:
          loadingMunicipalities ?? this.loadingMunicipalities,
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

  static double? safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }
}
