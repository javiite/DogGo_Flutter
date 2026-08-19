import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/api_exception.dart';
import '../../services/paseadores_service.dart';
import '../../services/location_catalog_service.dart';
import '../../services/storage_service.dart';
import 'edit_walker_profile_state.dart';

class EditWalkerProfileController extends ChangeNotifier {
  final ImagePicker _imagePicker;
  final LocationCatalogService _locationCatalogService;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController zoneController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  EditWalkerProfileState _state = const EditWalkerProfileState();

  bool _disposed = false;

  EditWalkerProfileController({
    ImagePicker? imagePicker,
    LocationCatalogService? locationCatalogService,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _locationCatalogService =
           locationCatalogService ?? LocationCatalogService();

  EditWalkerProfileState get state => _state;

  bool get profileComplete {
    final rate = double.tryParse(
      rateController.text.trim().replaceAll(',', '.'),
    );

    final experience = int.tryParse(experienceController.text.trim());

    return descriptionController.text.trim().isNotEmpty &&
        zoneController.text.trim().isNotEmpty &&
        rate != null &&
        rate > 0 &&
        experience != null &&
        experience >= 0 &&
        _state.hasPhoto;
  }

  int get completionPercentage {
    var completed = 0;

    if (descriptionController.text.trim().length >= 20) {
      completed++;
    }

    if (zoneController.text.trim().isNotEmpty) {
      completed++;
    }

    final rate = double.tryParse(
      rateController.text.trim().replaceAll(',', '.'),
    );

    if (rate != null && rate > 0) {
      completed++;
    }

    final experience = int.tryParse(experienceController.text.trim());

    if (experience != null && experience >= 0) {
      completed++;
    }

    if (_state.hasPhoto) {
      completed++;
    }

    return ((completed / 5) * 100).round();
  }

  Future<void> initialize() async {
    _setState(_state.copyWith(loading: true, clearError: true));

    try {
      final baseUrl = await StorageService.obtenerBaseUrl();

      if (_disposed) return;

      _setState(_state.copyWith(baseUrl: baseUrl));

      final states = await _locationCatalogService.getStates();
      if (_disposed) return;
      _setState(_state.copyWith(states: states));
      await _loadProfile();
    } catch (error) {
      if (_disposed) return;

      _setState(_state.copyWith(loading: false, error: _cleanError(error)));
    }
  }

  Future<void> retry() {
    return initialize();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await PaseadoresService.obtenerMiPerfilPaseador();

      if (_disposed) return;

      descriptionController.text = _text(
        _value(profile, const [
          'descripcion',
          'Descripcion',
          'descripción',
          'bio',
          'Bio',
        ]),
      );

      zoneController.text = _text(
        _value(profile, const [
          'zonaServicio',
          'ZonaServicio',
          'zona',
          'Zona',
          'serviceZone',
          'ServiceZone',
        ]),
      );

      final stateCode = _text(
        _value(profile, const ['estadoClave', 'EstadoClave']),
      );
      final municipalityCode = _text(
        _value(profile, const ['municipioClave', 'MunicipioClave']),
      );
      final radius =
          int.tryParse(
            _text(
              _value(profile, const ['radioServicioKm', 'RadioServicioKm']),
            ),
          ) ??
          10;
      final latitude = double.tryParse(
        _text(_value(profile, const ['latitud', 'Latitud'])),
      );
      final longitude = double.tryParse(
        _text(_value(profile, const ['longitud', 'Longitud'])),
      );

      if (stateCode.isNotEmpty) {
        await _loadMunicipalities(stateCode);
      }

      rateController.text = EditWalkerProfileState.decimalText(
        _value(profile, const [
          'tarifaPorHora',
          'TarifaPorHora',
          'tarifa',
          'Tarifa',
          'hourlyRate',
          'HourlyRate',
        ]),
      );

      experienceController.text = EditWalkerProfileState.integerText(
        _value(profile, const [
          'experienciaAnios',
          'ExperienciaAnios',
          'experienciaAños',
          'ExperienciaAños',
          'experiencia',
          'Experiencia',
          'experienceYears',
          'ExperienceYears',
        ]),
      );

      final available = EditWalkerProfileState.safeBool(
        _value(profile, const [
          'disponible',
          'Disponible',
          'available',
          'Available',
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

      _setState(
        _state.copyWith(
          loading: false,
          available: available,
          currentPhotoUrl: _state.publicUrl(photo),
          profileLoaded: true,
          selectedStateCode: stateCode.isEmpty ? null : stateCode,
          selectedMunicipalityCode: municipalityCode.isEmpty
              ? null
              : municipalityCode,
          serviceRadiusKm: radius.clamp(1, 100),
          latitude: latitude,
          longitude: longitude,
          clearError: true,
        ),
      );
      if (latitude == null &&
          longitude == null &&
          municipalityCode.isNotEmpty) {
        final municipality = _state.municipalities
            .where((item) => item.code == municipalityCode)
            .firstOrNull;
        if (municipality != null) {
          await _locateMunicipality(municipality.name);
        }
      }
    } catch (error) {
      if (_disposed) return;

      _setState(
        _state.copyWith(
          loading: false,
          profileLoaded: false,
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

  void setAvailable(bool value) {
    _setState(_state.copyWith(available: value));
  }

  Future<void> selectState(String? code) async {
    if (code == null || code == _state.selectedStateCode) return;
    _setState(
      _state.copyWith(
        selectedStateCode: code,
        clearSelectedMunicipality: true,
        municipalities: const [],
      ),
    );
    await _loadMunicipalities(code);
  }

  void selectMunicipality(String? code) {
    final municipality = _state.municipalities
        .where((item) => item.code == code)
        .firstOrNull;
    zoneController.text = municipality?.name ?? '';
    _setState(
      _state.copyWith(
        selectedMunicipalityCode: code,
        clearSelectedMunicipality: code == null,
      ),
    );
    if (municipality != null) {
      _locateMunicipality(municipality.name);
    }
  }

  Future<void> _locateMunicipality(String municipalityName) async {
    final stateName = _state.states
        .where((item) => item.code == _state.selectedStateCode)
        .firstOrNull
        ?.name;
    if (stateName == null) return;
    _setState(_state.copyWith(locatingCoverage: true));
    try {
      final point = await _locationCatalogService.geocodeMunicipality(
        municipality: municipalityName,
        state: stateName,
      );
      if (_disposed) return;
      _setState(
        _state.copyWith(
          latitude: point?.latitude,
          longitude: point?.longitude,
          clearLatitude: point == null,
          clearLongitude: point == null,
          locatingCoverage: false,
        ),
      );
    } catch (_) {
      if (_disposed) return;
      _setState(_state.copyWith(locatingCoverage: false));
    }
  }

  void setCoverageCenter(double latitude, double longitude) {
    _setState(_state.copyWith(latitude: latitude, longitude: longitude));
  }

  void setServiceRadius(double value) {
    _setState(_state.copyWith(serviceRadiusKm: value.round()));
  }

  Future<void> _loadMunicipalities(String stateCode) async {
    _setState(_state.copyWith(loadingMunicipalities: true));
    try {
      final items = await _locationCatalogService.getMunicipalities(stateCode);
      if (_disposed) return;
      _setState(
        _state.copyWith(municipalities: items, loadingMunicipalities: false),
      );
    } catch (_) {
      if (_disposed) return;
      _setState(
        _state.copyWith(
          loadingMunicipalities: false,
          error: 'No pudimos cargar los municipios.',
        ),
      );
    }
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(_state.copyWith(clearError: true));
  }

  Future<bool> save() async {
    if (_state.saving) return false;

    final rate = double.tryParse(
      rateController.text.trim().replaceAll(',', '.'),
    );

    final experience = int.tryParse(experienceController.text.trim());

    if (rate == null || experience == null) {
      _setState(
        _state.copyWith(error: 'Revisa la tarifa y los años de experiencia.'),
      );

      return false;
    }

    if (_state.selectedStateCode == null ||
        _state.selectedMunicipalityCode == null) {
      _setState(
        _state.copyWith(
          error: 'Selecciona el estado y municipio donde darás servicio.',
        ),
      );
      return false;
    }

    _setState(_state.copyWith(saving: true, clearError: true));

    try {
      await PaseadoresService.guardarMiPerfilPaseador(
        descripcion: descriptionController.text.trim(),
        zonaServicio: zoneController.text.trim(),
        tarifaPorHora: rate,
        experienciaAnios: experience,
        disponible: _state.available,
        estadoClave: _state.selectedStateCode!,
        municipioClave: _state.selectedMunicipalityCode!,
        radioServicioKm: _state.serviceRadiusKm,
        latitud: _state.latitude,
        longitud: _state.longitude,
      );

      final selectedPhoto = _state.selectedPhoto;

      if (selectedPhoto != null) {
        await PaseadoresService.subirFotoMiPerfilPaseador(selectedPhoto);
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

  String? validateDescription(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Escribe una descripción.';
    }

    if (text.length < 20) {
      return 'Utiliza al menos 20 caracteres.';
    }

    if (text.length > 500) {
      return 'No puede superar 500 caracteres.';
    }

    return null;
  }

  String? validateZone(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Escribe tu zona de servicio.';
    }

    if (text.length > 100) {
      return 'No puede superar 100 caracteres.';
    }

    return null;
  }

  String? validateRate(String? value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';

    if (text.isEmpty) {
      return 'Escribe tu tarifa por hora.';
    }

    final number = double.tryParse(text);

    if (number == null) {
      return 'Escribe una tarifa válida.';
    }

    if (number <= 0) {
      return 'La tarifa debe ser mayor que cero.';
    }

    if (number > 100000) {
      return 'La tarifa es demasiado alta.';
    }

    return null;
  }

  String? validateExperience(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Escribe tus años de experiencia.';
    }

    final number = int.tryParse(text);

    if (number == null) {
      return 'Escribe un número entero.';
    }

    if (number < 0) {
      return 'La experiencia no puede ser negativa.';
    }

    if (number > 80) {
      return 'La experiencia no puede superar 80 años.';
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

    return message.isEmpty
        ? 'No se pudo guardar el perfil de paseador.'
        : message;
  }

  void _setState(EditWalkerProfileState newState) {
    if (_disposed) return;

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    descriptionController.dispose();
    zoneController.dispose();
    rateController.dispose();
    experienceController.dispose();

    super.dispose();
  }
}
