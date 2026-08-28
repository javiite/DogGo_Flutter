import 'package:doggo_flutter/core/offline/offline_tracking_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conserva el contrato de estados de sincronización', () {
    for (final status in OfflineSyncStatus.values) {
      expect(OfflineSyncStatus.fromValue(status.value), status);
    }

    expect(OfflineSyncStatus.fromValue(999), OfflineSyncStatus.pending);
  });

  test('conserva los tipos de operación pendientes', () {
    for (final type in PendingWalkOperationType.values) {
      expect(PendingWalkOperationType.fromStorage(type.storageValue), type);
    }
  });

  test('resume correctamente el trabajo pendiente', () {
    const summary = OfflinePendingSummary(trackingPoints: 4, walkOperations: 2);

    expect(summary.total, 6);
    expect(summary.hasPending, isTrue);
  });
}
