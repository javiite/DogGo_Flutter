import 'package:uuid/uuid.dart';

import '../database/doggo_database.dart';
import 'offline_tracking_models.dart';

class OfflineTrackingRepository {
  OfflineTrackingRepository({DogGoDatabase? database, Uuid? uuid})
    : _database = database ?? DogGoDatabase.instance,
      _uuid = uuid ?? const Uuid();

  final DogGoDatabase _database;
  final Uuid _uuid;

  Future<String> saveTrackingPoint(OfflineTrackingPointDraft point) async {
    final clientPointId = _uuid.v4();

    await _database.insertTrackingPoint(
      clientPointId: clientPointId,
      point: point,
    );

    return clientPointId;
  }

  Future<String> enqueueWalkOperation(
    PendingWalkOperationDraft operation,
  ) async {
    final clientOperationId = _uuid.v4();

    await _database.insertWalkOperation(
      clientOperationId: clientOperationId,
      operation: operation,
    );

    return clientOperationId;
  }

  Future<List<OfflineTrackingPointRecord>> pendingTrackingPoints({
    int limit = 100,
  }) async {
    final rows = await _database.pendingTrackingPoints(limit: limit);

    return _mapTrackingPoints(rows);
  }

  Future<List<OfflineTrackingPointRecord>> claimPendingTrackingPoints({
    int limit = 100,
  }) async {
    final rows = await _database.claimPendingTrackingPoints(limit: limit);

    return _mapTrackingPoints(rows);
  }

  List<OfflineTrackingPointRecord> _mapTrackingPoints(
    Iterable<OfflineTrackingPoint> rows,
  ) {
    return rows
        .map(
          (row) => OfflineTrackingPointRecord(
            clientPointId: row.clientPointId,
            paseoId: row.paseoId,
            latitude: row.latitude,
            longitude: row.longitude,
            accuracy: row.accuracy,
            altitude: row.altitude,
            speed: row.speed,
            heading: row.heading,
            capturedAt: row.capturedAt,
            syncStatus: OfflineSyncStatus.fromValue(row.syncStatus),
            retryCount: row.retryCount,
            lastError: row.lastError,
            createdAt: row.createdAt,
            syncedAt: row.syncedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<int> pendingTrackingPointCount() {
    return _database.pendingTrackingPointCount();
  }

  Future<int> discardFailedTrackingPoints() async {
    final points = await pendingTrackingPoints(limit: 100000);
    final ids = points
        .where((point) => point.syncStatus == OfflineSyncStatus.failed)
        .map((point) => point.clientPointId)
        .toList(growable: false);
    if (ids.isEmpty) return 0;
    await markTrackingPointsSynced(ids);
    return ids.length;
  }

  Future<int> pendingTrackingPointCountForWalk(int paseoId) {
    return _database.pendingTrackingPointCountForWalk(paseoId);
  }

  Future<List<PendingWalkOperationRecord>> pendingWalkOperations({
    int limit = 25,
  }) async {
    final rows = await _database.pendingWalkOperationsList(limit: limit);

    return rows.map(_mapWalkOperation).toList(growable: false);
  }

  Future<PendingWalkOperationRecord?> claimNextWalkOperation() async {
    final row = await _database.claimNextWalkOperation();
    return row == null ? null : _mapWalkOperation(row);
  }

  PendingWalkOperationRecord _mapWalkOperation(PendingWalkOperation row) {
    return PendingWalkOperationRecord(
      clientOperationId: row.clientOperationId,
      paseoId: row.paseoId,
      type: PendingWalkOperationType.fromStorage(row.operationType),
      payloadJson: row.payloadJson,
      syncStatus: OfflineSyncStatus.fromValue(row.syncStatus),
      retryCount: row.retryCount,
      lastError: row.lastError,
      createdAt: row.createdAt,
      syncedAt: row.syncedAt,
    );
  }

  Future<int> pendingWalkOperationCount() {
    return _database.pendingWalkOperationCount();
  }

  Future<void> markWalkOperationSynced(String clientOperationId) {
    return _database.setWalkOperationSynced(clientOperationId);
  }

  Future<void> markWalkOperationFailed(String clientOperationId, Object error) {
    return _database.setWalkOperationFailed(
      clientOperationId,
      error.toString(),
    );
  }

  Future<void> markTrackingPointsSyncing(List<String> ids) {
    return _database.setTrackingPointsSyncing(ids);
  }

  Future<void> markTrackingPointsSynced(List<String> ids) {
    return _database.setTrackingPointsSynced(ids);
  }

  Future<void> markTrackingPointsFailed(List<String> ids, Object error) {
    return _database.setTrackingPointsFailed(ids, error.toString());
  }

  Future<void> recoverInterruptedSyncs() {
    return _database.resetInterruptedSyncs();
  }

  Stream<OfflinePendingSummary> watchPendingSummary() {
    return _database.watchPendingSummary();
  }
}
