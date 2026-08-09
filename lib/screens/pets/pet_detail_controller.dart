import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/api_exception.dart';
import '../../services/perros_service.dart';
import '../../services/storage_service.dart';
import 'models/pet.dart';
import 'models/pet_photo.dart';
import 'pet_detail_state.dart';

class PetGalleryResult {
  final bool success;
  final String message;

  const PetGalleryResult({
    required this.success,
    required this.message,
  });

  const PetGalleryResult.success(
    this.message,
  ) : success = true;

  const PetGalleryResult.failure(
    this.message,
  ) : success = false;
}

class PetDetailController
    extends ChangeNotifier {
  final Pet initialPet;
  final ImagePicker _imagePicker;

  late PetDetailState _state;

  bool _disposed = false;
  bool _requestInProgress = false;
  bool _galleryActionInProgress = false;

  PetDetailController({
    required Map<String, dynamic> initialData,
    ImagePicker? imagePicker,
  })  : initialPet = Pet.fromMap(initialData),
        _imagePicker =
            imagePicker ?? ImagePicker() {
    _state = PetDetailState(
      loading: true,
      pet: initialPet,
    );
  }

  PetDetailState get state => _state;

  Future<void> initialize() {
    return loadDetail();
  }

  Future<void> refresh() {
    return loadDetail();
  }

  Future<void> markChangedAndRefresh() async {
    _setState(
      _state.copyWith(
        changed: true,
      ),
    );

    await loadDetail();
  }

  Future<void> loadDetail() async {
    if (_requestInProgress) {
      return;
    }

    if (!initialPet.hasValidId) {
      _setState(
        _state.copyWith(
          loading: false,
          error:
              'No se encontró el identificador de la mascota.',
        ),
      );
      return;
    }

    _requestInProgress = true;

    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final results =
          await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        PerrosService.obtenerPerroPorId(
          initialPet.id,
        ),
      ]);

      if (_disposed) {
        return;
      }

      final baseUrl =
          results[0]?.toString();

      final response =
          _asMap(results[1]);

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback:
                'No se pudo cargar la información de la mascota.',
          ),
        );
      }

      final detailMap =
          _asMap(response['data']);

      if (detailMap.isEmpty) {
        throw Exception(
          'El servidor no devolvió información de la mascota.',
        );
      }

      _setState(
        PetDetailState(
          loading: false,
          galleryBusy:
              _state.galleryBusy,
          actingPhotoId:
              _state.actingPhotoId,
          baseUrl: baseUrl,
          pet: Pet.fromMap(detailMap),
          changed: _state.changed,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          error: _cleanError(error),
        ),
      );
    } finally {
      _requestInProgress = false;
    }
  }

  Future<PetGalleryResult?> addPhoto({
  bool makePrimary = false,
}) async {
  if (_galleryActionInProgress ||
      !_state.canAddPhoto) {
    return const PetGalleryResult.failure(
      'Espera a que termine la acción actual.',
    );
  }

  List<XFile> images;

  try {
    images =
        await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1800,
      maxHeight: 1800,
    );
  } catch (error) {
    return PetGalleryResult.failure(
      _cleanError(error),
    );
  }

  if (images.isEmpty) {
    return null;
  }

  final currentCount =
      _state.pet?.photoCount ?? 0;

  final availableSlots =
      8 - currentCount;

  if (availableSlots <= 0) {
    return const PetGalleryResult.failure(
      'La galería ya tiene el máximo de 8 fotografías.',
    );
  }

  final selectedImages = images
      .take(availableSlots)
      .toList(growable: false);

  _galleryActionInProgress = true;

  _setState(
    _state.copyWith(
      galleryBusy: true,
      clearActingPhoto: true,
      clearError: true,
    ),
  );

  var uploadedCount = 0;
  String? uploadError;

  try {
    for (final image in selectedImages) {
      final response =
          await PerrosService
              .agregarFotoGaleria(
        id: initialPet.id,
        filePath: image.path,
        hacerPrincipal:
            makePrimary &&
                uploadedCount == 0,
      );

      if (response['success'] != true) {
        uploadError = _responseMessage(
          response,
          fallback:
              'No se pudo subir una de las fotografías.',
        );

        break;
      }

      final detailMap =
          _asMap(response['data']);

      if (detailMap.isNotEmpty &&
          !_disposed) {
        _setState(
          _state.copyWith(
            pet: Pet.fromMap(detailMap),
            changed: true,
          ),
        );
      }

      uploadedCount++;
    }

    if (uploadedCount == 0) {
      return PetGalleryResult.failure(
        uploadError ??
            'No se pudo agregar ninguna fotografía.',
      );
    }

    final omittedCount =
        images.length -
            selectedImages.length;

    if (uploadError != null) {
      return PetGalleryResult.success(
        uploadedCount == 1
            ? 'Se guardó 1 fotografía. '
                'Otra imagen no pudo subirse: '
                '$uploadError'
            : 'Se guardaron $uploadedCount '
                'fotografías. Otra imagen no '
                'pudo subirse: $uploadError',
      );
    }

    if (omittedCount > 0) {
      return PetGalleryResult.success(
        'Se guardaron $uploadedCount '
        'fotografías. Se omitieron '
        '$omittedCount porque la galería '
        'admite un máximo de 8.',
      );
    }

    return PetGalleryResult.success(
      uploadedCount == 1
          ? 'Fotografía agregada correctamente.'
          : '$uploadedCount fotografías '
              'agregadas correctamente.',
    );
  } catch (error) {
    if (uploadedCount > 0) {
      return PetGalleryResult.success(
        'Se guardaron $uploadedCount '
        'fotografías antes de que ocurriera '
        'un problema.',
      );
    }

    return PetGalleryResult.failure(
      _cleanError(error),
    );
  } finally {
    _galleryActionInProgress = false;

    if (!_disposed) {
      _setState(
        _state.copyWith(
          galleryBusy: false,
          clearActingPhoto: true,
        ),
      );
    }
  }
}

  Future<PetGalleryResult> makePrimary(
    PetPhoto photo,
  ) {
    if (!photo.hasValidId) {
      return Future.value(
        const PetGalleryResult.failure(
          'Esta fotografía todavía no puede modificarse.',
        ),
      );
    }

    return _runGalleryAction(
      photoId: photo.id,
      action: () =>
          PerrosService.marcarFotoPrincipal(
        id: initialPet.id,
        fotoId: photo.id,
      ),
      fallback:
          'No se pudo cambiar la portada.',
    );
  }

  Future<PetGalleryResult> deletePhoto(
    PetPhoto photo,
  ) {
    if (!photo.hasValidId) {
      return Future.value(
        const PetGalleryResult.failure(
          'Esta fotografía todavía no puede eliminarse.',
        ),
      );
    }

    return _runGalleryAction(
      photoId: photo.id,
      action: () =>
          PerrosService.eliminarFotoGaleria(
        id: initialPet.id,
        fotoId: photo.id,
      ),
      fallback:
          'No se pudo eliminar la fotografía.',
    );
  }

  Future<PetGalleryResult>
      _runGalleryAction({
    required Future<Map<String, dynamic>>
        Function() action,
    required String fallback,
    int? photoId,
  }) async {
    if (_galleryActionInProgress) {
      return const PetGalleryResult.failure(
        'Espera a que termine la acción actual.',
      );
    }

    _galleryActionInProgress = true;

    _setState(
      _state.copyWith(
        galleryBusy: true,
        actingPhotoId: photoId,
        clearActingPhoto: photoId == null,
        clearError: true,
      ),
    );

    try {
      final response = await action();

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback: fallback,
          ),
        );
      }

      final detailMap =
          _asMap(response['data']);

      if (detailMap.isNotEmpty &&
          !_disposed) {
        _setState(
          _state.copyWith(
            pet: Pet.fromMap(detailMap),
            changed: true,
          ),
        );
      } else {
        await loadDetail();

        if (!_disposed) {
          _setState(
            _state.copyWith(
              changed: true,
            ),
          );
        }
      }

      return PetGalleryResult.success(
        _responseMessage(
          response,
          fallback:
              'Galería actualizada.',
        ),
      );
    } catch (error) {
      return PetGalleryResult.failure(
        _cleanError(error),
      );
    } finally {
      _galleryActionInProgress = false;

      if (!_disposed) {
        _setState(
          _state.copyWith(
            galleryBusy: false,
            clearActingPhoto: true,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _asMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final value =
        response['message'] ??
            response['mensaje'] ??
            response['error'];

    final message =
        value?.toString().trim();

    if (message == null ||
        message.isEmpty) {
      return fallback;
    }

    return message;
  }

  String _cleanError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst(
          'ApiException: ',
          '',
        )
        .trim();

    return message.isEmpty
        ? 'No se pudo actualizar la galería.'
        : message;
  }

  void _setState(
    PetDetailState newState,
  ) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}