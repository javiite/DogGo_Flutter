import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/api_exception.dart';
import '../../services/storage_service.dart';
import '../../services/location_catalog_service.dart';
import '../../services/usuario_service.dart';
import 'edit_profile_state.dart';
import 'profile_state.dart';

class EditProfileController extends ChangeNotifier {
  final UsuarioService _usuarioService;
  final ImagePicker _imagePicker;
  final LocationCatalogService _locationCatalogService;
  final Map<String, dynamic> initialProfile;

  late final TextEditingController nameController;
  late final TextEditingController lastNameController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;
  late final TextEditingController referencesController;
  late final TextEditingController zoneController;
  late final TextEditingController descriptionController;
  late final TextEditingController preferencesController;

  EditProfileState _state = const EditProfileState();
  bool _disposed = false;

  EditProfileController({
    required this.initialProfile,
    UsuarioService? usuarioService,
    ImagePicker? imagePicker,
    LocationCatalogService? locationCatalogService,
  }) : _usuarioService = usuarioService ?? UsuarioService(),
       _locationCatalogService =
           locationCatalogService ?? LocationCatalogService(),
       _imagePicker = imagePicker ?? ImagePicker() {
    nameController = TextEditingController(
      text: _text(
        _value(initialProfile, const [
          'nombre',
          'Nombre',
          'name',
          'Name',
          'firstName',
          'FirstName',
        ]),
      ),
    );

    lastNameController = TextEditingController(
      text: _text(
        _value(initialProfile, const [
          'apellido',
          'Apellido',
          'lastName',
          'LastName',
        ]),
      ),
    );

    phoneController = TextEditingController(
      text: _text(
        _value(initialProfile, const [
          'telefono',
          'Telefono',
          'teléfono',
          'phone',
          'Phone',
        ]),
      ),
    );

    addressController = TextEditingController();
    referencesController = TextEditingController();
    zoneController = TextEditingController();
    descriptionController = TextEditingController();
    preferencesController = TextEditingController();
  }

  EditProfileState get state => _state;

  ProfileState get baseProfile {
    return ProfileState(user: initialProfile);
  }

  bool get isOwner => baseProfile.isOwner;

  bool get isWalker => baseProfile.isWalker;

  String get email => baseProfile.email;

  String get roleLabel => baseProfile.roleLabel;

  String get fullName {
    final fullName =
        '${nameController.text.trim()} '
                '${lastNameController.text.trim()}'
            .trim();

    return fullName.isEmpty ? 'Usuario DogGo' : fullName;
  }

  Future<void> initialize() async {
    _setState(_state.copyWith(loading: true, clearError: true));

    try {
      final baseUrl = await StorageService.obtenerBaseUrl();

      if (_disposed) return;

      _setState(_state.copyWith(baseUrl: baseUrl));

      if (isOwner) {
        await _loadStates();
        await _loadOwnerProfile();
      }

      if (_disposed) return;

      _setState(_state.copyWith(loading: false));
    } catch (error) {
      if (_disposed) return;

      _setState(_state.copyWith(loading: false, error: _cleanError(error)));
    }
  }

  Future<void> retry() {
    return initialize();
  }

  Future<void> _loadOwnerProfile() async {
    try {
      final profile = await _usuarioService.obtenerPerfilDuenio();

      if (_disposed) return;

      addressController.text = _text(
        _value(profile, const ['direccion', 'Direccion', 'address', 'Address']),
      );

      referencesController.text = _text(
        _value(profile, const [
          'referenciasDireccion',
          'ReferenciasDireccion',
          'referencias',
          'Referencias',
        ]),
      );

      zoneController.text = _text(
        _value(profile, const ['zona', 'Zona', 'zone', 'Zone']),
      );

      descriptionController.text = _text(
        _value(profile, const [
          'descripcion',
          'Descripcion',
          'descripción',
          'description',
          'Description',
        ]),
      );

      preferencesController.text = _text(
        _value(profile, const [
          'preferenciasPaseo',
          'PreferenciasPaseo',
          'preferencias',
          'Preferencias',
        ]),
      );

      final photo = _value(profile, const [
        'fotoUrl',
        'FotoUrl',
        'fotoPerfilUrl',
        'FotoPerfilUrl',
        'imagenUrl',
        'ImagenUrl',
        'foto',
        'Foto',
      ]);

      final latitude = EditProfileState.safeDouble(
        _value(profile, const ['latitud', 'Latitud', 'latitude', 'Latitude']),
      );

      final longitude = EditProfileState.safeDouble(
        _value(profile, const [
          'longitud',
          'Longitud',
          'longitude',
          'Longitude',
        ]),
      );

      final stateCode = _text(
        _value(profile, const ['estadoClave', 'EstadoClave']),
      );
      final municipalityCode = _text(
        _value(profile, const ['municipioClave', 'MunicipioClave']),
      );

      if (stateCode.isNotEmpty) {
        await _loadMunicipalities(
          stateCode,
          selectedMunicipalityCode: municipalityCode,
        );
      }

      _setState(
        _state.copyWith(
          currentPhotoUrl: _state.publicUrl(photo),
          latitude: latitude,
          longitude: longitude,
          ownerProfileLoaded: true,
          selectedStateCode: stateCode.isEmpty ? null : stateCode,
          selectedMunicipalityCode: municipalityCode.isEmpty
              ? null
              : municipalityCode,
        ),
      );
    } catch (error) {
      if (_disposed) return;

      _setState(
        _state.copyWith(ownerProfileLoaded: false, error: _cleanError(error)),
      );
    }
  }

