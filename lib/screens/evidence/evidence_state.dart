import 'dart:io';

import 'models/evidence_type.dart';

class EvidenceState {
  final int walkId;
  final EvidenceType type;
  final String petName;
  final String walkerName;
  final bool selecting;
  final bool uploading;
  final String? error;
  final File? selectedFile;
  final int selectedFileBytes;

  const EvidenceState({
    required this.walkId,
    required this.type,
    required this.petName,
    required this.walkerName,
    this.selecting = false,
    this.uploading = false,
    this.error,
    this.selectedFile,
    this.selectedFileBytes = 0,
  });

  bool get hasFile {
    return selectedFile != null;
  }

  bool get busy {
    return selecting || uploading;
  }

  bool get canUpload {
    return walkId > 0 &&
        selectedFile != null &&
        selectedFileBytes > 0 &&
        !busy;
  }

  String get fileName {
    final file = selectedFile;

    if (file == null) {
      return 'Sin fotografía';
    }

    final segments = file.path
        .replaceAll('\\', '/')
        .split('/');

    return segments.isEmpty
        ? 'fotografia'
        : segments.last;
  }

  String get fileSizeLabel {
    final bytes = selectedFileBytes;

    if (bytes <= 0) {
      return 'Tamaño no disponible';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    final kilobytes = bytes / 1024;

    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }

    final megabytes = kilobytes / 1024;

    return '${megabytes.toStringAsFixed(2)} MB';
  }

  EvidenceState copyWith({
    int? walkId,
    EvidenceType? type,
    String? petName,
    String? walkerName,
    bool? selecting,
    bool? uploading,
    String? error,
    bool clearError = false,
    File? selectedFile,
    bool clearSelectedFile = false,
    int? selectedFileBytes,
  }) {
    return EvidenceState(
      walkId: walkId ?? this.walkId,
      type: type ?? this.type,
      petName: petName ?? this.petName,
      walkerName:
          walkerName ?? this.walkerName,
      selecting:
          selecting ?? this.selecting,
      uploading:
          uploading ?? this.uploading,
      error:
          clearError ? null : error ?? this.error,
      selectedFile: clearSelectedFile
          ? null
          : selectedFile ?? this.selectedFile,
      selectedFileBytes: clearSelectedFile
          ? 0
          : selectedFileBytes ??
              this.selectedFileBytes,
    );
  }
}