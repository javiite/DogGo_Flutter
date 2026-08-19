import 'dart:convert';
import 'dart:io';

import '../../services/evidencia_service.dart';
import '../../services/paseos_service.dart';
import 'offline_evidence_storage.dart';
import 'offline_tracking_models.dart';
import 'offline_tracking_repository.dart';
import 'offline_tracking_sync_service.dart';

class OfflineWalkSyncService {
  OfflineWalkSyncService({
    OfflineTrackingRepository? repository,
    OfflineTrackingSyncService? trackingSyncService,
    OfflineEvidenceStorage? evidenceStorage,
    EvidenciaService? evidenciaService,
  }) : _repository = repository ?? OfflineTrackingRepository(),
       _trackingSyncService =
           trackingSyncService ?? OfflineTrackingSyncService.instance,
       _evidenceStorage = evidenceStorage ?? OfflineEvidenceStorage(),
       _evidenciaService = evidenciaService ?? EvidenciaService();

  static final OfflineWalkSyncService instance = OfflineWalkSyncService();

  final OfflineTrackingRepository _repository;
  final OfflineTrackingSyncService _trackingSyncService;
  final OfflineEvidenceStorage _evidenceStorage;
  final EvidenciaService _evidenciaService;

  bool _syncing = false;

  Future<void> initialize() {
    return _repository.recoverInterruptedSyncs();
  }

  Future<String> queueStart(int paseoId) {
    return _enqueueUnique(paseoId, PendingWalkOperationType.start);
  }

  Future<String> queueFinish(int paseoId) {
    return _enqueueUnique(paseoId, PendingWalkOperationType.finish);
  }

