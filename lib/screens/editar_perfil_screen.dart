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

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;

  const EditarPerfilScreen({super.key, required this.perfil});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final EditProfileController _controller;
  bool _validationEnabled = false;

  @override
  void initState() {
    super.initState();

    _controller = EditProfileController(initialProfile: widget.perfil)
      ..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? DogGoTheme.red : DogGoTheme.ink,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _selectPhoto() async {
    if (_controller.state.saving) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.sm,
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Actualizar fotografía',
                  style: DogGoTheme.title(size: 21),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  'Elige una fotografía clara para tu perfil.',
                  textAlign: TextAlign.center,
                  style: DogGoTheme.subtitle(),
                ),
                const SizedBox(height: DogGoSpacing.lg),
                _SheetOption(
                  icon: Icons.photo_camera_outlined,
                  title: 'Tomar fotografía',
                  subtitle: 'Usar la cámara del teléfono',
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
                const SizedBox(height: DogGoSpacing.sm),
                _SheetOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Elegir de la galería',
                  subtitle: 'Seleccionar una imagen guardada',
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final selected = await _controller.selectPhoto(source);

    if (!mounted) return;

    if (selected) {
      _showMessage('Fotografía seleccionada. Se subirá al guardar.');
    } else if (_controller.state.error != null) {
      _showMessage(_controller.state.error!, error: true);
    }
  }

  Future<void> _selectLocation() async {
    final state = _controller.state;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => SeleccionarUbicacionScreen(
          ubicacionInicial: state.hasLocation
              ? LatLng(state.latitude!, state.longitude!)
              : null,
          textoInicial: _controller.addressController.text.trim().isEmpty
              ? null
              : _controller.addressController.text.trim(),
        ),
      ),
    );

    if (result == null) return;

    final latitude = EditProfileState.safeDouble(
      result['latitud'] ?? result['Latitud'] ?? result['latitude'],
    );

    final longitude = EditProfileState.safeDouble(
      result['longitud'] ?? result['Longitud'] ?? result['longitude'],
    );

    if (latitude == null || longitude == null) {
      _showMessage('La ubicación seleccionada no es válida.', error: true);
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

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _validationEnabled = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage('Revisa los campos marcados.', error: true);
      return;
    }

    final saved = await _controller.save();

    if (!mounted) return;

    if (!saved) {
      _showMessage(
        _controller.state.error ?? 'No se pudo actualizar el perfil.',
        error: true,
      );
      return;
    }

    _showMessage('Perfil actualizado correctamente.');

    await Future<void>.delayed(const Duration(milliseconds: 550));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return PopScope(
          canPop: !state.saving,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Editar perfil'),
              actions: [
                TextButton(
                  onPressed: state.saving ? null : _save,
                  child: const Text('Guardar'),
                ),
                const SizedBox(width: DogGoSpacing.sm),
              ],
            ),
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(EditProfileState state) {
    if (state.loading) {
      return const DogGoLoadingView(message: 'Cargando tu información...');
    }

    if (state.error != null &&
        _controller.isOwner &&
        !state.ownerProfileLoaded) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
          child: DogGoErrorView(
            title: 'No pudimos cargar el perfil',
            message: state.error!,
            onRetry: _controller.retry,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      autovalidateMode: _validationEnabled
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.md,
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.xxl,
        ),
        children: [
          _buildPhotoCard(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildPersonalInformation(),
          if (_controller.isOwner) ...[
            const SizedBox(height: DogGoSpacing.md),
            _buildCollectionInformation(state),
            const SizedBox(height: DogGoSpacing.md),
            _buildWalkingPreferences(),
          ],
          const SizedBox(height: DogGoSpacing.lg),
          _buildSaveButton(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildCancelButton(state),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(EditProfileState state) {
    return _EditCard(
      title: 'Fotografía',
      subtitle: _controller.isOwner
          ? 'La verá el paseador al coordinar el servicio.'
          : 'Esta fotografía identifica tu cuenta.',
      icon: Icons.account_circle_outlined,
      child: Column(
        children: [
          _ProfilePhoto(
            selectedPhoto: state.selectedPhoto,
            currentPhotoUrl: state.currentPhotoUrl,
          ),
          const SizedBox(height: DogGoSpacing.md),
          OutlinedButton.icon(
            onPressed: state.saving ? null : _selectPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              state.hasPhoto ? 'Cambiar fotografía' : 'Agregar fotografía',
            ),
          ),
          if (state.selectedPhoto != null) ...[
            const SizedBox(height: DogGoSpacing.sm),
            TextButton.icon(
              onPressed: state.saving ? null : _controller.removeSelectedPhoto,
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Mantener fotografía anterior'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _EditCard(
      title: 'Datos personales',
      subtitle: 'Información principal de tu cuenta.',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _ProfileField(
            controller: _controller.nameController,
            label: 'Nombre',
            hint: 'Escribe tu nombre',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: _controller.validateName,
            autofillHints: const [AutofillHints.givenName],
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ProfileField(
            controller: _controller.lastNameController,
            label: 'Apellido',
            hint: 'Escribe tu apellido',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: _controller.validateLastName,
            autofillHints: const [AutofillHints.familyName],
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ProfileField(
            controller: _controller.phoneController,
            label: 'Teléfono',
            hint: 'Número de contacto',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: _controller.validatePhone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: DogGoSpacing.md),
          _ReadOnlyInformation(
            icon: Icons.email_outlined,
            title: 'Correo',
            value: _controller.email,
          ),
          const SizedBox(height: DogGoSpacing.sm),
          _ReadOnlyInformation(
            icon: Icons.manage_accounts_outlined,
            title: 'Tipo de cuenta',
            value: _controller.roleLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionInformation(EditProfileState state) {
    return _EditCard(
      title: 'Datos de recolección',
      subtitle: 'Ayudan al paseador a encontrar el punto de inicio.',
      icon: Icons.home_outlined,
      child: Column(
        children: [
          _ProfileField(
            controller: _controller.addressController,
            label: 'Dirección',
            hint: 'Calle, número y colonia',
            icon: Icons.location_on_outlined,
            textInputAction: TextInputAction.next,
            validator: (value) {
              return _controller.validateOptionalText(
                value,
                maximumLength: 250,
              );
            },
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ProfileField(
            controller: _controller.referencesController,
            label: 'Referencias',
            hint: 'Color de casa, entrecalles u otra referencia',
            icon: Icons.signpost_outlined,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            validator: (value) {
              return _controller.validateOptionalText(
                value,
                maximumLength: 300,
              );
            },
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          DropdownButtonFormField<String>(
            initialValue: state.selectedStateCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            items: state.states
                .map(
                  (item) => DropdownMenuItem(
                    value: item.code,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: state.saving ? null : _controller.selectState,
            validator: (value) =>
                value == null ? 'Selecciona tu estado.' : null,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          DropdownButtonFormField<String>(
            key: ValueKey(
              '${state.selectedStateCode}-${state.selectedMunicipalityCode}',
            ),
            initialValue: state.selectedMunicipalityCode,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Municipio o alcaldía',
              prefixIcon: state.loadingMunicipalities
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_city_outlined),
            ),
            items: state.municipalities
                .map(
                  (item) => DropdownMenuItem(
                    value: item.code,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged:
                state.saving ||
                    state.loadingMunicipalities ||
                    state.selectedStateCode == null
                ? null
                : _controller.selectMunicipality,
            validator: (value) =>
                value == null ? 'Selecciona tu municipio.' : null,
          ),
          const SizedBox(height: DogGoSpacing.md),
          DogGoMapPreview(
            latitud: state.latitude,
            longitud: state.longitude,
            height: 190,
            emptyText: 'Selecciona una ubicación',
            onTap: state.saving ? null : _selectLocation,
          ),
          const SizedBox(height: DogGoSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.saving ? null : _selectLocation,
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: Text(
                state.hasLocation
                    ? 'Cambiar ubicación'
                    : 'Seleccionar ubicación',
              ),
            ),
          ),
          if (state.hasLocation)
            TextButton.icon(
              onPressed: state.saving ? null : _controller.clearLocation,
              icon: const Icon(Icons.location_off_outlined),
              label: const Text('Quitar ubicación'),
            ),
        ],
      ),
    );
  }

  Widget _buildWalkingPreferences() {
    return _EditCard(
      title: 'Información para paseos',
      subtitle: 'Comparte indicaciones útiles con el paseador.',
      icon: Icons.pets_outlined,
      child: Column(
        children: [
          _ProfileField(
            controller: _controller.descriptionController,
            label: 'Descripción',
            hint: 'Cuéntanos algo importante sobre ti o tus mascotas',
            icon: Icons.notes_outlined,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            validator: (value) {
              return _controller.validateOptionalText(
                value,
                maximumLength: 600,
              );
            },
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ProfileField(
            controller: _controller.preferencesController,
            label: 'Preferencias de paseo',
            hint: 'Horarios, cuidados o indicaciones especiales',
            icon: Icons.directions_walk_outlined,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            validator: (value) {
              return _controller.validateOptionalText(
                value,
                maximumLength: 600,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(EditProfileState state) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: state.saving ? null : _save,
        icon: state.saving
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(state.saving ? 'Guardando cambios...' : 'Guardar cambios'),
      ),
    );
  }

  Widget _buildCancelButton(EditProfileState state) {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: state.saving
            ? null
            : () {
                Navigator.pop(context, false);
              },
        child: const Text('Cancelar'),
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _EditCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: DogGoTheme.teal, size: 22),
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DogGoTheme.title(size: 17)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: DogGoTheme.subtitle(size: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.largeGap),
          child,
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final File? selectedPhoto;
  final String? currentPhotoUrl;

  const _ProfilePhoto({
    required this.selectedPhoto,
    required this.currentPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 124,
        height: 124,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DogGoTheme.tealLight,
          shape: BoxShape.circle,
          border: Border.all(color: DogGoTheme.card, width: 4),
          boxShadow: DogGoTheme.elevatedShadow(),
        ),
        child: _buildImage(),
      ),
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

    final url = currentPhotoUrl?.trim();

    if (url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person_rounded, color: DogGoTheme.teal, size: 62);
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final int minLines;
  final int maxLines;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autofillHints: autofillHints,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 48 : 0),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _ReadOnlyInformation extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ReadOnlyInformation({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.md),
      decoration: BoxDecoration(
        color: DogGoTheme.cream,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: DogGoTheme.muted, size: 21),
          const SizedBox(width: DogGoSpacing.compactGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DogGoTheme.caption(weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, style: DogGoTheme.body(size: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DogGoRadius.medium),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DogGoSpacing.md),
        decoration: BoxDecoration(
          color: DogGoTheme.cream,
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
          border: Border.all(color: DogGoTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: DogGoTheme.tealLight,
                borderRadius: BorderRadius.circular(DogGoRadius.medium),
              ),
              child: Icon(icon, color: DogGoTheme.teal),
            ),
            const SizedBox(width: DogGoSpacing.compactGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DogGoTheme.body(weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: DogGoTheme.subtitle(size: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DogGoTheme.muted),
          ],
        ),
      ),
    );
  }
}
