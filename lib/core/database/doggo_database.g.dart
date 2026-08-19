// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doggo_database.dart';

// ignore_for_file: type=lint
class $OfflineTrackingPointsTable extends OfflineTrackingPoints
    with TableInfo<$OfflineTrackingPointsTable, OfflineTrackingPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineTrackingPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientPointIdMeta = const VerificationMeta(
    'clientPointId',
  );
  @override
  late final GeneratedColumn<String> clientPointId = GeneratedColumn<String>(
    'client_point_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paseoIdMeta = const VerificationMeta(
    'paseoId',
  );
  @override
  late final GeneratedColumn<int> paseoId = GeneratedColumn<int>(
    'paseo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientPointId,
    paseoId,
    latitude,
    longitude,
    accuracy,
    altitude,
    speed,
    heading,
    capturedAt,
    syncStatus,
    retryCount,
    lastError,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_tracking_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineTrackingPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_point_id')) {
      context.handle(
        _clientPointIdMeta,
        clientPointId.isAcceptableOrUnknown(
          data['client_point_id']!,
          _clientPointIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientPointIdMeta);
    }
    if (data.containsKey('paseo_id')) {
      context.handle(
        _paseoIdMeta,
        paseoId.isAcceptableOrUnknown(data['paseo_id']!, _paseoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_paseoIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientPointId};
  @override
  OfflineTrackingPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineTrackingPoint(
      clientPointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_point_id'],
      )!,
      paseoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paseo_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $OfflineTrackingPointsTable createAlias(String alias) {
    return $OfflineTrackingPointsTable(attachedDatabase, alias);
  }
}

class OfflineTrackingPoint extends DataClass
    implements Insertable<OfflineTrackingPoint> {
  final String clientPointId;
  final int paseoId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime capturedAt;
  final int syncStatus;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const OfflineTrackingPoint({
    required this.clientPointId,
    required this.paseoId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.capturedAt,
    required this.syncStatus,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_point_id'] = Variable<String>(clientPointId);
    map['paseo_id'] = Variable<int>(paseoId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  OfflineTrackingPointsCompanion toCompanion(bool nullToAbsent) {
    return OfflineTrackingPointsCompanion(
      clientPointId: Value(clientPointId),
      paseoId: Value(paseoId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      capturedAt: Value(capturedAt),
      syncStatus: Value(syncStatus),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory OfflineTrackingPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineTrackingPoint(
      clientPointId: serializer.fromJson<String>(json['clientPointId']),
      paseoId: serializer.fromJson<int>(json['paseoId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      speed: serializer.fromJson<double?>(json['speed']),
      heading: serializer.fromJson<double?>(json['heading']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientPointId': serializer.toJson<String>(clientPointId),
      'paseoId': serializer.toJson<int>(paseoId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'altitude': serializer.toJson<double?>(altitude),
      'speed': serializer.toJson<double?>(speed),
      'heading': serializer.toJson<double?>(heading),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  OfflineTrackingPoint copyWith({
    String? clientPointId,
    int? paseoId,
    double? latitude,
    double? longitude,
    Value<double?> accuracy = const Value.absent(),
    Value<double?> altitude = const Value.absent(),
    Value<double?> speed = const Value.absent(),
    Value<double?> heading = const Value.absent(),
    DateTime? capturedAt,
    int? syncStatus,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => OfflineTrackingPoint(
    clientPointId: clientPointId ?? this.clientPointId,
    paseoId: paseoId ?? this.paseoId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    altitude: altitude.present ? altitude.value : this.altitude,
    speed: speed.present ? speed.value : this.speed,
    heading: heading.present ? heading.value : this.heading,
    capturedAt: capturedAt ?? this.capturedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  OfflineTrackingPoint copyWithCompanion(OfflineTrackingPointsCompanion data) {
    return OfflineTrackingPoint(
      clientPointId: data.clientPointId.present
          ? data.clientPointId.value
          : this.clientPointId,
      paseoId: data.paseoId.present ? data.paseoId.value : this.paseoId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      speed: data.speed.present ? data.speed.value : this.speed,
      heading: data.heading.present ? data.heading.value : this.heading,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTrackingPoint(')
          ..write('clientPointId: $clientPointId, ')
          ..write('paseoId: $paseoId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientPointId,
    paseoId,
    latitude,
    longitude,
    accuracy,
    altitude,
    speed,
    heading,
    capturedAt,
    syncStatus,
    retryCount,
    lastError,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineTrackingPoint &&
          other.clientPointId == this.clientPointId &&
          other.paseoId == this.paseoId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.altitude == this.altitude &&
          other.speed == this.speed &&
          other.heading == this.heading &&
          other.capturedAt == this.capturedAt &&
          other.syncStatus == this.syncStatus &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class OfflineTrackingPointsCompanion
    extends UpdateCompanion<OfflineTrackingPoint> {
  final Value<String> clientPointId;
  final Value<int> paseoId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> accuracy;
  final Value<double?> altitude;
  final Value<double?> speed;
  final Value<double?> heading;
  final Value<DateTime> capturedAt;
  final Value<int> syncStatus;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const OfflineTrackingPointsCompanion({
    this.clientPointId = const Value.absent(),
    this.paseoId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineTrackingPointsCompanion.insert({
    required String clientPointId,
    required int paseoId,
    required double latitude,
    required double longitude,
    this.accuracy = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    required DateTime capturedAt,
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientPointId = Value(clientPointId),
       paseoId = Value(paseoId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       capturedAt = Value(capturedAt),
       createdAt = Value(createdAt);
  static Insertable<OfflineTrackingPoint> custom({
    Expression<String>? clientPointId,
    Expression<int>? paseoId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<double>? altitude,
    Expression<double>? speed,
    Expression<double>? heading,
    Expression<DateTime>? capturedAt,
    Expression<int>? syncStatus,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientPointId != null) 'client_point_id': clientPointId,
      if (paseoId != null) 'paseo_id': paseoId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineTrackingPointsCompanion copyWith({
    Value<String>? clientPointId,
    Value<int>? paseoId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? accuracy,
    Value<double?>? altitude,
    Value<double?>? speed,
    Value<double?>? heading,
    Value<DateTime>? capturedAt,
    Value<int>? syncStatus,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return OfflineTrackingPointsCompanion(
      clientPointId: clientPointId ?? this.clientPointId,
      paseoId: paseoId ?? this.paseoId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      capturedAt: capturedAt ?? this.capturedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientPointId.present) {
      map['client_point_id'] = Variable<String>(clientPointId.value);
    }
    if (paseoId.present) {
      map['paseo_id'] = Variable<int>(paseoId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTrackingPointsCompanion(')
          ..write('clientPointId: $clientPointId, ')
          ..write('paseoId: $paseoId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingWalkOperationsTable extends PendingWalkOperations
    with TableInfo<$PendingWalkOperationsTable, PendingWalkOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingWalkOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientOperationIdMeta = const VerificationMeta(
    'clientOperationId',
  );
  @override
  late final GeneratedColumn<String> clientOperationId =
      GeneratedColumn<String>(
        'client_operation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _paseoIdMeta = const VerificationMeta(
    'paseoId',
  );
  @override
  late final GeneratedColumn<int> paseoId = GeneratedColumn<int>(
    'paseo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientOperationId,
    paseoId,
    operationType,
    payloadJson,
    syncStatus,
    retryCount,
    lastError,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_walk_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingWalkOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_operation_id')) {
      context.handle(
        _clientOperationIdMeta,
        clientOperationId.isAcceptableOrUnknown(
          data['client_operation_id']!,
          _clientOperationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOperationIdMeta);
    }
    if (data.containsKey('paseo_id')) {
      context.handle(
        _paseoIdMeta,
        paseoId.isAcceptableOrUnknown(data['paseo_id']!, _paseoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_paseoIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientOperationId};
  @override
  PendingWalkOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingWalkOperation(
      clientOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_operation_id'],
      )!,
      paseoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paseo_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $PendingWalkOperationsTable createAlias(String alias) {
    return $PendingWalkOperationsTable(attachedDatabase, alias);
  }
}

class PendingWalkOperation extends DataClass
    implements Insertable<PendingWalkOperation> {
  final String clientOperationId;
  final int paseoId;
  final String operationType;
  final String payloadJson;
  final int syncStatus;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const PendingWalkOperation({
    required this.clientOperationId,
    required this.paseoId,
    required this.operationType,
    required this.payloadJson,
    required this.syncStatus,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_operation_id'] = Variable<String>(clientOperationId);
    map['paseo_id'] = Variable<int>(paseoId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['sync_status'] = Variable<int>(syncStatus);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  PendingWalkOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingWalkOperationsCompanion(
      clientOperationId: Value(clientOperationId),
      paseoId: Value(paseoId),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      syncStatus: Value(syncStatus),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory PendingWalkOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingWalkOperation(
      clientOperationId: serializer.fromJson<String>(json['clientOperationId']),
      paseoId: serializer.fromJson<int>(json['paseoId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientOperationId': serializer.toJson<String>(clientOperationId),
      'paseoId': serializer.toJson<int>(paseoId),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  PendingWalkOperation copyWith({
    String? clientOperationId,
    int? paseoId,
    String? operationType,
    String? payloadJson,
    int? syncStatus,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => PendingWalkOperation(
    clientOperationId: clientOperationId ?? this.clientOperationId,
    paseoId: paseoId ?? this.paseoId,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    syncStatus: syncStatus ?? this.syncStatus,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  PendingWalkOperation copyWithCompanion(PendingWalkOperationsCompanion data) {
    return PendingWalkOperation(
      clientOperationId: data.clientOperationId.present
          ? data.clientOperationId.value
          : this.clientOperationId,
      paseoId: data.paseoId.present ? data.paseoId.value : this.paseoId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingWalkOperation(')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('paseoId: $paseoId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientOperationId,
    paseoId,
    operationType,
    payloadJson,
    syncStatus,
    retryCount,
    lastError,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingWalkOperation &&
          other.clientOperationId == this.clientOperationId &&
          other.paseoId == this.paseoId &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.syncStatus == this.syncStatus &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class PendingWalkOperationsCompanion
    extends UpdateCompanion<PendingWalkOperation> {
  final Value<String> clientOperationId;
  final Value<int> paseoId;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<int> syncStatus;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const PendingWalkOperationsCompanion({
    this.clientOperationId = const Value.absent(),
    this.paseoId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingWalkOperationsCompanion.insert({
    required String clientOperationId,
    required int paseoId,
    required String operationType,
    this.payloadJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientOperationId = Value(clientOperationId),
       paseoId = Value(paseoId),
       operationType = Value(operationType),
       createdAt = Value(createdAt);
  static Insertable<PendingWalkOperation> custom({
    Expression<String>? clientOperationId,
    Expression<int>? paseoId,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<int>? syncStatus,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientOperationId != null) 'client_operation_id': clientOperationId,
      if (paseoId != null) 'paseo_id': paseoId,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingWalkOperationsCompanion copyWith({
    Value<String>? clientOperationId,
    Value<int>? paseoId,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<int>? syncStatus,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return PendingWalkOperationsCompanion(
      clientOperationId: clientOperationId ?? this.clientOperationId,
      paseoId: paseoId ?? this.paseoId,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientOperationId.present) {
      map['client_operation_id'] = Variable<String>(clientOperationId.value);
    }
    if (paseoId.present) {
      map['paseo_id'] = Variable<int>(paseoId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingWalkOperationsCompanion(')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('paseoId: $paseoId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWalksTable extends CachedWalks
    with TableInfo<$CachedWalksTable, CachedWalk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWalksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _paseoIdMeta = const VerificationMeta(
    'paseoId',
  );
  @override
  late final GeneratedColumn<int> paseoId = GeneratedColumn<int>(
    'paseo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isInListMeta = const VerificationMeta(
    'isInList',
  );
  @override
  late final GeneratedColumn<bool> isInList = GeneratedColumn<bool>(
    'is_in_list',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_in_list" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasDetailMeta = const VerificationMeta(
    'hasDetail',
  );
  @override
  late final GeneratedColumn<bool> hasDetail = GeneratedColumn<bool>(
    'has_detail',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_detail" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    paseoId,
    dataJson,
    isInList,
    hasDetail,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_walks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWalk> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('paseo_id')) {
      context.handle(
        _paseoIdMeta,
        paseoId.isAcceptableOrUnknown(data['paseo_id']!, _paseoIdMeta),
      );
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('is_in_list')) {
      context.handle(
        _isInListMeta,
        isInList.isAcceptableOrUnknown(data['is_in_list']!, _isInListMeta),
      );
    }
    if (data.containsKey('has_detail')) {
      context.handle(
        _hasDetailMeta,
        hasDetail.isAcceptableOrUnknown(data['has_detail']!, _hasDetailMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {paseoId};
  @override
  CachedWalk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWalk(
      paseoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paseo_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      isInList: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_in_list'],
      )!,
      hasDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_detail'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedWalksTable createAlias(String alias) {
    return $CachedWalksTable(attachedDatabase, alias);
  }
}

class CachedWalk extends DataClass implements Insertable<CachedWalk> {
  final int paseoId;
  final String dataJson;
  final bool isInList;
  final bool hasDetail;
  final DateTime cachedAt;
  const CachedWalk({
    required this.paseoId,
    required this.dataJson,
    required this.isInList,
    required this.hasDetail,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['paseo_id'] = Variable<int>(paseoId);
    map['data_json'] = Variable<String>(dataJson);
    map['is_in_list'] = Variable<bool>(isInList);
    map['has_detail'] = Variable<bool>(hasDetail);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedWalksCompanion toCompanion(bool nullToAbsent) {
    return CachedWalksCompanion(
      paseoId: Value(paseoId),
      dataJson: Value(dataJson),
      isInList: Value(isInList),
      hasDetail: Value(hasDetail),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedWalk.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWalk(
      paseoId: serializer.fromJson<int>(json['paseoId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      isInList: serializer.fromJson<bool>(json['isInList']),
      hasDetail: serializer.fromJson<bool>(json['hasDetail']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'paseoId': serializer.toJson<int>(paseoId),
      'dataJson': serializer.toJson<String>(dataJson),
      'isInList': serializer.toJson<bool>(isInList),
      'hasDetail': serializer.toJson<bool>(hasDetail),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedWalk copyWith({
    int? paseoId,
    String? dataJson,
    bool? isInList,
    bool? hasDetail,
    DateTime? cachedAt,
  }) => CachedWalk(
    paseoId: paseoId ?? this.paseoId,
    dataJson: dataJson ?? this.dataJson,
    isInList: isInList ?? this.isInList,
    hasDetail: hasDetail ?? this.hasDetail,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedWalk copyWithCompanion(CachedWalksCompanion data) {
    return CachedWalk(
      paseoId: data.paseoId.present ? data.paseoId.value : this.paseoId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      isInList: data.isInList.present ? data.isInList.value : this.isInList,
      hasDetail: data.hasDetail.present ? data.hasDetail.value : this.hasDetail,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWalk(')
          ..write('paseoId: $paseoId, ')
          ..write('dataJson: $dataJson, ')
          ..write('isInList: $isInList, ')
          ..write('hasDetail: $hasDetail, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(paseoId, dataJson, isInList, hasDetail, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWalk &&
          other.paseoId == this.paseoId &&
          other.dataJson == this.dataJson &&
          other.isInList == this.isInList &&
          other.hasDetail == this.hasDetail &&
          other.cachedAt == this.cachedAt);
}

class CachedWalksCompanion extends UpdateCompanion<CachedWalk> {
  final Value<int> paseoId;
  final Value<String> dataJson;
  final Value<bool> isInList;
  final Value<bool> hasDetail;
  final Value<DateTime> cachedAt;
  const CachedWalksCompanion({
    this.paseoId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.isInList = const Value.absent(),
    this.hasDetail = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedWalksCompanion.insert({
    this.paseoId = const Value.absent(),
    required String dataJson,
    this.isInList = const Value.absent(),
    this.hasDetail = const Value.absent(),
    required DateTime cachedAt,
  }) : dataJson = Value(dataJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedWalk> custom({
    Expression<int>? paseoId,
    Expression<String>? dataJson,
    Expression<bool>? isInList,
    Expression<bool>? hasDetail,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (paseoId != null) 'paseo_id': paseoId,
      if (dataJson != null) 'data_json': dataJson,
      if (isInList != null) 'is_in_list': isInList,
      if (hasDetail != null) 'has_detail': hasDetail,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedWalksCompanion copyWith({
    Value<int>? paseoId,
    Value<String>? dataJson,
    Value<bool>? isInList,
    Value<bool>? hasDetail,
    Value<DateTime>? cachedAt,
  }) {
    return CachedWalksCompanion(
      paseoId: paseoId ?? this.paseoId,
      dataJson: dataJson ?? this.dataJson,
      isInList: isInList ?? this.isInList,
      hasDetail: hasDetail ?? this.hasDetail,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (paseoId.present) {
      map['paseo_id'] = Variable<int>(paseoId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (isInList.present) {
      map['is_in_list'] = Variable<bool>(isInList.value);
    }
    if (hasDetail.present) {
      map['has_detail'] = Variable<bool>(hasDetail.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWalksCompanion(')
          ..write('paseoId: $paseoId, ')
          ..write('dataJson: $dataJson, ')
          ..write('isInList: $isInList, ')
          ..write('hasDetail: $hasDetail, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$DogGoDatabase extends GeneratedDatabase {
  _$DogGoDatabase(QueryExecutor e) : super(e);
  $DogGoDatabaseManager get managers => $DogGoDatabaseManager(this);
  late final $OfflineTrackingPointsTable offlineTrackingPoints =
      $OfflineTrackingPointsTable(this);
  late final $PendingWalkOperationsTable pendingWalkOperations =
      $PendingWalkOperationsTable(this);
  late final $CachedWalksTable cachedWalks = $CachedWalksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    offlineTrackingPoints,
    pendingWalkOperations,
    cachedWalks,
  ];
}

typedef $$OfflineTrackingPointsTableCreateCompanionBuilder =
    OfflineTrackingPointsCompanion Function({
      required String clientPointId,
      required int paseoId,
      required double latitude,
      required double longitude,
      Value<double?> accuracy,
      Value<double?> altitude,
      Value<double?> speed,
      Value<double?> heading,
      required DateTime capturedAt,
      Value<int> syncStatus,
      Value<int> retryCount,
      Value<String?> lastError,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$OfflineTrackingPointsTableUpdateCompanionBuilder =
    OfflineTrackingPointsCompanion Function({
      Value<String> clientPointId,
      Value<int> paseoId,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> accuracy,
      Value<double?> altitude,
      Value<double?> speed,
      Value<double?> heading,
      Value<DateTime> capturedAt,
      Value<int> syncStatus,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$OfflineTrackingPointsTableFilterComposer
    extends Composer<_$DogGoDatabase, $OfflineTrackingPointsTable> {
  $$OfflineTrackingPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientPointId => $composableBuilder(
    column: $table.clientPointId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paseoId => $composableBuilder(
    column: $table.paseoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineTrackingPointsTableOrderingComposer
    extends Composer<_$DogGoDatabase, $OfflineTrackingPointsTable> {
  $$OfflineTrackingPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientPointId => $composableBuilder(
    column: $table.clientPointId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paseoId => $composableBuilder(
    column: $table.paseoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineTrackingPointsTableAnnotationComposer
    extends Composer<_$DogGoDatabase, $OfflineTrackingPointsTable> {
  $$OfflineTrackingPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientPointId => $composableBuilder(
    column: $table.clientPointId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paseoId =>
      $composableBuilder(column: $table.paseoId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$OfflineTrackingPointsTableTableManager
    extends
        RootTableManager<
          _$DogGoDatabase,
          $OfflineTrackingPointsTable,
          OfflineTrackingPoint,
          $$OfflineTrackingPointsTableFilterComposer,
          $$OfflineTrackingPointsTableOrderingComposer,
          $$OfflineTrackingPointsTableAnnotationComposer,
          $$OfflineTrackingPointsTableCreateCompanionBuilder,
          $$OfflineTrackingPointsTableUpdateCompanionBuilder,
          (
            OfflineTrackingPoint,
            BaseReferences<
              _$DogGoDatabase,
              $OfflineTrackingPointsTable,
              OfflineTrackingPoint
            >,
          ),
          OfflineTrackingPoint,
          PrefetchHooks Function()
        > {
  $$OfflineTrackingPointsTableTableManager(
    _$DogGoDatabase db,
    $OfflineTrackingPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineTrackingPointsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OfflineTrackingPointsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineTrackingPointsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientPointId = const Value.absent(),
                Value<int> paseoId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineTrackingPointsCompanion(
                clientPointId: clientPointId,
                paseoId: paseoId,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                altitude: altitude,
                speed: speed,
                heading: heading,
                capturedAt: capturedAt,
                syncStatus: syncStatus,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientPointId,
                required int paseoId,
                required double latitude,
                required double longitude,
                Value<double?> accuracy = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                required DateTime capturedAt,
                Value<int> syncStatus = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineTrackingPointsCompanion.insert(
                clientPointId: clientPointId,
                paseoId: paseoId,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                altitude: altitude,
                speed: speed,
                heading: heading,
                capturedAt: capturedAt,
                syncStatus: syncStatus,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineTrackingPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$DogGoDatabase,
      $OfflineTrackingPointsTable,
      OfflineTrackingPoint,
      $$OfflineTrackingPointsTableFilterComposer,
      $$OfflineTrackingPointsTableOrderingComposer,
      $$OfflineTrackingPointsTableAnnotationComposer,
      $$OfflineTrackingPointsTableCreateCompanionBuilder,
      $$OfflineTrackingPointsTableUpdateCompanionBuilder,
      (
        OfflineTrackingPoint,
        BaseReferences<
          _$DogGoDatabase,
          $OfflineTrackingPointsTable,
          OfflineTrackingPoint
        >,
      ),
      OfflineTrackingPoint,
      PrefetchHooks Function()
    >;
typedef $$PendingWalkOperationsTableCreateCompanionBuilder =
    PendingWalkOperationsCompanion Function({
      required String clientOperationId,
      required int paseoId,
      required String operationType,
      Value<String> payloadJson,
      Value<int> syncStatus,
      Value<int> retryCount,
      Value<String?> lastError,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$PendingWalkOperationsTableUpdateCompanionBuilder =
    PendingWalkOperationsCompanion Function({
      Value<String> clientOperationId,
      Value<int> paseoId,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<int> syncStatus,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$PendingWalkOperationsTableFilterComposer
    extends Composer<_$DogGoDatabase, $PendingWalkOperationsTable> {
  $$PendingWalkOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paseoId => $composableBuilder(
    column: $table.paseoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingWalkOperationsTableOrderingComposer
    extends Composer<_$DogGoDatabase, $PendingWalkOperationsTable> {
  $$PendingWalkOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paseoId => $composableBuilder(
    column: $table.paseoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingWalkOperationsTableAnnotationComposer
    extends Composer<_$DogGoDatabase, $PendingWalkOperationsTable> {
  $$PendingWalkOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paseoId =>
      $composableBuilder(column: $table.paseoId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$PendingWalkOperationsTableTableManager
    extends
        RootTableManager<
          _$DogGoDatabase,
          $PendingWalkOperationsTable,
          PendingWalkOperation,
          $$PendingWalkOperationsTableFilterComposer,
          $$PendingWalkOperationsTableOrderingComposer,
          $$PendingWalkOperationsTableAnnotationComposer,
          $$PendingWalkOperationsTableCreateCompanionBuilder,
          $$PendingWalkOperationsTableUpdateCompanionBuilder,
          (
            PendingWalkOperation,
            BaseReferences<
              _$DogGoDatabase,
              $PendingWalkOperationsTable,
              PendingWalkOperation
            >,
          ),
          PendingWalkOperation,
          PrefetchHooks Function()
        > {
  $$PendingWalkOperationsTableTableManager(
    _$DogGoDatabase db,
    $PendingWalkOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingWalkOperationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingWalkOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingWalkOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientOperationId = const Value.absent(),
                Value<int> paseoId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingWalkOperationsCompanion(
                clientOperationId: clientOperationId,
                paseoId: paseoId,
                operationType: operationType,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientOperationId,
                required int paseoId,
                required String operationType,
                Value<String> payloadJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingWalkOperationsCompanion.insert(
                clientOperationId: clientOperationId,
                paseoId: paseoId,
                operationType: operationType,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingWalkOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$DogGoDatabase,
      $PendingWalkOperationsTable,
      PendingWalkOperation,
      $$PendingWalkOperationsTableFilterComposer,
      $$PendingWalkOperationsTableOrderingComposer,
      $$PendingWalkOperationsTableAnnotationComposer,
      $$PendingWalkOperationsTableCreateCompanionBuilder,
      $$PendingWalkOperationsTableUpdateCompanionBuilder,
      (
        PendingWalkOperation,
        BaseReferences<
          _$DogGoDatabase,
          $PendingWalkOperationsTable,
          PendingWalkOperation
        >,
      ),
      PendingWalkOperation,
      PrefetchHooks Function()
    >;
typedef $$CachedWalksTableCreateCompanionBuilder =
    CachedWalksCompanion Function({
      Value<int> paseoId,
      required String dataJson,
      Value<bool> isInList,
      Value<bool> hasDetail,
      required DateTime cachedAt,
    });
typedef $$CachedWalksTableUpdateCompanionBuilder =
    CachedWalksCompanion Function({
      Value<int> paseoId,
      Value<String> dataJson,
      Value<bool> isInList,
      Value<bool> hasDetail,
      Value<DateTime> cachedAt,
    });

class $$CachedWalksTableFilterComposer
    extends Composer<_$DogGoDatabase, $CachedWalksTable> {
  $$CachedWalksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get paseoId => $composableBuilder(
    column: $table.paseoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInList => $composableBuilder(
    column: $table.isInList,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasDetail => $composableBuilder(
    column: $table.hasDetail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWalksTableOrderingComposer
    extends Composer<_$DogGoDatabase, $CachedWalksTable> {
  $$CachedWalksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get paseoId => $composableBuilder(
    column: $table.paseoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInList => $composableBuilder(
    column: $table.isInList,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasDetail => $composableBuilder(
    column: $table.hasDetail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWalksTableAnnotationComposer
    extends Composer<_$DogGoDatabase, $CachedWalksTable> {
  $$CachedWalksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get paseoId =>
      $composableBuilder(column: $table.paseoId, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<bool> get isInList =>
      $composableBuilder(column: $table.isInList, builder: (column) => column);

  GeneratedColumn<bool> get hasDetail =>
      $composableBuilder(column: $table.hasDetail, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedWalksTableTableManager
    extends
        RootTableManager<
          _$DogGoDatabase,
          $CachedWalksTable,
          CachedWalk,
          $$CachedWalksTableFilterComposer,
          $$CachedWalksTableOrderingComposer,
          $$CachedWalksTableAnnotationComposer,
          $$CachedWalksTableCreateCompanionBuilder,
          $$CachedWalksTableUpdateCompanionBuilder,
          (
            CachedWalk,
            BaseReferences<_$DogGoDatabase, $CachedWalksTable, CachedWalk>,
          ),
          CachedWalk,
          PrefetchHooks Function()
        > {
  $$CachedWalksTableTableManager(_$DogGoDatabase db, $CachedWalksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWalksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWalksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedWalksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> paseoId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<bool> isInList = const Value.absent(),
                Value<bool> hasDetail = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedWalksCompanion(
                paseoId: paseoId,
                dataJson: dataJson,
                isInList: isInList,
                hasDetail: hasDetail,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> paseoId = const Value.absent(),
                required String dataJson,
                Value<bool> isInList = const Value.absent(),
                Value<bool> hasDetail = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedWalksCompanion.insert(
                paseoId: paseoId,
                dataJson: dataJson,
                isInList: isInList,
                hasDetail: hasDetail,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWalksTableProcessedTableManager =
    ProcessedTableManager<
      _$DogGoDatabase,
      $CachedWalksTable,
      CachedWalk,
      $$CachedWalksTableFilterComposer,
      $$CachedWalksTableOrderingComposer,
      $$CachedWalksTableAnnotationComposer,
      $$CachedWalksTableCreateCompanionBuilder,
      $$CachedWalksTableUpdateCompanionBuilder,
      (
        CachedWalk,
        BaseReferences<_$DogGoDatabase, $CachedWalksTable, CachedWalk>,
      ),
      CachedWalk,
      PrefetchHooks Function()
    >;

class $DogGoDatabaseManager {
  final _$DogGoDatabase _db;
  $DogGoDatabaseManager(this._db);
  $$OfflineTrackingPointsTableTableManager get offlineTrackingPoints =>
      $$OfflineTrackingPointsTableTableManager(_db, _db.offlineTrackingPoints);
  $$PendingWalkOperationsTableTableManager get pendingWalkOperations =>
      $$PendingWalkOperationsTableTableManager(_db, _db.pendingWalkOperations);
  $$CachedWalksTableTableManager get cachedWalks =>
      $$CachedWalksTableTableManager(_db, _db.cachedWalks);
}
