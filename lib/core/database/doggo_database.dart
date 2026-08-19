import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../offline/offline_tracking_models.dart';
import 'tables/cached_walks.dart';
import 'tables/offline_tracking_points.dart';
import 'tables/pending_walk_operations.dart';

part 'doggo_database.g.dart';

@DriftDatabase(
  tables: [OfflineTrackingPoints, PendingWalkOperations, CachedWalks],
)
class DogGoDatabase extends _$DogGoDatabase {
  DogGoDatabase._()
    : super(
        driftDatabase(
          name: 'doggo_offline',
          native: const DriftNativeOptions(shareAcrossIsolates: true),
        ),
      );

  static final DogGoDatabase instance = DogGoDatabase._();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS '
        'idx_offline_tracking_pending '
        'ON offline_tracking_points '
        '(sync_status, paseo_id, captured_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS '
        'idx_walk_operations_pending '
        'ON pending_walk_operations '
        '(sync_status, paseo_id, created_at)',
      );
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(cachedWalks);
      }
    },
  );

  Future<void> replaceCachedWalkList(
    List<({int paseoId, String dataJson})> walks,
  ) async {
    await transaction(() async {
      await update(
        cachedWalks,
      ).write(const CachedWalksCompanion(isInList: Value(false)));

      final now = DateTime.now().toUtc();

      for (final walk in walks) {
        final existing = await (select(
          cachedWalks,
        )..where((row) => row.paseoId.equals(walk.paseoId))).getSingleOrNull();

        await into(cachedWalks).insertOnConflictUpdate(
          CachedWalksCompanion.insert(
            paseoId: Value(walk.paseoId),
            dataJson: walk.dataJson,
            isInList: const Value(true),
            hasDetail: Value(existing?.hasDetail ?? false),
            cachedAt: now,
          ),
        );
      }
    });
  }

  Future<void> saveCachedWalkDetail({
    required int paseoId,
    required String dataJson,
  }) async {
    await transaction(() async {
      final existing = await (select(
        cachedWalks,
      )..where((row) => row.paseoId.equals(paseoId))).getSingleOrNull();

      await into(cachedWalks).insertOnConflictUpdate(
        CachedWalksCompanion.insert(
          paseoId: Value(paseoId),
          dataJson: dataJson,
          isInList: Value(existing?.isInList ?? false),
          hasDetail: const Value(true),
          cachedAt: DateTime.now().toUtc(),
        ),
      );
    });
  }

  Future<List<CachedWalk>> cachedWalkList() {
    final query = select(cachedWalks)
      ..where((row) => row.isInList.equals(true))
      ..orderBy([(row) => OrderingTerm.desc(row.cachedAt)]);

    return query.get();
  }

  Future<CachedWalk?> cachedWalkDetail(int paseoId) {
    final query = select(cachedWalks)
      ..where((row) => row.paseoId.equals(paseoId) & row.hasDetail.equals(true))
      ..limit(1);

    return query.getSingleOrNull();
  }

  Future<bool> insertTrackingPoint({
    required String clientPointId,
    required OfflineTrackingPointDraft point,
  }) async {
    final inserted = await into(offlineTrackingPoints).insert(
      OfflineTrackingPointsCompanion.insert(
        clientPointId: clientPointId,
        paseoId: point.paseoId,
        latitude: point.latitude,
        longitude: point.longitude,
        accuracy: Value(point.accuracy),
        altitude: Value(point.altitude),
        speed: Value(point.speed),
        heading: Value(point.heading),
        capturedAt: point.capturedAt.toUtc(),
        createdAt: DateTime.now().toUtc(),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    return inserted > 0;
  }

  Future<List<OfflineTrackingPoint>> pendingTrackingPoints({int limit = 100}) {
    final query = select(offlineTrackingPoints)
      ..where(
        (row) => row.syncStatus.isIn([
          OfflineSyncStatus.pending.value,
          OfflineSyncStatus.failed.value,
        ]),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.capturedAt)])
      ..limit(limit);

    return query.get();
  }

  Future<List<OfflineTrackingPoint>> claimPendingTrackingPoints({
    int limit = 100,
  }) {
    return transaction(() async {
      final rows = await pendingTrackingPoints(limit: limit);

      if (rows.isEmpty) {
        return const <OfflineTrackingPoint>[];
      }

      final ids = rows.map((row) => row.clientPointId).toList(growable: false);

      await (update(offlineTrackingPoints)..where(
            (row) =>
                row.clientPointId.isIn(ids) &
                row.syncStatus.isIn([
                  OfflineSyncStatus.pending.value,
                  OfflineSyncStatus.failed.value,
                ]),
          ))
          .write(
            OfflineTrackingPointsCompanion(
              syncStatus: Value(OfflineSyncStatus.syncing.value),
              lastError: const Value(null),
            ),
          );

      return rows;
    });
  }

  Future<int> pendingTrackingPointCount() async {
    final count = offlineTrackingPoints.clientPointId.count();
    final query = selectOnly(offlineTrackingPoints)
      ..addColumns([count])
      ..where(
        offlineTrackingPoints.syncStatus.isNotIn([
          OfflineSyncStatus.synced.value,
        ]),
      );

    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> pendingTrackingPointCountForWalk(int paseoId) async {
    final count = offlineTrackingPoints.clientPointId.count();
    final query = selectOnly(offlineTrackingPoints)
      ..addColumns([count])
      ..where(
        offlineTrackingPoints.paseoId.equals(paseoId) &
            offlineTrackingPoints.syncStatus.isNotIn([
              OfflineSyncStatus.synced.value,
            ]),
      );

    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> setTrackingPointsSyncing(List<String> ids) async {
    if (ids.isEmpty) return;

    await (update(
      offlineTrackingPoints,
    )..where((row) => row.clientPointId.isIn(ids))).write(
      OfflineTrackingPointsCompanion(
        syncStatus: Value(OfflineSyncStatus.syncing.value),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> setTrackingPointsSynced(List<String> ids) async {
    if (ids.isEmpty) return;

    await (update(
      offlineTrackingPoints,
    )..where((row) => row.clientPointId.isIn(ids))).write(
      OfflineTrackingPointsCompanion(
        syncStatus: Value(OfflineSyncStatus.synced.value),
        lastError: const Value(null),
        syncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> setTrackingPointsFailed(List<String> ids, String error) async {
    if (ids.isEmpty) return;

    await transaction(() async {
      final rows = await (select(
        offlineTrackingPoints,
      )..where((row) => row.clientPointId.isIn(ids))).get();

      for (final row in rows) {
        await (update(
          offlineTrackingPoints,
        )..where((item) => item.clientPointId.equals(row.clientPointId))).write(
          OfflineTrackingPointsCompanion(
            syncStatus: Value(OfflineSyncStatus.failed.value),
            retryCount: Value(row.retryCount + 1),
            lastError: Value(error),
          ),
        );
      }
    });
  }

  Future<bool> insertWalkOperation({
    required String clientOperationId,
    required PendingWalkOperationDraft operation,
  }) async {
    final inserted = await into(pendingWalkOperations).insert(
      PendingWalkOperationsCompanion.insert(
        clientOperationId: clientOperationId,
        paseoId: operation.paseoId,
        operationType: operation.type.storageValue,
        payloadJson: Value(operation.payloadJson),
        createdAt: DateTime.now().toUtc(),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    return inserted > 0;
  }

  Future<List<PendingWalkOperation>> pendingWalkOperationsList({
    int limit = 25,
  }) {
    final query = select(pendingWalkOperations)
      ..where(
        (row) => row.syncStatus.isIn([
          OfflineSyncStatus.pending.value,
          OfflineSyncStatus.failed.value,
        ]),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
      ..limit(limit);

    return query.get();
  }

  Future<PendingWalkOperation?> claimNextWalkOperation() {
    return transaction(() async {
      final query = select(pendingWalkOperations)
        ..where(
          (row) => row.syncStatus.isIn([
            OfflineSyncStatus.pending.value,
            OfflineSyncStatus.failed.value,
          ]),
        )
        ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
        ..limit(1);

      final operation = await query.getSingleOrNull();
      if (operation == null) return null;

      final updated =
          await (update(pendingWalkOperations)..where(
                (row) =>
                    row.clientOperationId.equals(operation.clientOperationId) &
                    row.syncStatus.isIn([
                      OfflineSyncStatus.pending.value,
                      OfflineSyncStatus.failed.value,
                    ]),
              ))
              .write(
                PendingWalkOperationsCompanion(
                  syncStatus: Value(OfflineSyncStatus.syncing.value),
                  lastError: const Value(null),
                ),
              );

      return updated == 1 ? operation : null;
    });
  }

  Future<int> pendingWalkOperationCount() async {
    final count = pendingWalkOperations.clientOperationId.count();
    final query = selectOnly(pendingWalkOperations)
      ..addColumns([count])
      ..where(
        pendingWalkOperations.syncStatus.isNotIn([
          OfflineSyncStatus.synced.value,
        ]),
      );

    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> setWalkOperationSynced(String clientOperationId) async {
    await (update(
      pendingWalkOperations,
    )..where((row) => row.clientOperationId.equals(clientOperationId))).write(
      PendingWalkOperationsCompanion(
        syncStatus: Value(OfflineSyncStatus.synced.value),
        lastError: const Value(null),
        syncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> setWalkOperationFailed(
    String clientOperationId,
    String error,
  ) async {
    await transaction(() async {
      final operation =
          await (select(pendingWalkOperations)..where(
                (row) => row.clientOperationId.equals(clientOperationId),
              ))
              .getSingleOrNull();

      if (operation == null) return;

      await (update(
        pendingWalkOperations,
      )..where((row) => row.clientOperationId.equals(clientOperationId))).write(
        PendingWalkOperationsCompanion(
          syncStatus: Value(OfflineSyncStatus.failed.value),
          retryCount: Value(operation.retryCount + 1),
          lastError: Value(error),
        ),
      );
    });
  }

  Future<void> resetInterruptedSyncs() async {
    await transaction(() async {
      await (update(offlineTrackingPoints)..where(
            (row) => row.syncStatus.equals(OfflineSyncStatus.syncing.value),
          ))
          .write(
            OfflineTrackingPointsCompanion(
              syncStatus: Value(OfflineSyncStatus.pending.value),
            ),
          );

      await (update(pendingWalkOperations)..where(
            (row) => row.syncStatus.equals(OfflineSyncStatus.syncing.value),
          ))
          .write(
            PendingWalkOperationsCompanion(
              syncStatus: Value(OfflineSyncStatus.pending.value),
            ),
          );
    });
  }

  Stream<OfflinePendingSummary> watchPendingSummary() {
    final pointCount = offlineTrackingPoints.clientPointId.count();
    final operationCount = pendingWalkOperations.clientOperationId.count();

    final pointsQuery = selectOnly(offlineTrackingPoints)
      ..addColumns([pointCount])
      ..where(
        offlineTrackingPoints.syncStatus.isNotIn([
          OfflineSyncStatus.synced.value,
        ]),
      );

    final operationsQuery = selectOnly(pendingWalkOperations)
      ..addColumns([operationCount])
      ..where(
        pendingWalkOperations.syncStatus.isNotIn([
          OfflineSyncStatus.synced.value,
        ]),
      );

    return pointsQuery.watchSingle().asyncMap((pointRow) async {
      final operationRow = await operationsQuery.getSingle();

      return OfflinePendingSummary(
        trackingPoints: pointRow.read(pointCount) ?? 0,
        walkOperations: operationRow.read(operationCount) ?? 0,
      );
    });
  }
}
