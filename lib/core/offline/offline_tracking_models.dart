enum OfflineSyncStatus {
  pending(0),
  syncing(1),
  synced(2),
  failed(3);

  const OfflineSyncStatus(this.value);

  final int value;

  static OfflineSyncStatus fromValue(int value) {
    return OfflineSyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OfflineSyncStatus.pending,
    );
  }
}

enum PendingWalkOperationType {
  start,
  finish,
  cancel,
  uploadStartEvidence,
  uploadEndEvidence;

  String get storageValue => name;

  static PendingWalkOperationType fromStorage(String value) {
    return PendingWalkOperationType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => PendingWalkOperationType.finish,
    );
  }
}

class OfflineTrackingPointDraft {
  const OfflineTrackingPointDraft({
    required this.paseoId,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
  });

  final int paseoId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime capturedAt;
}

class OfflineTrackingPointRecord {
  const OfflineTrackingPointRecord({
    required this.clientPointId,
    required this.paseoId,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.syncStatus,
    required this.retryCount,
    required this.createdAt,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.lastError,
    this.syncedAt,
  });

  final String clientPointId;
  final int paseoId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime capturedAt;
  final OfflineSyncStatus syncStatus;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? syncedAt;
}

class PendingWalkOperationDraft {
  const PendingWalkOperationDraft({
    required this.paseoId,
    required this.type,
    this.payloadJson = '{}',
  });

  final int paseoId;
  final PendingWalkOperationType type;
  final String payloadJson;
}

class PendingWalkOperationRecord {
  const PendingWalkOperationRecord({
    required this.clientOperationId,
    required this.paseoId,
    required this.type,
    required this.payloadJson,
    required this.syncStatus,
    required this.retryCount,
    required this.createdAt,
    this.lastError,
    this.syncedAt,
  });

  final String clientOperationId;
  final int paseoId;
  final PendingWalkOperationType type;
  final String payloadJson;
  final OfflineSyncStatus syncStatus;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? syncedAt;
}

class OfflinePendingSummary {
  const OfflinePendingSummary({
    required this.trackingPoints,
    required this.walkOperations,
  });

  final int trackingPoints;
  final int walkOperations;

  int get total => trackingPoints + walkOperations;

  bool get hasPending => total > 0;
}
