import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../shared/widgets/doggo_sticky_action_bar.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'profile/edit_walker_profile_controller.dart';
import 'profile/edit_walker_profile_state.dart';
import 'profile/widgets/walker_coverage_map.dart';
import 'availability/availability_screen.dart';
import 'location/widgets/searchable_location_field.dart';

class EditarPerfilPaseadorScreen extends StatefulWidget {
  const EditarPerfilPaseadorScreen({super.key});

  @override
  State<EditarPerfilPaseadorScreen> createState() =>
      _EditarPerfilPaseadorScreenState();
}

class _EditarPerfilPaseadorScreenState
    extends State<EditarPerfilPaseadorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final EditWalkerProfileController _controller;

  bool _validationEnabled = false;

  @override
  void initState() {
    super.initState();

    _controller = EditWalkerProfileController();

    _controller.descriptionController.addListener(_refreshForm);
    _controller.zoneController.addListener(_refreshForm);
    _controller.rateController.addListener(_refreshForm);
    _controller.experienceController.addListener(_refreshForm);

    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.descriptionController.removeListener(_refreshForm);
    _controller.zoneController.removeListener(_refreshForm);
    _controller.rateController.removeListener(_refreshForm);
    _controller.experienceController.removeListener(_refreshForm);

    _controller.dispose();
    super.dispose();
  }

  void _refreshForm() {
    if (mounted) {
      setState(() {});
    }
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
                  'Fotografía profesional',
                  style: DogGoTheme.title(size: 21),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  'Elige una fotografía clara para que los dueños puedan reconocerte.',
                  textAlign: TextAlign.center,
                  style: DogGoTheme.subtitle(),
                ),
                const SizedBox(height: DogGoSpacing.lg),
                _PhotoOption(
                  icon: Icons.photo_camera_outlined,
                  title: 'Tomar fotografía',
                  subtitle: 'Usar la cámara del teléfono',
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
                const SizedBox(height: DogGoSpacing.sm),
                _PhotoOption(
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
        _controller.state.error ?? 'No se pudo guardar el perfil.',
        error: true,
      );
      return;
    }

    _showMessage('Perfil de paseador actualizado correctamente.');

    await Future<void>.delayed(const Duration(milliseconds: 600));

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
          child: DogGoScreenScaffold(
            title: 'Perfil de paseador',
            body: _buildBody(state),
            bottomNavigationBar: state.loading
                ? null
                : DogGoStickyActionBar(
                    primaryLabel: state.saving
                        ? 'Guardando perfil...'
                        : 'Guardar perfil',
                    primaryIcon: Icons.save_outlined,
                    onPrimary: state.saving ? null : _save,
                    secondaryLabel: 'Cancelar',
                    secondaryIcon: Icons.close_rounded,
                    onSecondary: state.saving
                        ? null
                        : () => Navigator.pop(context, false),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBody(EditWalkerProfileState state) {
    if (state.loading) {
      return const DogGoLoadingView(message: 'Cargando perfil profesional...');
    }

    if (state.error != null && !state.profileLoaded) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
          child: DogGoErrorView(
            title: 'No pudimos cargar tu perfil',
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
          if (state.error != null) ...[
            DogGoErrorView(
              message: state.error!,
              onRetry: _controller.clearError,
              retryText: 'Cerrar mensaje',
              compact: true,
            ),
            const SizedBox(height: DogGoSpacing.md),
          ],
          _buildProgressCard(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildPhotoCard(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildProfessionalInformation(),
          const SizedBox(height: DogGoSpacing.md),
          _buildAvailabilityCard(state),
        ],
      ),
    );
  }

  Widget _buildProgressCard(EditWalkerProfileState state) {
    final percentage = _controller.completionPercentage;

    final complete = _controller.profileComplete;

    return Container(
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: complete ? DogGoTheme.greenLight : DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(
          color: complete
              ? DogGoTheme.green.withValues(alpha: 0.18)
              : DogGoTheme.orange.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: DogGoTheme.card,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(
                  complete
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  color: complete ? DogGoTheme.green : DogGoTheme.orange,
                ),
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Perfil completo' : 'Completa tu perfil',
                      style: DogGoTheme.title(size: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      complete
                          ? 'Tu información profesional está lista.'
                          : 'Llevas $percentage% completado.',
                      style: DogGoTheme.subtitle(size: 12.5),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: DogGoTheme.body(
                  size: 15,
                  weight: FontWeight.w800,
                  color: complete ? DogGoTheme.green : DogGoTheme.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(DogGoRadius.pill),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              color: complete ? DogGoTheme.green : DogGoTheme.orange,
              backgroundColor: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(EditWalkerProfileState state) {
    return _WalkerCard(
      title: 'Fotografía profesional',
      subtitle: 'Ayuda a que los dueños puedan identificarte.',
      icon: Icons.account_circle_outlined,
      child: Column(
        children: [
          _WalkerPhoto(
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

  Widget _buildProfessionalInformation() {
    return _WalkerCard(
      title: 'Información profesional',
      subtitle: 'Esta información será visible para los dueños.',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _WalkerField(
            controller: _controller.descriptionController,
            label: 'Descripción',
            hint: 'Describe tu experiencia y forma de trabajar',
            icon: Icons.description_outlined,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            validator: _controller.validateDescription,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          SearchableLocationField(
            label: 'Estado',
            icon: Icons.map_outlined,
            items: _controller.state.states,
            value: _controller.state.selectedStateCode,
            valueOf: (item) => item.code,
            labelOf: (item) => item.name,
            onChanged: _controller.state.saving
                ? null
                : _controller.selectState,
            validator: (value) =>
                value == null ? 'Selecciona tu estado.' : null,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          DropdownButtonFormField<String>(
            initialValue: _controller.state.selectedMunicipalityCode,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Municipio',
              prefixIcon: const Icon(Icons.location_city_outlined),
              suffixIcon: _controller.state.loadingMunicipalities
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            items: _controller.state.municipalities
                .map(
                  (item) => DropdownMenuItem(
                    value: item.code,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged:
                _controller.state.loadingMunicipalities ||
                    _controller.state.saving
                ? null
                : _controller.selectMunicipality,
            validator: (value) =>
                value == null ? 'Selecciona tu municipio.' : null,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cobertura: ${_controller.state.serviceRadiusKm} km',
                style: DogGoTheme.body(weight: FontWeight.w800),
              ),
              const SizedBox(height: DogGoSpacing.xs),
              Text(
                'Distancia máxima desde tu zona para recibir solicitudes.',
                style: DogGoTheme.subtitle(size: 12.5),
              ),
              Slider(
                value: _controller.state.serviceRadiusKm.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                label: '${_controller.state.serviceRadiusKm} km',
                onChanged: _controller.state.saving
                    ? null
                    : _controller.setServiceRadius,
              ),
            ],
          ),
          if (_controller.state.locatingCoverage) ...[
            const SizedBox(height: DogGoSpacing.sm),
            const LinearProgressIndicator(),
            const SizedBox(height: DogGoSpacing.sm),
            Text(
              'Ubicando el municipio en el mapa...',
              style: DogGoTheme.subtitle(size: 12),
            ),
          ] else if (_controller.state.latitude != null &&
              _controller.state.longitude != null) ...[
            const SizedBox(height: DogGoSpacing.md),
            WalkerCoverageMap(
              latitude: _controller.state.latitude!,
              longitude: _controller.state.longitude!,
              radiusKm: _controller.state.serviceRadiusKm,
              onCenterChanged: (point) {
                _controller.setCoverageCenter(point.latitude, point.longitude);
              },
            ),
            const SizedBox(height: DogGoSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: DogGoTheme.teal,
                ),
                const SizedBox(width: DogGoSpacing.sm),
                Expanded(
                  child: Text(
                    'Toca el mapa para mover el centro. El círculo muestra dónde recibirás solicitudes.',
                    style: DogGoTheme.subtitle(size: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: DogGoSpacing.fieldGap),
          _WalkerField(
            controller: _controller.rateController,
            label: 'Tarifa por hora',
            hint: 'Ejemplo: 120',
            icon: Icons.payments_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: _controller.validateRate,
            prefixText: '\$ ',
            suffixText: 'MXN',
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _WalkerField(
            controller: _controller.experienceController,
            label: 'Años de experiencia',
            hint: 'Ejemplo: 2',
            icon: Icons.workspace_premium_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: _controller.validateExperience,
            suffixText: 'años',
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(EditWalkerProfileState state) {
    return _WalkerCard(
      title: 'Disponibilidad',
      subtitle: 'Indica si actualmente puedes recibir solicitudes.',
      icon: Icons.event_available_outlined,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: state.available,
            onChanged: state.saving ? null : _controller.setAvailable,
            secondary: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: state.available
                    ? DogGoTheme.greenLight
                    : DogGoTheme.redLight,
                borderRadius: BorderRadius.circular(DogGoRadius.medium),
              ),
              child: Icon(
                state.available
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: state.available ? DogGoTheme.green : DogGoTheme.red,
              ),
            ),
            title: Text(
              state.available ? 'Disponible para paseos' : 'No disponible',
              style: DogGoTheme.body(weight: FontWeight.w800),
            ),
            subtitle: Text(
              state.available
                  ? 'Los dueños podrán encontrarte.'
                  : 'Tu perfil permanecerá visible, pero pausado.',
              style: DogGoTheme.subtitle(size: 12),
            ),
          ),
          const Divider(height: DogGoSpacing.largeGap),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.saving
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AvailabilityScreen(),
                      ),
                    ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Configurar días y horarios'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _WalkerCard({
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
                  color: DogGoTheme.purpleLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: DogGoTheme.purple, size: 22),
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

class _WalkerPhoto extends StatelessWidget {
  final File? selectedPhoto;
  final String? currentPhotoUrl;

  const _WalkerPhoto({
    required this.selectedPhoto,
    required this.currentPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 126,
        height: 126,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DogGoTheme.purpleLight,
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
        errorBuilder: (_, _, _) {
          return const _WalkerPlaceholder();
        },
      );
    }

    final url = currentPhotoUrl?.trim();

    if (url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return DogGoNetworkImage(
        url: url,
        semanticLabel: 'Fotografía profesional del paseador',
        fallback: const _WalkerPlaceholder(),
      );
    }

    return const _WalkerPlaceholder();
  }
}

class _WalkerPlaceholder extends StatelessWidget {
  const _WalkerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person_rounded, color: DogGoTheme.purple, size: 64);
  }
}

class _WalkerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final int minLines;
  final int maxLines;
  final String? prefixText;
  final String? suffixText;

  const _WalkerField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    required this.validator,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.prefixText,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixText: prefixText,
        suffixText: suffixText,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 52 : 0),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoOption({
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
                color: DogGoTheme.purpleLight,
                borderRadius: BorderRadius.circular(DogGoRadius.medium),
              ),
              child: Icon(icon, color: DogGoTheme.purple),
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
