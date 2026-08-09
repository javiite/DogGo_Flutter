import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_map_preview.dart';
import 'profile/edit_profile_controller.dart';
import 'profile/edit_profile_state.dart';
import 'seleccionar_ubicacion_screen.dart';

class OwnerProfileSetupScreen
    extends StatefulWidget {
  final Map<String, dynamic> profile;

  const OwnerProfileSetupScreen({
    super.key,
    required this.profile,
  });

  @override
  State<OwnerProfileSetupScreen>
      createState() {
    return _OwnerProfileSetupScreenState();
  }
}

class _OwnerProfileSetupScreenState
    extends State<OwnerProfileSetupScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final EditProfileController
      _controller;

  bool _validationEnabled = false;

  @override
  void initState() {
    super.initState();

    _controller = EditProfileController(
      initialProfile: widget.profile,
    );

    for (final controller
        in _textControllers) {
      controller.addListener(
        _refreshProgress,
      );
    }

    _controller.initialize();
  }

  List<TextEditingController>
      get _textControllers {
    return [
      _controller.nameController,
      _controller.lastNameController,
      _controller.phoneController,
      _controller.addressController,
      _controller.referencesController,
      _controller.zoneController,
      _controller.descriptionController,
      _controller.preferencesController,
    ];
  }

  void _refreshProgress() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final controller
        in _textControllers) {
      controller.removeListener(
        _refreshProgress,
      );
    }

    _controller.dispose();
    super.dispose();
  }

  double _progress(
    EditProfileState state,
  ) {
    var completed = 0;

    if (_controller
        .nameController.text
        .trim()
        .isNotEmpty) {
      completed++;
    }

    if (_controller
        .phoneController.text
        .trim()
        .isNotEmpty) {
      completed++;
    }

    if (_controller
        .addressController.text
        .trim()
        .isNotEmpty) {
      completed++;
    }

    if (state.hasLocation) {
      completed++;
    }

    return completed / 4;
  }

  Future<void> _selectLocation() async {
    final state = _controller.state;

    final result =
        await Navigator.push<
            Map<String, dynamic>>(
      context,
      MaterialPageRoute<
          Map<String, dynamic>>(
        builder: (_) =>
            SeleccionarUbicacionScreen(
          ubicacionInicial:
              state.hasLocation
                  ? LatLng(
                      state.latitude!,
                      state.longitude!,
                    )
                  : null,
          textoInicial: _controller
                  .addressController.text
                  .trim()
                  .isEmpty
              ? null
              : _controller
                  .addressController.text
                  .trim(),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    final latitude =
        EditProfileState.safeDouble(
      result['latitud'] ??
          result['Latitud'] ??
          result['latitude'],
    );

    final longitude =
        EditProfileState.safeDouble(
      result['longitud'] ??
          result['Longitud'] ??
          result['longitude'],
    );

    if (latitude == null ||
        longitude == null) {
      _showMessage(
        'La ubicación seleccionada no es válida.',
        error: true,
      );
      return;
    }

    final address =
        result['texto'] ??
            result['ubicacionTexto'] ??
            result['direccionRecogida'] ??
            result['direccion'];

    _controller.setLocation(
      latitude: latitude,
      longitude: longitude,
      address: address?.toString(),
    );
  }

  Future<void> _selectPhoto() async {
    if (_controller.state.saving) {
      return;
    }

    final source =
        await showModalBottomSheet<
            ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  'Fotografía de perfil',
                  style: DogGoTheme.title(
                    size: 21,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Puedes agregar una foto clara para que el paseador te reconozca.',
                  textAlign:
                      TextAlign.center,
                  style:
                      DogGoTheme.subtitle(),
                ),
                const SizedBox(height: 18),
                _PhotoSourceOption(
                  icon: Icons
                      .photo_camera_outlined,
                  title: 'Tomar fotografía',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      ImageSource.camera,
                    );
                  },
                ),
                const SizedBox(height: 10),
                _PhotoSourceOption(
                  icon: Icons
                      .photo_library_outlined,
                  title:
                      'Elegir de la galería',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      ImageSource.gallery,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final selected =
        await _controller.selectPhoto(
      source,
    );

    if (!mounted) {
      return;
    }

    if (!selected &&
        _controller.state.error != null) {
      _showMessage(
        _controller.state.error!,
        error: true,
      );
    }
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    setState(() {
      _validationEnabled = true;
    });

    if (!(_formKey.currentState
            ?.validate() ??
        false)) {
      _showMessage(
        'Revisa los campos marcados.',
        error: true,
      );
      return;
    }

    if (_controller
        .addressController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Agrega la dirección de recogida.',
        error: true,
      );
      return;
    }

    if (!_controller.state.hasLocation) {
      _showMessage(
        'Selecciona el punto de recogida en el mapa.',
        error: true,
      );
      return;
    }

    final saved =
        await _controller.save();

    if (!mounted) {
      return;
    }

    if (!saved) {
      _showMessage(
        _controller.state.error ??
            'No se pudo guardar el perfil.',
        error: true,
      );
      return;
    }

    _showMessage(
      'Tu perfil de dueño está listo.',
    );

    await Future<void>.delayed(
      const Duration(
        milliseconds: 450,
      ),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error
              ? DogGoTheme.red
              : DogGoTheme.teal,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons
                        .error_outline_rounded
                    : Icons
                        .check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state =
            _controller.state;

        return PopScope(
          canPop: !state.saving,
          child: Scaffold(
            backgroundColor:
                DogGoTheme.cream,
            appBar: AppBar(
              automaticallyImplyLeading:
                  false,
              title: const Text(
                'Configura tu perfil',
              ),
            ),
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    EditProfileState state,
  ) {
    if (state.loading) {
      return const DogGoLoadingView(
        message:
            'Preparando tu perfil...',
      );
    }

    if (state.error != null &&
        !state.ownerProfileLoaded) {
      return Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: DogGoErrorView(
            title:
                'No pudimos preparar tu perfil',
            message: state.error!,
            onRetry: _controller.retry,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            autovalidateMode:
                _validationEnabled
                    ? AutovalidateMode
                        .onUserInteraction
                    : AutovalidateMode
                        .disabled,
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                DogGoSpacing
                    .screenHorizontal,
                DogGoSpacing.md,
                DogGoSpacing
                    .screenHorizontal,
                DogGoSpacing.lg,
              ),
              children: [
                _buildWelcomeCard(state),
                const SizedBox(
                  height: 18,
                ),
                _buildPickupSection(state),
                const SizedBox(
                  height: 16,
                ),
                _buildReferencesSection(),
                const SizedBox(
                  height: 16,
                ),
                _buildPersonalSection(state),
                const SizedBox(
                  height: 16,
                ),
                _buildPreferencesSection(),
              ],
            ),
          ),
        ),
        _buildBottomAction(state),
      ],
    );
  }

  Widget _buildWelcomeCard(
    EditProfileState state,
  ) {
    final progress = _progress(state);
    final percentage =
        (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            DogGoTheme.tealDark,
            DogGoTheme.teal,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(
          DogGoRadius.extraLarge,
        ),
        boxShadow:
            DogGoTheme.elevatedShadow(),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: .14,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: .14,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    999,
                  ),
                ),
                child: Text(
                  '$percentage%',
                  style: DogGoTheme.body(
                    size: 12,
                    color: Colors.white,
                    weight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Prepara tu hogar para DogGo',
            style: DogGoTheme.title(
              size: 25,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guardaremos el punto donde normalmente recogerán a tus mascotas.',
            style: DogGoTheme.subtitle(
              size: 13,
              color: Colors.white
                  .withValues(alpha: .82),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              999,
            ),
            child:
                LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor:
                  Colors.white.withValues(
                alpha: .18,
              ),
              valueColor:
                  const AlwaysStoppedAnimation(
                DogGoTheme.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSection(
    EditProfileState state,
  ) {
    return _SetupSection(
      number: '1',
      icon:
          Icons.location_on_outlined,
      title: 'Punto de recogida',
      subtitle:
          'Será la ubicación predeterminada para solicitar paseos.',
      requiredSection: true,
      child: Column(
        children: [
          _SetupField(
            controller:
                _controller
                    .addressController,
            label: 'Dirección',
            hint:
                'Calle, número y colonia',
            icon:
                Icons.home_outlined,
            textInputAction:
                TextInputAction.next,
            validator: (value) {
              final text =
                  value?.trim() ?? '';

              if (text.isEmpty) {
                return 'La dirección es obligatoria.';
              }

              if (text.length > 250) {
                return 'La dirección es demasiado larga.';
              }

              return null;
            },
          ),
          const SizedBox(height: 14),
          DogGoMapPreview(
            latitud: state.latitude,
            longitud: state.longitude,
            height: 205,
            emptyText:
                'Fija tu punto de recogida',
            onTap: state.saving
                ? null
                : _selectLocation,
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.saving
                  ? null
                  : _selectLocation,
              icon: Icon(
                state.hasLocation
                    ? Icons
                        .edit_location_alt_outlined
                    : Icons
                        .add_location_alt_outlined,
              ),
              label: Text(
                state.hasLocation
                    ? 'Cambiar ubicación'
                    : 'Seleccionar en el mapa',
              ),
            ),
          ),
          if (state.hasLocation) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: state.saving
                  ? null
                  : _controller
                      .clearLocation,
              icon: const Icon(
                Icons
                    .location_off_outlined,
              ),
              label: const Text(
                'Quitar ubicación',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferencesSection() {
    return _SetupSection(
      number: '2',
      icon: Icons.signpost_outlined,
      title: 'Ayuda al paseador',
      subtitle:
          'Agrega referencias para localizar el domicilio fácilmente.',
      child: Column(
        children: [
          _SetupField(
            controller:
                _controller
                    .referencesController,
            label: 'Referencias',
            hint:
                'Color de casa, entrecalles, portón...',
            icon:
                Icons.signpost_outlined,
            maxLines: 3,
            textInputAction:
                TextInputAction.next,
            validator: (value) {
              return _controller
                  .validateOptionalText(
                value,
                maximumLength: 300,
              );
            },
          ),
          const SizedBox(height: 14),
          _SetupField(
            controller:
                _controller
                    .zoneController,
            label: 'Zona',
            hint:
                'Colonia, municipio o sector',
            icon: Icons.map_outlined,
            textInputAction:
                TextInputAction.next,
            validator: (value) {
              return _controller
                  .validateOptionalText(
                value,
                maximumLength: 120,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection(
    EditProfileState state,
  ) {
    return _SetupSection(
      number: '3',
      icon:
          Icons.person_outline_rounded,
      title: 'Tus datos',
      subtitle:
          'Información para coordinar el servicio contigo.',
      child: Column(
        children: [
          Row(
            children: [
              _CompactProfilePhoto(
                selectedPhoto:
                    state.selectedPhoto,
                currentPhotoUrl:
                    state.currentPhotoUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: state.saving
                      ? null
                      : _selectPhoto,
                  icon: const Icon(
                    Icons
                        .add_a_photo_outlined,
                  ),
                  label: const Text(
                    'Agregar foto',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SetupField(
            controller:
                _controller
                    .nameController,
            label: 'Nombre',
            hint: 'Tu nombre',
            icon:
                Icons.person_outline,
            textInputAction:
                TextInputAction.next,
            validator:
                _controller.validateName,
          ),
          const SizedBox(height: 14),
          _SetupField(
            controller:
                _controller
                    .lastNameController,
            label: 'Apellido',
            hint: 'Tu apellido',
            icon:
                Icons.badge_outlined,
            textInputAction:
                TextInputAction.next,
            validator: _controller
                .validateLastName,
          ),
          const SizedBox(height: 14),
          _SetupField(
            controller:
                _controller
                    .phoneController,
            label: 'Teléfono',
            hint:
                'Número de contacto',
            icon:
                Icons.phone_outlined,
            keyboardType:
                TextInputType.phone,
            textInputAction:
                TextInputAction.next,
            validator:
                _controller.validatePhone,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _SetupSection(
      number: '4',
      icon: Icons.pets_outlined,
      title: 'Preferencias',
      subtitle:
          'Opcional: comparte información útil para futuros paseos.',
      child: Column(
        children: [
          _SetupField(
            controller:
                _controller
                    .descriptionController,
            label: 'Sobre ti y tus mascotas',
            hint:
                'Cuéntanos algo importante',
            icon: Icons.notes_outlined,
            maxLines: 3,
            textInputAction:
                TextInputAction.newline,
            validator: (value) {
              return _controller
                  .validateOptionalText(
                value,
                maximumLength: 600,
              );
            },
          ),
          const SizedBox(height: 14),
          _SetupField(
            controller:
                _controller
                    .preferencesController,
            label:
                'Preferencias de paseo',
            hint:
                'Horarios, cuidados o indicaciones',
            icon: Icons
                .directions_walk_outlined,
            maxLines: 3,
            textInputAction:
                TextInputAction.newline,
            validator: (value) {
              return _controller
                  .validateOptionalText(
                value,
                maximumLength: 600,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(
    EditProfileState state,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 +
            MediaQuery.paddingOf(
              context,
            ).bottom,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        border: const Border(
          top: BorderSide(
            color: DogGoTheme.border,
          ),
        ),
        boxShadow: DogGoTheme.softShadow(
          offset: const Offset(0, -5),
          blur: 18,
        ),
      ),
      child: ElevatedButton.icon(
        onPressed:
            state.saving ? null : _save,
        icon: state.saving
            ? const SizedBox(
                width: 19,
                height: 19,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons
                    .check_circle_outline_rounded,
              ),
        label: Text(
          state.saving
              ? 'Guardando perfil...'
              : 'Guardar y comenzar',
        ),
      ),
    );
  }
}

class _SetupSection
    extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool requiredSection;
  final Widget child;

  const _SetupSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.requiredSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: requiredSection
              ? DogGoTheme.teal
                  .withValues(alpha: .25)
              : DogGoTheme.border,
        ),
        boxShadow:
            DogGoTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color:
                      DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Stack(
                  alignment:
                      Alignment.center,
                  children: [
                    Icon(
                      icon,
                      color:
                          DogGoTheme.teal,
                      size: 22,
                    ),
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration:
                            const BoxDecoration(
                          color:
                              DogGoTheme.teal,
                          shape:
                              BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            number,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 8,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style:
                                DogGoTheme.title(
                              size: 17,
                            ),
                          ),
                        ),
                        if (requiredSection)
                          Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              left: 8,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration:
                                BoxDecoration(
                              color: DogGoTheme
                                  .orangeLight,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                999,
                              ),
                            ),
                            child: const Text(
                              'Necesario',
                              style: TextStyle(
                                color:
                                    DogGoTheme
                                        .orange,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style:
                          DogGoTheme.subtitle(
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SetupField
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)?
      validator;
  final int maxLines;

  const _SetupField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      minLines: 1,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint:
            maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            bottom:
                maxLines > 1 ? 44 : 0,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _CompactProfilePhoto
    extends StatelessWidget {
  final File? selectedPhoto;
  final String? currentPhotoUrl;

  const _CompactProfilePhoto({
    required this.selectedPhoto,
    required this.currentPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: DogGoTheme.card,
          width: 3,
        ),
        boxShadow:
            DogGoTheme.softShadow(),
      ),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (selectedPhoto != null) {
      return Image.file(
        selectedPhoto!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const _PhotoPlaceholder();
        },
      );
    }

    final url =
        currentPhotoUrl?.trim();

    if (url != null &&
        (url.startsWith('http://') ||
            url.startsWith(
              'https://',
            ))) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const _PhotoPlaceholder();
        },
      );
    }

    return const _PhotoPlaceholder();
  }
}

class _PhotoPlaceholder
    extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.person_rounded,
      color: DogGoTheme.teal,
      size: 36,
    );
  }
}

class _PhotoSourceOption
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PhotoSourceOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.cream,
      borderRadius:
          BorderRadius.circular(
        DogGoRadius.medium,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          DogGoRadius.medium,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            15,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              DogGoRadius.medium,
            ),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: DogGoTheme.teal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style:
                      DogGoTheme.body(
                    weight:
                        FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}