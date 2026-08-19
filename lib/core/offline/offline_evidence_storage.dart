import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'offline_tracking_models.dart';

class OfflineEvidenceStorage {
  OfflineEvidenceStorage({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<File> preserve({
    required int paseoId,
    required PendingWalkOperationType type,
    required File source,
  }) async {
    if (!await source.exists() || await source.length() == 0) {
      throw Exception('La evidencia seleccionada no existe o está vacía.');
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final evidenceDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}'
      'doggo_offline_evidence',
    );

    await evidenceDirectory.create(recursive: true);

    final extension = _safeExtension(source.path);
    final target = File(
      '${evidenceDirectory.path}${Platform.pathSeparator}'
      '${paseoId}_${type.storageValue}_${_uuid.v4()}$extension',
    );

    final copied = await source.copy(target.path);
    if (!await copied.exists() || await copied.length() == 0) {
      throw Exception('No se pudo conservar la evidencia en el dispositivo.');
    }

    return copied;
  }

  Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _safeExtension(String path) {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final separator = fileName.lastIndexOf('.');

    if (separator <= 0 || separator == fileName.length - 1) {
      return '.jpg';
    }

    final extension = fileName.substring(separator).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : '.jpg';
  }
}
