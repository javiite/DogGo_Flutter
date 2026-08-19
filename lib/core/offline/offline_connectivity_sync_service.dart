import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'offline_tracking_models.dart';
import 'offline_tracking_repository.dart';
import 'offline_walk_sync_service.dart';
import '../../services/session_service.dart';

enum OfflineRecoveryStatus { idle, offline, syncing, synchronized, failed }

class OfflineConnectivitySyncService extends ChangeNotifier {
  OfflineConnectivitySyncService({
    Connectivity? connectivity,
    OfflineTrackingRepository? repository,
    OfflineWalkSyncService? walkSyncService,
  }) : _connectivity = connectivity ?? Connectivity(),
       _repository = repository ?? OfflineTrackingRepository(),
       _walkSyncService = walkSyncService ?? OfflineWalkSyncService.instance;

  static final OfflineConnectivitySyncService instance =
      OfflineConnectivitySyncService();

  final Connectivity _connectivity;
  final OfflineTrackingRepository _repository;
  final OfflineWalkSyncService _walkSyncService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<OfflinePendingSummary>? _pendingSubscription;
  Timer? _pollTimer;
  Timer? _successTimer;

  OfflinePendingSummary _summary = const OfflinePendingSummary(
    trackingPoints: 0,
    walkOperations: 0,
  );
  OfflineRecoveryStatus _status = OfflineRecoveryStatus.idle;
  Object? _lastError;
  bool _initialized = false;
  bool _online = true;
  bool _syncing = false;
  bool _hasIrrecoverable = false;
  DateTime? _lastSyncAttempt;

  OfflinePendingSummary get summary => _summary;
  OfflineRecoveryStatus get status => _status;
  Object? get lastError => _lastError;
  bool get online => _online;
  bool get syncing => _syncing;
  bool get hasPending => _summary.hasPending;
  bool get hasIrrecoverable => _hasIrrecoverable;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _refreshSummary();

    final initialConnectivity = await _connectivity.checkConnectivity();
    _online = _hasNetwork(initialConnectivity);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    _pendingSubscription = _repository.watchPendingSummary().listen((summary) {
      _summary = summary;
      if (!_online && summary.hasPending) {
        _status = OfflineRecoveryStatus.offline;
      }
      notifyListeners();
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_pollPendingWork());
    });

    if (_online && _summary.hasPending) {
      unawaited(syncNow());
    } else if (!_online && _summary.hasPending) {
      _status = OfflineRecoveryStatus.offline;
      notifyListeners();
    }
  }

  Future<void> _handleConnectivityChanged(
    List<ConnectivityResult> results,
  ) async {
    final wasOnline = _online;
    _online = _hasNetwork(results);

    if (!_online) {
      if (_summary.hasPending) {
        _status = OfflineRecoveryStatus.offline;
      }
      notifyListeners();
      return;
    }

    notifyListeners();

    if (!wasOnline || _summary.hasPending) {
      await syncNow();
    }
  }

  Future<void> syncNow() async {
    if (_syncing) return;

    if (!await SessionService.esPaseador()) {
      _status = _summary.hasPending
          ? OfflineRecoveryStatus.offline
          : OfflineRecoveryStatus.idle;
      _lastError = _summary.hasPending
          ? 'Los puntos GPS se sincronizan únicamente en modo Paseador.'
          : null;
      notifyListeners();
      return;
    }

    _lastSyncAttempt = DateTime.now();

    final connectivity = await _connectivity.checkConnectivity();
    _online = _hasNetwork(connectivity);

    await _refreshSummary();

    if (!_online) {
      _status = _summary.hasPending
          ? OfflineRecoveryStatus.offline
          : OfflineRecoveryStatus.idle;
      notifyListeners();
      return;
    }

    if (!_summary.hasPending) {
      _status = OfflineRecoveryStatus.idle;
      _lastError = null;
      notifyListeners();
      return;
    }

    _syncing = true;
    _status = OfflineRecoveryStatus.syncing;
    _lastError = null;
    _successTimer?.cancel();
    notifyListeners();

    try {
      final result = await _walkSyncService.syncPending(maxOperations: 100);
      await _refreshSummary();

      if (_summary.hasPending || result.lastError != null) {
        _status = OfflineRecoveryStatus.failed;
        _lastError = result.lastError;
        _hasIrrecoverable = _isPermanent(result.lastError);
      } else {
        _status = OfflineRecoveryStatus.synchronized;
        _lastError = null;
        _successTimer = Timer(const Duration(seconds: 4), () {
          if (_status == OfflineRecoveryStatus.synchronized) {
            _status = OfflineRecoveryStatus.idle;
            notifyListeners();
          }
        });
      }
    } catch (error) {
      _status = OfflineRecoveryStatus.failed;
      _lastError = error;
      await _refreshSummary();
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<int> discardIrrecoverable() async {
    if (!_hasIrrecoverable || _syncing) return 0;
    final removed = await _repository.discardFailedTrackingPoints();
    _hasIrrecoverable = false;
    _lastError = null;
    await _refreshSummary();
    _status = _summary.hasPending
        ? OfflineRecoveryStatus.idle
        : OfflineRecoveryStatus.synchronized;
    notifyListeners();
    return removed;
  }

  bool _isPermanent(Object? error) {
    final message = error?.toString().toLowerCase() ?? '';
    return message.contains('código: 400') ||
        message.contains('código: 403') ||
        message.contains('paseo no encontrado') ||
        message.contains('solo se puede enviar ubicación') ||
        message.contains('solo el paseador asignado');
  }

  Future<void> _refreshSummary() async {
    final next = OfflinePendingSummary(
      trackingPoints: await _repository.pendingTrackingPointCount(),
      walkOperations: await _repository.pendingWalkOperationCount(),
    );

    if (next.trackingPoints == _summary.trackingPoints &&
        next.walkOperations == _summary.walkOperations) {
      return;
    }

    _summary = next;

    if (!_online && next.hasPending) {
      _status = OfflineRecoveryStatus.offline;
    }

    notifyListeners();
  }

  Future<void> _pollPendingWork() async {
    await _refreshSummary();

    if (!_summary.hasPending ||
        _syncing ||
        _status == OfflineRecoveryStatus.failed) {
      return;
    }

    final lastAttempt = _lastSyncAttempt;
    final mayRetry =
        lastAttempt == null ||
        DateTime.now().difference(lastAttempt) >= const Duration(seconds: 20);

    if (mayRetry) {
      await syncNow();
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingSubscription?.cancel();
    _pollTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }
}