  Future<void> _loadStates() async {
    final states = await _locationCatalogService.getStates();
    if (!_disposed) _setState(_state.copyWith(states: states));
  }

  Future<void> selectState(String? code) async {
    if (code == null || code == _state.selectedStateCode) return;
    _setState(
      _state.copyWith(
        selectedStateCode: code,
        clearSelectedMunicipality: true,
        municipalities: const [],
        loadingMunicipalities: true,
        clearError: true,
      ),
    );
    await _loadMunicipalities(code);
  }

  void selectMunicipality(String? code) {
    if (code == null) return;
    final municipality = _state.municipalities
        .where((item) => item.code == code)
        .firstOrNull;
    if (municipality != null) zoneController.text = municipality.name;
    _setState(
      _state.copyWith(selectedMunicipalityCode: code, clearError: true),
    );
  }

  Future<void> _loadMunicipalities(
    String stateCode, {
    String? selectedMunicipalityCode,
  }) async {
    try {
      final municipalities = await _locationCatalogService.getMunicipalities(
        stateCode,
      );
      if (_disposed) return;
      final validSelection =
          municipalities.any((item) => item.code == selectedMunicipalityCode)
          ? selectedMunicipalityCode
          : null;
      _setState(
        _state.copyWith(
          municipalities: municipalities,
          selectedStateCode: stateCode,
          selectedMunicipalityCode: validSelection,
          clearSelectedMunicipality: validSelection == null,
          loadingMunicipalities: false,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) return;
      _setState(
        _state.copyWith(
          loadingMunicipalities: false,
          error: _cleanError(error),
        ),
      );
    }
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

      _setState(
        _state.copyWith(selectedPhoto: File(image.path), clearError: true),
      );

      return true;
    } catch (error) {
      if (!_disposed) {
        _setState(_state.copyWith(error: _cleanError(error)));
      }

      return false;
    }
  }

  void removeSelectedPhoto() {
    _setState(_state.copyWith(clearSelectedPhoto: true));
  }

  void setLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _setState(
        _state.copyWith(error: 'La ubicación seleccionada no es válida.'),
      );
      return;
    }

    final cleanAddress = address?.trim() ?? '';

    if (cleanAddress.isNotEmpty) {
      addressController.text = cleanAddress;
    }

    _setState(
      _state.copyWith(
        latitude: latitude,
        longitude: longitude,
        clearError: true,
      ),
    );
  }

  void clearLocation() {
    _setState(_state.copyWith(clearLocation: true));
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(_state.copyWith(clearError: true));
  }

  Future<bool> save() async {
    if (_state.saving) return false;

    _setState(_state.copyWith(saving: true, clearError: true));

    try {
      await _usuarioService.actualizarPerfil(
        nombre: nameController.text.trim(),
        apellido: lastNameController.text.trim(),
        telefono: phoneController.text.trim(),
      );

      if (isOwner) {
        final selectedPhoto = _state.selectedPhoto;

        if (selectedPhoto != null) {
          await _usuarioService.subirFotoPerfilDuenio(selectedPhoto);
        }

        await _usuarioService.actualizarPerfilDuenio(
          direccion: addressController.text.trim(),
          referenciasDireccion: referencesController.text.trim(),
          zona: zoneController.text.trim(),
          latitud: _state.latitude,
          longitud: _state.longitude,
          descripcion: descriptionController.text.trim(),
          preferenciasPaseo: preferencesController.text.trim(),
          estadoClave: _state.selectedStateCode,
          municipioClave: _state.selectedMunicipalityCode,
        );
      }

      if (_disposed) return false;

      _setState(_state.copyWith(saving: false, clearError: true));

      return true;
    } catch (error) {
      if (_disposed) return false;

      _setState(_state.copyWith(saving: false, error: _cleanError(error)));

      return false;
    }
  }

  String? validateName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'El nombre es obligatorio.';
    }

    if (text.length < 2) {
      return 'Escribe al menos 2 caracteres.';
    }

    if (text.length > 80) {
      return 'El nombre es demasiado largo.';
    }

    return null;
  }

  String? validateLastName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'El apellido es obligatorio.';
    }

    if (text.length < 2) {
      return 'Escribe al menos 2 caracteres.';
    }

    if (text.length > 80) {
      return 'El apellido es demasiado largo.';
    }

    return null;
  }

  String? validatePhone(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'El teléfono es obligatorio.';
    }

    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 8) {
      return 'El teléfono es demasiado corto.';
    }

    if (digits.length > 15) {
      return 'El teléfono es demasiado largo.';
    }

    return null;
  }

  String? validateOptionalText(String? value, {int maximumLength = 500}) {
    final text = value?.trim() ?? '';

    if (text.length > maximumLength) {
      return 'El texto no puede superar '
          '$maximumLength caracteres.';
    }

    return null;
  }

  dynamic _value(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _text(dynamic value) {
    if (value == null) return '';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }

    return text;
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

    return message.isEmpty ? 'No se pudo actualizar el perfil.' : message;
  }

  void _setState(EditProfileState newState) {
    if (_disposed) return;

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    nameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    referencesController.dispose();
    zoneController.dispose();
    descriptionController.dispose();
    preferencesController.dispose();

    super.dispose();
  }
}