  Future<String> queueCancel(int paseoId, {String? reason}) {
    return _enqueueUnique(
      paseoId,
      PendingWalkOperationType.cancel,
      payload: <String, dynamic>{
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<String> queueEvidence({
    required int paseoId,
    required PendingWalkOperationType type,
    required File source,
  }) async {
    if (type != PendingWalkOperationType.uploadStartEvidence &&
        type != PendingWalkOperationType.uploadEndEvidence) {
      throw ArgumentError.value(type, 'type', 'Tipo de evidencia no válido.');
    }

    final existing = await _findPendingOperation(paseoId, type);
    if (existing != null) return existing.clientOperationId;

    final preserved = await _evidenceStorage.preserve(
      paseoId: paseoId,
      type: type,
      source: source,
    );

    try {
      return await _enqueue(
        paseoId,
        type,
        payload: <String, dynamic>{'filePath': preserved.path},
      );
    } catch (_) {
      await _evidenceStorage.deleteIfExists(preserved.path);
      rethrow;
    }
  }

  Future<String> _enqueue(
    int paseoId,
    PendingWalkOperationType type, {
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    return _repository.enqueueWalkOperation(
      PendingWalkOperationDraft(
        paseoId: paseoId,
        type: type,
        payloadJson: jsonEncode(payload),
      ),
    );
  }

  Future<String> _enqueueUnique(
    int paseoId,
    PendingWalkOperationType type, {
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    final existing = await _findPendingOperation(paseoId, type);
    if (existing != null) return existing.clientOperationId;

    return _enqueue(paseoId, type, payload: payload);
  }

  Future<PendingWalkOperationRecord?> _findPendingOperation(
    int paseoId,
    PendingWalkOperationType type,
  ) async {
    final operations = await _repository.pendingWalkOperations(limit: 1000);

    for (final operation in operations) {
      if (operation.paseoId == paseoId && operation.type == type) {
        return operation;
      }
    }

    return null;
  }

  Future<bool> hasPendingOperation(
    int paseoId,
    PendingWalkOperationType type,
  ) async {
    return await _findPendingOperation(paseoId, type) != null;
  }

  Future<OfflineWalkSubmissionResult> submitStart(int paseoId) async {
    return _submit(await queueStart(paseoId));
  }

  Future<OfflineWalkSubmissionResult> submitFinish(int paseoId) async {
    return _submit(await queueFinish(paseoId));
  }

  Future<OfflineWalkSubmissionResult> submitCancel(
    int paseoId, {
    String? reason,
  }) async {
    return _submit(await queueCancel(paseoId, reason: reason));
  }

  Future<OfflineWalkSubmissionResult> submitEvidence({
    required int paseoId,
    required PendingWalkOperationType type,
    required File source,
  }) async {
    return _submit(
      await queueEvidence(paseoId: paseoId, type: type, source: source),
    );
  }

  Future<OfflineWalkSubmissionResult> _submit(String clientOperationId) async {
    final syncResult = await syncPending();
    final operations = await _repository.pendingWalkOperations(limit: 1000);
    final remainsPending = operations.any(
      (operation) => operation.clientOperationId == clientOperationId,
    );

    return OfflineWalkSubmissionResult(
      clientOperationId: clientOperationId,
      synchronized: !remainsPending,
      lastError: remainsPending ? syncResult.lastError : null,
    );
  }

  Future<OfflineWalkSyncResult> syncPending({int maxOperations = 25}) async {
    if (_syncing) {
      return OfflineWalkSyncResult(
        pending: await _repository.pendingWalkOperationCount(),
        busy: true,
      );
    }

    _syncing = true;
    var synced = 0;
    Object? lastError;

    try {
      for (var index = 0; index < maxOperations; index++) {
        final operation = await _repository.claimNextWalkOperation();
        if (operation == null) break;

        try {
          await _execute(operation);
          await _repository.markWalkOperationSynced(
            operation.clientOperationId,
          );
          try {
            await _deleteEvidenceAfterSuccess(operation);
          } catch (_) {
            // La operación remota ya quedó confirmada. Un fallo de limpieza
            // local no debe provocar que la evidencia vuelva a enviarse.
          }
          synced++;
        } catch (error) {
          lastError = error;
          await _repository.markWalkOperationFailed(
            operation.clientOperationId,
            error,
          );
          break;
        }
      }

      if (lastError == null) {
        final trackingResult = await _trackingSyncService.syncPending(
          maxBatches: 20,
        );
        lastError = trackingResult.lastError;
      }

      return OfflineWalkSyncResult(
        synced: synced,
        pending: await _repository.pendingWalkOperationCount(),
        lastError: lastError,
      );
    } finally {
      _syncing = false;
    }
  }

  Future<void> _execute(PendingWalkOperationRecord operation) async {
    switch (operation.type) {
      case PendingWalkOperationType.start:
        _requireSuccess(await PaseosService.iniciarPaseo(operation.paseoId));
      case PendingWalkOperationType.finish:
        final trackingResult = await _trackingSyncService.syncPending(
          maxBatches: 20,
        );
        final walkPending = await _repository.pendingTrackingPointCountForWalk(
          operation.paseoId,
        );

        if (walkPending > 0) {
          throw Exception(
            trackingResult.lastError?.toString() ??
                'Quedan $walkPending ubicaciones pendientes de este paseo.',
          );
        }

        _requireSuccess(await PaseosService.finalizarPaseo(operation.paseoId));
      case PendingWalkOperationType.cancel:
        final payload = _decodePayload(operation.payloadJson);
        _requireSuccess(
          await PaseosService.cancelarPaseo(
            operation.paseoId,
            motivo: payload['reason']?.toString(),
          ),
        );
      case PendingWalkOperationType.uploadStartEvidence:
        await _evidenciaService.subirFotoInicio(
          paseoId: operation.paseoId,
          archivo: File(_evidencePath(operation)),
        );
      case PendingWalkOperationType.uploadEndEvidence:
        await _evidenciaService.subirFotoFin(
          paseoId: operation.paseoId,
          archivo: File(_evidencePath(operation)),
        );
    }
  }

  void _requireSuccess(Map<String, dynamic> response) {
    if (response['success'] == true) return;

    throw Exception(
      response['message']?.toString() ?? 'La operación no fue confirmada.',
    );
  }

  Map<String, dynamic> _decodePayload(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException(
        'La operación offline tiene datos inválidos.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _evidencePath(PendingWalkOperationRecord operation) {
    final path = _decodePayload(
      operation.payloadJson,
    )['filePath']?.toString().trim();

    if (path == null || path.isEmpty) {
      throw const FormatException('La evidencia offline no contiene archivo.');
    }

    return path;
  }

  Future<void> _deleteEvidenceAfterSuccess(
    PendingWalkOperationRecord operation,
  ) async {
    if (operation.type != PendingWalkOperationType.uploadStartEvidence &&
        operation.type != PendingWalkOperationType.uploadEndEvidence) {
      return;
    }

    await _evidenceStorage.deleteIfExists(_evidencePath(operation));
  }
}

class OfflineWalkSyncResult {
  const OfflineWalkSyncResult({
    this.synced = 0,
    this.pending = 0,
    this.busy = false,
    this.lastError,
  });

  final int synced;
  final int pending;
  final bool busy;
  final Object? lastError;

  bool get completed => pending == 0 && lastError == null;
}

class OfflineWalkSubmissionResult {
  const OfflineWalkSubmissionResult({
    required this.clientOperationId,
    required this.synchronized,
    this.lastError,
  });

  final String clientOperationId;
  final bool synchronized;
  final Object? lastError;

  bool get queued => !synchronized;
}
