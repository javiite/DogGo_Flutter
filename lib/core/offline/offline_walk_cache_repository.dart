import 'dart:convert';

import '../database/doggo_database.dart';

class OfflineWalkCacheRepository {
  OfflineWalkCacheRepository({DogGoDatabase? database})
    : _database = database ?? DogGoDatabase.instance;

  final DogGoDatabase _database;

  Future<void> saveWalkList(Iterable<Map<String, dynamic>> walks) async {
    final records = <({int paseoId, String dataJson})>[];

    for (final walk in walks) {
      final paseoId = _readId(walk);
      if (paseoId == null || paseoId <= 0) continue;

      records.add((paseoId: paseoId, dataJson: jsonEncode(walk)));
    }

    await _database.replaceCachedWalkList(records);
  }

  Future<List<Map<String, dynamic>>> getWalkList() async {
    final rows = await _database.cachedWalkList();
    final walks = <Map<String, dynamic>>[];

    for (final row in rows) {
      final decoded = _decode(row.dataJson);
      if (decoded != null) walks.add(decoded);
    }

    return walks;
  }

  Future<void> saveWalkDetail(Map<String, dynamic> walk) async {
    final paseoId = _readId(walk);
    if (paseoId == null || paseoId <= 0) {
      throw const FormatException(
        'El paseo no contiene un identificador válido.',
      );
    }

    await _database.saveCachedWalkDetail(
      paseoId: paseoId,
      dataJson: jsonEncode(walk),
    );
  }

  Future<Map<String, dynamic>?> getWalkDetail(int paseoId) async {
    final row = await _database.cachedWalkDetail(paseoId);
    return row == null ? null : _decode(row.dataJson);
  }

  Map<String, dynamic>? _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  int? _readId(Map<String, dynamic> walk) {
    final value = walk['id'];

    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
