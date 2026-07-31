import 'dart:io';

enum PetFormMode {
  create,
  edit,
}

class PetFormState {
  static const List<String> availableSizes = [
    'Pequeño',
    'Mediano',
    'Grande',
  ];

  final PetFormMode mode;
  final bool loading;
  final bool saving;
  final String? error;
  final String? baseUrl;
  final String selectedSize;
  final String? currentPhotoUrl;
  final File? selectedPhoto;

  const PetFormState({
    required this.mode,
    this.loading = false,
    this.saving = false,
    this.error,
    this.baseUrl,
    this.selectedSize = 'Mediano',
    this.currentPhotoUrl,
    this.selectedPhoto,
  });

  bool get isCreating => mode == PetFormMode.create;

  bool get isEditing => mode == PetFormMode.edit;

  bool get hasPhoto {
    return selectedPhoto != null ||
        (currentPhotoUrl != null &&
            currentPhotoUrl!.trim().isNotEmpty);
  }

  String get screenTitle {
    return isCreating ? 'Agregar mascota' : 'Editar mascota';
  }

  String get saveButtonText {
    return isCreating
        ? 'Registrar mascota'
        : 'Guardar cambios';
  }

  PetFormState copyWith({
    PetFormMode? mode,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
    String? baseUrl,
    String? selectedSize,
    String? currentPhotoUrl,
    bool clearCurrentPhoto = false,
    File? selectedPhoto,
    bool clearSelectedPhoto = false,
  }) {
    return PetFormState(
      mode: mode ?? this.mode,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      selectedSize:
          selectedSize ?? this.selectedSize,
      currentPhotoUrl: clearCurrentPhoto
          ? null
          : currentPhotoUrl ?? this.currentPhotoUrl,
      selectedPhoto: clearSelectedPhoto
          ? null
          : selectedPhoto ?? this.selectedPhoto,
    );
  }

  String? publicUrl(dynamic value) {
    final path = value?.toString().trim();

    if (path == null ||
        path.isEmpty ||
        path.toLowerCase() == 'null') {
      return null;
    }

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    final server = baseUrl?.trim() ?? '';

    if (server.isEmpty) return path;

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath =
        path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  static String normalizeSize(dynamic value) {
    final text = value?.toString().trim() ?? '';

    for (final size in availableSizes) {
      if (size.toLowerCase() == text.toLowerCase()) {
        return size;
      }
    }

    final normalized = text.toLowerCase();

    if (normalized.contains('peque')) {
      return 'Pequeño';
    }

    if (normalized.contains('grand')) {
      return 'Grande';
    }

    return 'Mediano';
  }
}