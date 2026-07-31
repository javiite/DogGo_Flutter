import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/api_exception.dart';
import '../../services/perros_service.dart';
import '../../services/storage_service.dart';
import 'models/pet.dart';
import 'pet_form_state.dart';

class PetFormResult {
  final bool success;
  final String message;
  final int? petId;
  final bool photoUploaded;

  const PetFormResult({
    required this.success,
    required this.message,
    this.petId,
    this.photoUploaded = false,
  });
}

class PetFormController extends ChangeNotifier {
  final ImagePicker _imagePicker;
  final Pet? initialPet;

  final TextEditingController nameController;
  final TextEditingController breedController;
  final TextEditingController ageController;
  final TextEditingController notesController;
  final TextEditingController photoUrlController;

  late PetFormState _state;
  bool _disposed = false;

  PetFormController({
    Map<String, dynamic>? initialData,
    ImagePicker? imagePicker,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        initialPet = initialData == null
            ? null
            : Pet.fromMap(initialData),
        nameController = TextEditingController(
          text: initialData == null
              ? ''
              : Pet.fromMap(initialData).name,
        ),
        breedController = TextEditingController(
          text: initialData == null
              ? ''
              : Pet.fromMap(initialData).breed,
        ),
        ageController = TextEditingController(
          text: initialData == null
              ? ''
              : Pet.fromMap(initialData).age?.toString() ??
                  '',
        ),
        notesController = TextEditingController(
          text: initialData == null
              ? ''
              : Pet.fromMap(initialData).notes,
        ),
        photoUrlController = TextEditingController(
          text: initialData == null
              ? ''
              : Pet.fromMap(initialData).photoPath ?? '',
        ) {
    final pet = initialPet;

    _state = PetFormState(
      mode: pet == null
          ? PetFormMode.create
          : PetFormMode.edit,
      loading: true,
      selectedSize: PetFormState.normalizeSize(
        pet?.size,
      ),
    );
  }

  PetFormState get state => _state;

  bool get isCreating => _state.isCreating;

  bool get isEditing => _state.isEditing;

  Future<void> initialize() async {
    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final baseUrl = await StorageService.obtenerBaseUrl();

      if (_disposed) return;

      final stateWithServer = _state.copyWith(
        baseUrl: baseUrl,
      );

      _setState(
        stateWithServer.copyWith(
          loading: false,
          currentPhotoUrl: stateWithServer.publicUrl(
            initialPet?.photoPath,
          ),
        ),
      );
    } catch (error) {
      if (_disposed) return;

      _setState(
        _state.copyWith(
          loading: false,
          error: _cleanError(error),
        ),
      );
    }
  }

  void setSize(String? size) {
    if (size == null ||
        !PetFormState.availableSizes.contains(size)) {
      return;
    }

    _setState(
      _state.copyWith(
        selectedSize: size,
      ),
    );
  }

  Future<bool> selectPhoto(ImageSource source) async {
    if (_state.saving) return false;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || _disposed) {
        return false;
      }

      photoUrlController.clear();

      _setState(
        _state.copyWith(
          selectedPhoto: File(image.path),
          clearError: true,
        ),
      );

      return true;
    } catch (error) {
      if (!_disposed) {
        _setState(
          _state.copyWith(
            error: _cleanError(error),
          ),
        );
      }

      return false;
    }
  }

  void removeSelectedPhoto() {
    _setState(
      _state.copyWith(
        clearSelectedPhoto: true,
      ),
    );
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(
      _state.copyWith(
        clearError: true,
      ),
    );
  }

  Future<PetFormResult> save() async {
    if (_state.saving) {
      return const PetFormResult(
        success: false,
        message: 'Ya se está guardando la mascota.',
      );
    }

    final age = int.tryParse(
      ageController.text.trim(),
    );

    if (age == null) {
      return const PetFormResult(
        success: false,
        message: 'La edad no es válida.',
      );
    }

    _setState(
      _state.copyWith(
        saving: true,
        clearError: true,
      ),
    );

    try {
      if (_state.isCreating) {
        return await _createPet(age);
      }

      return await _updatePet(age);
    } catch (error) {
      final message = _cleanError(error);

      if (!_disposed) {
        _setState(
          _state.copyWith(
            saving: false,
            error: message,
          ),
        );
      }

      return PetFormResult(
        success: false,
        message: message,
      );
    }
  }

  Future<PetFormResult> _createPet(int age) async {
    final response = await PerrosService.registrarPerro(
      nombre: nameController.text.trim(),
      raza: breedController.text.trim(),
      edad: age,
      tamano: _state.selectedSize,
      notas: notesController.text.trim(),
      fotoUrl: _manualPhotoUrl,
    );

    if (response['success'] != true) {
      throw Exception(
        _responseMessage(
          response,
          fallback:
              'No se pudo registrar la mascota.',
        ),
      );
    }

    final petId = _extractPetId(response['data']);
    final selectedPhoto = _state.selectedPhoto;

    var photoUploaded = false;
    var message = _responseMessage(
      response,
      fallback:
          'Mascota registrada correctamente.',
    );

    if (selectedPhoto != null) {
      if (petId == null) {
        message =
            'La mascota se registró, pero el servidor no devolvió su identificador para subir la fotografía.';
      } else {
        final photoResponse =
            await PerrosService.subirFotoPerro(
          id: petId,
          filePath: selectedPhoto.path,
        );

        if (photoResponse['success'] == true) {
          photoUploaded = true;
          message =
              'Mascota registrada con fotografía correctamente.';
        } else {
          message =
              'La mascota se registró, pero no se pudo subir la fotografía: '
              '${_responseMessage(photoResponse, fallback: 'Error desconocido.')}';
        }
      }
    }

    if (!_disposed) {
      _setState(
        _state.copyWith(
          saving: false,
          clearError: true,
        ),
      );
    }

    return PetFormResult(
      success: true,
      message: message,
      petId: petId,
      photoUploaded: photoUploaded,
    );
  }

  Future<PetFormResult> _updatePet(int age) async {
    final pet = initialPet;

    if (pet == null || !pet.hasValidId) {
      throw Exception(
        'No se encontró el identificador de la mascota.',
      );
    }

    final response = await PerrosService.editarPerro(
      id: pet.id,
      nombre: nameController.text.trim(),
      raza: breedController.text.trim(),
      edad: age,
      tamano: _state.selectedSize,
      notas: notesController.text.trim(),
      fotoUrl: _manualPhotoUrl,
    );

    if (response['success'] != true) {
      throw Exception(
        _responseMessage(
          response,
          fallback:
              'No se pudo actualizar la mascota.',
        ),
      );
    }

    final selectedPhoto = _state.selectedPhoto;

    var photoUploaded = false;
    var message = _responseMessage(
      response,
      fallback:
          'Mascota actualizada correctamente.',
    );

    if (selectedPhoto != null) {
      final photoResponse =
          await PerrosService.subirFotoPerro(
        id: pet.id,
        filePath: selectedPhoto.path,
      );

      if (photoResponse['success'] == true) {
        photoUploaded = true;
        message =
            'Mascota y fotografía actualizadas correctamente.';
      } else {
        message =
            'La mascota se actualizó, pero no se pudo subir la fotografía: '
            '${_responseMessage(photoResponse, fallback: 'Error desconocido.')}';
      }
    }

    if (!_disposed) {
      _setState(
        _state.copyWith(
          saving: false,
          clearError: true,
        ),
      );
    }

    return PetFormResult(
      success: true,
      message: message,
      petId: pet.id,
      photoUploaded: photoUploaded,
    );
  }

  String? get _manualPhotoUrl {
    if (_state.selectedPhoto != null) {
      return null;
    }

    final value = photoUrlController.text.trim();

    return value.isEmpty ? null : value;
  }

  String? validateName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Escribe el nombre de tu mascota.';
    }

    if (text.length < 2) {
      return 'Utiliza al menos 2 caracteres.';
    }

    if (text.length > 80) {
      return 'El nombre es demasiado largo.';
    }

    return null;
  }

  String? validateBreed(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Escribe la raza de tu mascota.';
    }

    if (text.length > 100) {
      return 'La raza es demasiado larga.';
    }

    return null;
  }

  String? validateAge(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Escribe la edad.';
    }

    final age = int.tryParse(text);

    if (age == null) {
      return 'Escribe un número entero.';
    }

    if (age < 0) {
      return 'La edad no puede ser negativa.';
    }

    if (age > 40) {
      return 'Revisa la edad ingresada.';
    }

    return null;
  }

  String? validateNotes(String? value) {
    final text = value?.trim() ?? '';

    if (text.length > 600) {
      return 'Las notas no pueden superar 600 caracteres.';
    }

    return null;
  }

  String? validatePhotoUrl(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty || _state.selectedPhoto != null) {
      return null;
    }

    final uri = Uri.tryParse(text);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Escribe una dirección http o https válida.';
    }

    return null;
  }

  int? _extractPetId(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is Map) {
      final candidates = [
        value['id'],
        value['Id'],
        value['perroId'],
        value['PerroId'],
        value['mascotaId'],
        value['MascotaId'],
      ];

      for (final candidate in candidates) {
        final id = candidate is int
            ? candidate
            : int.tryParse(
                candidate?.toString() ?? '',
              );

        if (id != null) return id;
      }

      final nested = value['data'] ??
          value['perro'] ??
          value['mascota'] ??
          value['resultado'] ??
          value['result'];

      if (nested != null && nested != value) {
        return _extractPetId(nested);
      }
    }

    return int.tryParse(value.toString());
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final value = response['message'] ??
        response['mensaje'] ??
        response['error'];

    final message = value?.toString().trim();

    if (message == null || message.isEmpty) {
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
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty
        ? 'No se pudo guardar la mascota.'
        : message;
  }

  void _setState(PetFormState newState) {
    if (_disposed) return;

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
    notesController.dispose();
    photoUrlController.dispose();

    super.dispose();
  }
}