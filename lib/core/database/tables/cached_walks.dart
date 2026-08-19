import 'package:drift/drift.dart';

class CachedWalks extends Table {
  IntColumn get paseoId => integer()();

  TextColumn get dataJson => text()();

  BoolColumn get isInList => boolean().withDefault(const Constant(false))();

  BoolColumn get hasDetail => boolean().withDefault(const Constant(false))();

  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {paseoId};
}
