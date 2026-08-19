import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/api_exception.dart';
import '../../core/offline/offline_tracking_models.dart';
import '../../core/offline/offline_walk_sync_service.dart';
import '../../services/permiso_service.dart';
import 'evidence_state.dart';
import 'models/evidence_type.dart';

enum EvidenceResultCode {
  selected,
  uploaded,
  queued,
  cancelled,
  permissionDenied,
  invalidFile,
  failed,
}

class EvidenceResult {
  final bool success;
  final String message;
  final EvidenceResultCode code;

  const EvidenceResult({
    required this.success,
    required this.message,
    required this.code,
  });

  const EvidenceResult.success(
    this.message, {
    this.code = EvidenceResultCode.selected,
  }) : success = true;

  const EvidenceResult.failure(
    this.message, {
    this.code = EvidenceResultCode.failed,
  }) : success = false;
}

class EvidenceController extends ChangeNotifier {
  static const int maximumFileBytes = 12 * 1024 * 1024;

  final ImagePicker _picker;
  final OfflineWalkSyncService _offlineSyncService;

  EvidenceState _state;

  bool _disposed = false;
  bool _selectionInProgress = false;
  bool _uploadInProgress = false;

  EvidenceController({
    required int walkId,
    required String type,
    required String petName,
    required String walkerName,
    ImagePicker? picker,
    OfflineWalkSyncService? offlineSyncService,
  }) : _picker = picker ?? ImagePicker(),
       _offlineSyncService =
           offlineSyncService ?? OfflineWalkSyncService.instance,
       _state = EvidenceState(
         walkId: walkId,
         type: EvidenceTypeData.fromValue(type),
         petName: petName,
         walkerName: walkerName,
       );

  EvidenceState get state => _state;

  Future<EvidenceResult> takePhoto() async {
    if (_selectionInProgress || _state.uploading) {
      return const EvidenceResult.failure('Ya hay una selección en proceso.');
    }

    _selectionInProgress = true;

    _setState(_state.copyWith(selecting: true, clearError: true));

    try {
      final permission = await PermisoService.pedirCamara();

      if (!permission) {
        return const EvidenceResult.failure(
          'Debes permitir el acceso a la cámara.',
          code: EvidenceResultCode.permissionDenied,
        );
      }

      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 78,
        maxWidth: 1600,
        maxHeight: 1600,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        return const EvidenceResult.failure(
          'No se seleccionó ninguna fotografía.',
          code: EvidenceResultCode.cancelled,
        );
      }

      return _selectFile(File(image.path));
    } catch (error) {
      final message = _cleanError(error);

      _setState(_state.copyWith(error: message));

      return EvidenceResult.failure(message);
    } finally {
      _selectionInProgress = false;

      _setState(_state.copyWith(selecting: false));
    }
  }

  Future<EvidenceResult> chooseFromGallery() async {
    if (_selectionInProgress || _state.uploading) {
      return const EvidenceResult.failure('Ya hay una selección en proceso.');
    }

    _selectionInProgress = true;

    _setState(_state.copyWith(selecting: true, clearError: true));

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return const EvidenceResult.failure(
          'No se seleccionó ninguna fotografía.',
          code: EvidenceResultCode.cancelled,
        );
      }

      return _selectFile(File(image.path));
    } catch (error) {
      final message = _cleanError(error);

      _setState(_state.copyWith(error: message));

      return EvidenceResult.failure(message);
    } finally {
      _selectionInProgress = false;

      _setState(_state.copyWith(selecting: false));
    }
  }

  Future<EvidenceResult> _selectFile(File file) async {
    if (!await file.exists()) {
      return const EvidenceResult.failure(
        'El archivo seleccionado ya no existe.',
        code: EvidenceResultCode.invalidFile,
      );
    }

    final bytes = await file.length();

    if (bytes <= 0) {
      return const EvidenceResult.failure(
        'La fotografía seleccionada está vacía.',
        code: EvidenceResultCode.invalidFile,
      );
    }

    if (bytes > maximumFileBytes) {
      return const EvidenceResult.failure(
        'La fotografía supera el límite de 12 MB.',
        code: EvidenceResultCode.invalidFile,
      );
    }

    _setState(
      _state.copyWith(
        selectedFile: file,
        selectedFileBytes: bytes,
        clearError: true,
      ),
    );

    return const EvidenceResult.success('Fotografía seleccionada.');
  }

  void removeSelectedFile() {
    if (_state.busy) {
      return;
    }

    _setState(_state.copyWith(clearSelectedFile: true, clearError: true));
  }

  Future<EvidenceResult> upload() async {
    if (_uploadInProgress) {
      return const EvidenceResult.failure('La evidencia ya se está subiendo.');
    }

    final file = _state.selectedFile;

    if (file == null) {
      return const EvidenceResult.failure(
        'Selecciona o toma una fotografía primero.',
        code: EvidenceResultCode.invalidFile,
      );
    }

    if (_state.walkId <= 0) {
      return const EvidenceResult.failure('No se pudo identificar el paseo.');
    }

    if (!await file.exists()) {
      _setState(_state.copyWith(clearSelectedFile: true));

      return const EvidenceResult.failure(
        'El archivo seleccionado ya no existe.',
        code: EvidenceResultCode.invalidFile,
      );
    }

    _uploadInProgress = true;

    _setState(_state.copyWith(uploading: true, clearError: true));

    try {
      final result = await _offlineSyncService.submitEvidence(
        paseoId: _state.walkId,
        type: _state.type == EvidenceType.start
            ? PendingWalkOperationType.uploadStartEvidence
            : PendingWalkOperationType.uploadEndEvidence,
        source: file,
      );

      if (result.queued) {
        return const EvidenceResult.success(
          'Evidencia guardada en el dispositivo. Se enviará al recuperar la conexión.',
          code: EvidenceResultCode.queued,
        );
      }

      return const EvidenceResult.success(
        'Evidencia subida correctamente.',
        code: EvidenceResultCode.uploaded,
      );
    } catch (error) {
      final message = _cleanError(error);

      _setState(_state.copyWith(error: message));

      return EvidenceResult.failure(message);
    } finally {
      _uploadInProgress = false;

      _setState(_state.copyWith(uploading: false));
    }
  }

  Future<bool> openAppSettings() {
    return PermisoService.abrirConfiguracion();
  }

  String _cleanError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty ? 'No se pudo procesar la evidencia.' : message;
  }

  void _setState(EvidenceState newState) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
