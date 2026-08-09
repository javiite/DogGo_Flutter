import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/places_cache_service.dart';
import '../../services/places_preferences_service.dart';
import '../../services/places_profile_location_service.dart';
import '../../services/places_service.dart';
import '../../theme/doggo_theme.dart';
import '../seleccionar_ubicacion_screen.dart';
import 'models/place_item.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() =>
      _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final PlacesProfileLocationService
      _profileLocationService =
      PlacesProfileLocationService();

  Map<String, dynamic>? _selectedLocation;

  PlaceCategory _selectedCategory =
      PlaceCategory.veterinary;

  List<PlaceItem> _places = const [];

  bool _restoringLocation = true;
  bool _resolvingProfileLocation = false;
  bool _loading = false;
  bool _updatingInBackground = false;

  String? _errorMessage;
  String? _cacheLabel;

  static const List<_CategoryAppearance>
      _categories = [
    _CategoryAppearance(
      category: PlaceCategory.parks,
      title: 'Parques',
      icon: Icons.park_outlined,
      color: DogGoTheme.green,
      background: DogGoTheme.greenLight,
    ),
    _CategoryAppearance(
      category: PlaceCategory.veterinary,
      title: 'Veterinarias',
      icon: Icons.local_hospital_outlined,
      color: DogGoTheme.red,
      background: DogGoTheme.redLight,
    ),
    _CategoryAppearance(
      category: PlaceCategory.stores,
      title: 'Tiendas',
      icon: Icons.storefront_outlined,
      color: DogGoTheme.orange,
      background: DogGoTheme.orangeLight,
    ),
    _CategoryAppearance(
      category: PlaceCategory.petFriendly,
      title: 'Pet friendly',
      icon: Icons.pets_outlined,
      color: DogGoTheme.purple,
      background: DogGoTheme.purpleLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _restorePreferences();
  }

  double? get _latitude {
    return _toDouble(
      _selectedLocation?['latitud'],
    );
  }

  double? get _longitude {
    return _toDouble(
      _selectedLocation?['longitud'],
    );
  }

  bool get _locationBusy {
    return _restoringLocation ||
        _resolvingProfileLocation;
  }

  String get _locationText {
    final location = _selectedLocation;

    if (location == null) {
      return 'Selecciona una zona para buscar lugares cercanos';
    }

    final value =
        location['texto'] ??
        location['ubicacionTexto'] ??
        location['direccionRecogida'];

    final text = value?.toString().trim() ?? '';

    return text.isEmpty
        ? 'Ubicación seleccionada'
        : text;
  }

  String get _categoryTitle {
    return _categories
        .firstWhere(
          (item) =>
              item.category == _selectedCategory,
        )
        .title;
  }

  Future<void> _restorePreferences() async {
    final savedLocation =
        await PlacesPreferencesService.getLocation();

    final savedCategory =
        await PlacesPreferencesService.getCategory();

    Map<String, dynamic>? initialLocation =
        savedLocation;

    if (initialLocation == null) {
      initialLocation = await _profileLocationService
          .getDefaultPickupLocation();

      if (initialLocation != null) {
        final latitude = _toDouble(
          initialLocation['latitud'],
        );

        final longitude = _toDouble(
          initialLocation['longitud'],
        );

        if (latitude != null && longitude != null) {
          await PlacesPreferencesService.saveLocation(
            latitude: latitude,
            longitude: longitude,
            locationText:
                initialLocation['texto']?.toString() ??
                    'Ubicación de recogida',
          );
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLocation = initialLocation;
      _selectedCategory = savedCategory;
      _restoringLocation = false;
    });

    if (initialLocation != null) {
      await _loadPlaces();
    }
  }

  Future<void> _showLocationOptions() async {
    if (_locationBusy) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(27),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DogGoTheme.border,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ubicación para explorar',
                        style: DogGoTheme.title(size: 19),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _LocationOption(
                  icon: Icons.home_work_outlined,
                  title:
                      'Usar dirección de recogida',
                  subtitle:
                      'Toma la ubicación guardada en tu perfil.',
                  color: DogGoTheme.teal,
                  background: DogGoTheme.tealLight,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _useDefaultPickupLocation();
                  },
                ),
                const SizedBox(height: 10),
                _LocationOption(
                  icon: Icons.edit_location_alt_outlined,
                  title: 'Elegir otra ubicación',
                  subtitle:
                      'Busca una dirección o selecciona un punto.',
                  color: DogGoTheme.orange,
                  background: DogGoTheme.orangeLight,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _selectLocation();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _useDefaultPickupLocation() async {
    if (_resolvingProfileLocation) {
      return;
    }

    setState(() {
      _resolvingProfileLocation = true;
    });

    final location = await _profileLocationService
        .getDefaultPickupLocation();

    if (!mounted) {
      return;
    }

    if (location == null) {
      setState(() {
        _resolvingProfileLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu perfil todavía no tiene una ubicación de recogida guardada.',
          ),
        ),
      );

      return;
    }

    final latitude =
        _toDouble(location['latitud']);

    final longitude =
        _toDouble(location['longitud']);

    if (latitude == null || longitude == null) {
      setState(() {
        _resolvingProfileLocation = false;
      });

      return;
    }

    final locationText =
        location['texto']?.toString() ??
            'Ubicación de recogida';

    await PlacesPreferencesService.saveLocation(
      latitude: latitude,
      longitude: longitude,
      locationText: locationText,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLocation = {
        'latitud': latitude,
        'longitud': longitude,
        'texto': locationText,
        'origen': 'perfil',
      };

      _places = const [];
      _cacheLabel = null;
      _errorMessage = null;
      _resolvingProfileLocation = false;
    });

    await _loadPlaces();
  }

  Future<void> _selectLocation() async {
    final result =
        await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) =>
            const SeleccionarUbicacionScreen(),
      ),
    );

    if (!mounted || result is! Map) {
      return;
    }

    final location =
        Map<String, dynamic>.from(result);

    final latitude =
        _toDouble(location['latitud']);

    final longitude =
        _toDouble(location['longitud']);

    if (latitude == null || longitude == null) {
      return;
    }

    final locationText = (
      location['texto'] ??
      location['ubicacionTexto'] ??
      'Ubicación seleccionada'
    ).toString();

    await PlacesPreferencesService.saveLocation(
      latitude: latitude,
      longitude: longitude,
      locationText: locationText,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLocation = {
        'latitud': latitude,
        'longitud': longitude,
        'texto': locationText,
        'origen': 'personalizada',
      };

      _places = const [];
      _cacheLabel = null;
      _errorMessage = null;
    });

    await _loadPlaces();
  }

  Future<void> _selectCategory(
    PlaceCategory category,
  ) async {
    if (_selectedCategory == category) {
      return;
    }

    await PlacesPreferencesService.saveCategory(
      category,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCategory = category;
      _places = const [];
      _cacheLabel = null;
      _errorMessage = null;
    });

    if (_selectedLocation != null) {
      await _loadPlaces();
    }
  }

  Future<void> _loadPlaces({
    bool forceRefresh = false,
  }) async {
    final latitude = _latitude;
    final longitude = _longitude;

    if (latitude == null ||
        longitude == null ||
        _loading ||
        _updatingInBackground) {
      return;
    }

    var hasCachedResults = false;

    if (!forceRefresh) {
      final cacheEntry =
          await PlacesCacheService.get(
        latitude: latitude,
        longitude: longitude,
        category: _selectedCategory,
      );

      if (!mounted) {
        return;
      }

      if (cacheEntry != null) {
        hasCachedResults = true;

        setState(() {
          _places = cacheEntry.places;
          _cacheLabel = cacheEntry.updatedLabel;
          _errorMessage = null;
        });

        if (cacheEntry.isFresh) {
          return;
        }
      }
    }

    setState(() {
      if (hasCachedResults || _places.isNotEmpty) {
        _updatingInBackground = true;
      } else {
        _loading = true;
      }

      _errorMessage = null;
    });

    try {
      final places =
          await PlacesService.searchNearby(
        latitude: latitude,
        longitude: longitude,
        category: _selectedCategory,
      );

      await PlacesCacheService.save(
        latitude: latitude,
        longitude: longitude,
        category: _selectedCategory,
        places: places,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _places = places;
        _cacheLabel = 'Actualizado ahora';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (_places.isEmpty) {
        setState(() {
          _errorMessage = _cleanError(error);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mostramos los últimos lugares guardados porque no se pudo actualizar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _updatingInBackground = false;
        });
      }
    }
  }

  Future<void> _openPlace(
    PlaceItem place,
  ) async {
    final latitude = place.latitude;
    final longitude = place.longitude;

    final geoUri = Uri(
      scheme: 'geo',
      path: '$latitude,$longitude',
      queryParameters: {
        'q': '$latitude,$longitude (${place.name})',
      },
    );

    try {
      final opened = await launchUrl(
        geoUri,
        mode: LaunchMode.externalApplication,
      );

      if (opened) {
        return;
      }
    } catch (_) {
      // Se utiliza la alternativa web.
    }

    final mapsUri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '$latitude,$longitude',
      },
    );

    try {
      final opened = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (opened) {
        return;
      }
    } catch (_) {
      // Se muestra un mensaje abajo.
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo abrir la aplicación de mapas.',
        ),
      ),
    );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception:', '')
        .trim();
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        backgroundColor: DogGoTheme.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Lugares',
          style: DogGoTheme.title(size: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return _loadPlaces(
            forceRefresh: true,
          );
        },
        color: DogGoTheme.teal,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            24,
            23,
            24,
            40,
          ),
          children: [
            Text(
              'Explora con tu mascota',
              style: DogGoTheme.title(size: 27),
            ),
            const SizedBox(height: 7),
            Text(
              'Encuentra espacios y servicios cerca de ti.',
              style: DogGoTheme.subtitle(size: 13),
            ),
            const SizedBox(height: 21),
            _LocationCard(
              locationText: _locationText,
              selected: _selectedLocation != null,
              busy: _locationBusy,
              onTap: _showLocationOptions,
            ),
            const SizedBox(height: 26),
            Text(
              '¿Qué estás buscando?',
              style: DogGoTheme.title(size: 20),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.37,
              ),
              itemBuilder: (context, index) {
                final appearance =
                    _categories[index];

                return _CategoryCard(
                  appearance: appearance,
                  selected: appearance.category ==
                      _selectedCategory,
                  onTap: () {
                    _selectCategory(
                      appearance.category,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 27),
            _ResultsHeader(
              title: _categoryTitle,
              resultCount: _places.length,
              hasLocation:
                  _selectedLocation != null,
              updating: _updatingInBackground,
            ),
            if (_cacheLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                _cacheLabel!,
                style: DogGoTheme.body(
                  size: 10,
                  color: DogGoTheme.muted,
                  weight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_locationBusy && _places.isEmpty) {
      return const _PlacesLoading();
    }

    if (_selectedLocation == null) {
      return _PlacesMessage(
        icon: Icons.location_searching_rounded,
        title: 'Configura tu ubicación',
        message:
            'Podemos usar tu dirección de recogida o permitirte elegir otra zona.',
        actionText: 'Elegir opción',
        onAction: () {
          _showLocationOptions();
        },
      );
    }

    if (_loading && _places.isEmpty) {
      return const _PlacesLoading();
    }

    if (_errorMessage != null &&
        _places.isEmpty) {
      return _PlacesMessage(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos buscar lugares',
        message: _errorMessage!,
        actionText: 'Reintentar',
        onAction: () {
          _loadPlaces(forceRefresh: true);
        },
      );
    }

    if (_places.isEmpty) {
      return _PlacesMessage(
        icon: Icons.travel_explore_rounded,
        title: 'Sin resultados cercanos',
        message:
            'No encontramos ${_categoryTitle.toLowerCase()} registrados en un radio de 10 km.',
        actionText: 'Cambiar ubicación',
        onAction: () {
          _showLocationOptions();
        },
      );
    }

    return Column(
      children: [
        for (var index = 0;
            index < _places.length;
            index++) ...[
          _PlaceCard(
            place: _places[index],
            appearance:
                _categories.firstWhere(
              (item) =>
                  item.category ==
                  _places[index].category,
            ),
            onTap: () {
              _openPlace(_places[index]);
            },
          ),
          if (index < _places.length - 1)
            const SizedBox(height: 12),
        ],
        const SizedBox(height: 17),
        Text(
          'Datos proporcionados por OpenStreetMap',
          textAlign: TextAlign.center,
          style: DogGoTheme.body(
            size: 10,
            color: DogGoTheme.muted,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String locationText;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  const _LocationCard({
    required this.locationText,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.teal,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF08705F),
                Color(0xFF07967B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Container(
                width: 53,
                height: 53,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: .15,
                  ),
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        selected
                            ? Icons.location_on_rounded
                            : Icons.my_location_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected
                          ? 'Ubicación para explorar'
                          : 'Configura tu zona',
                      style: DogGoTheme.body(
                        size: 10.5,
                        color: DogGoTheme.orange,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      busy
                          ? 'Buscando ubicación guardada...'
                          : locationText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (!busy) ...[
                const SizedBox(width: 9),
                Container(
                  width: 39,
                  height: 39,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: DogGoTheme.teal,
                    size: 21,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _LocationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.body(
                        size: 13,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: DogGoTheme.subtitle(
                        size: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryAppearance appearance;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.appearance,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? appearance.background
          : DogGoTheme.card,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: selected
                  ? appearance.color.withValues(
                      alpha: .42,
                    )
                  : DogGoTheme.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? DogGoTheme.card
                      : appearance.background,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  appearance.icon,
                  color: appearance.color,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                appearance.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.body(
                  size: 12.5,
                  color: DogGoTheme.ink,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final String title;
  final int resultCount;
  final bool hasLocation;
  final bool updating;

  const _ResultsHeader({
    required this.title,
    required this.resultCount,
    required this.hasLocation,
    required this.updating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: DogGoTheme.title(size: 21),
          ),
        ),
        if (updating) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DogGoTheme.teal,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'Actualizando',
            style: DogGoTheme.body(
              size: 10,
              color: DogGoTheme.teal,
              weight: FontWeight.w800,
            ),
          ),
        ] else if (hasLocation)
          Text(
            '$resultCount encontrados',
            style: DogGoTheme.body(
              size: 10.5,
              color: DogGoTheme.teal,
              weight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final PlaceItem place;
  final _CategoryAppearance appearance;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.appearance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: appearance.background,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Icon(
                  appearance.icon,
                  color: appearance.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 14,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: DogGoTheme.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            place.address,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: DogGoTheme.subtitle(
                              size: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                DogGoTheme.tealLight,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            place.distanceLabel,
                            style: DogGoTheme.body(
                              size: 10,
                              color: DogGoTheme.teal,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Abrir en Maps',
                          style: DogGoTheme.body(
                            size: 10,
                            color: appearance.color,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                Icons.navigation_rounded,
                color: appearance.color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacesLoading extends StatelessWidget {
  const _PlacesLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: DogGoTheme.teal,
        ),
      ),
    );
  }
}

class _PlacesMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _PlacesMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 61,
            height: 61,
            decoration: const BoxDecoration(
              color: DogGoTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: DogGoTheme.teal,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 11.5),
          ),
          const SizedBox(height: 17),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}

class _CategoryAppearance {
  final PlaceCategory category;
  final String title;
  final IconData icon;
  final Color color;
  final Color background;

  const _CategoryAppearance({
    required this.category,
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
  });
}