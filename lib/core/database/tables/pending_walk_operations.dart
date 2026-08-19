import 'package:drift/drift.dart';

class PendingWalkOperations extends Table {
  TextColumn get clientOperationId => text()();

  IntColumn get paseoId => integer()();

  TextColumn get operationType => text()();

  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientOperationId};
}
