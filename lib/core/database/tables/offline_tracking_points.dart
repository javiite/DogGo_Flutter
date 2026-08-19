import 'package:drift/drift.dart';

class OfflineTrackingPoints extends Table {
  TextColumn get clientPointId => text()();

  IntColumn get paseoId => integer()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  RealColumn get accuracy => real().nullable()();

  RealColumn get altitude => real().nullable()();

  RealColumn get speed => real().nullable()();

  RealColumn get heading => real().nullable()();

  DateTimeColumn get capturedAt => dateTime()();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientPointId};
}
