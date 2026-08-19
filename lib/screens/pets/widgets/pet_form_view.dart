import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/doggo_error_view.dart';
import '../../../shared/widgets/doggo_loading_view.dart';
import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_spacing.dart';
import '../../../theme/doggo_theme.dart';
import '../pet_form_controller.dart';
import '../pet_form_state.dart';

class PetFormView extends StatefulWidget {
  final PetFormController controller;

  const PetFormView({super.key, required this.controller});

  @override
  State<PetFormView> createState() => _PetFormViewState();
}

class _PetFormViewState extends State<PetFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _validationEnabled = false;

  PetFormController get _controller => widget.controller;

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

  Future<void> _showPhotoOptions() async {
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
                  'Fotografía de la mascota',
                  style: DogGoTheme.title(size: 21),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  'Elige una fotografía clara y reciente.',
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

    final result = await _controller.save();

    if (!mounted) return;

    _showMessage(result.message, error: !result.success);

    if (!result.success) return;

    await Future<void>.delayed(const Duration(milliseconds: 650));

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
              title: Text(state.screenTitle),
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

  Widget _buildBody(PetFormState state) {
    if (state.loading) {
      return const DogGoLoadingView(message: 'Preparando formulario...');
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
          _buildIntroduction(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildPhotoCard(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildInformationCard(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildPersonalityCard(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildSocialCard(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildSafetyCard(state),
          const SizedBox(height: DogGoSpacing.lg),
          SizedBox(
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
                  : Icon(
                      state.isCreating
                          ? Icons.add_rounded
                          : Icons.save_outlined,
                    ),
              label: Text(state.saving ? 'Guardando...' : state.saveButtonText),
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          SizedBox(
            height: 50,
            child: TextButton(
              onPressed: state.saving
                  ? null
                  : () {
                      Navigator.pop(context, false);
                    },
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroduction(PetFormState state) {
    return Container(
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.teal.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(DogGoRadius.medium),
            ),
            child: Icon(
              state.isCreating
                  ? Icons.add_circle_outline_rounded
                  : Icons.pets_outlined,
              color: DogGoTheme.teal,
              size: 27,
            ),
          ),
          const SizedBox(width: DogGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isCreating ? 'Nueva mascota' : 'Actualiza sus datos',
                  style: DogGoTheme.title(size: 19),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  state.isCreating
                      ? 'Registra la información necesaria antes de solicitar su primer paseo.'
                      : 'Mantén sus datos al día para que el paseador reciba información correcta.',
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(PetFormState state) {
    return _FormCard(
      title: 'Fotografía',
      subtitle: 'Una imagen reciente ayuda a identificarla.',
      icon: Icons.photo_camera_outlined,
      child: Column(
        children: [
          _PetPhoto(
            selectedPhoto: state.selectedPhoto,
            currentPhotoUrl: state.currentPhotoUrl,
          ),
          const SizedBox(height: DogGoSpacing.md),
          OutlinedButton.icon(
            onPressed: state.saving ? null : _showPhotoOptions,
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
          const SizedBox(height: DogGoSpacing.sm),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: DogGoSpacing.sm),
            leading: const Icon(Icons.link_rounded, color: DogGoTheme.muted),
            title: Text(
              'Usar enlace de imagen',
              style: DogGoTheme.body(size: 13, color: DogGoTheme.muted),
            ),
            subtitle: Text('Opción avanzada', style: DogGoTheme.caption()),
            children: [
              TextFormField(
                controller: _controller.photoUrlController,
                enabled: state.selectedPhoto == null && !state.saving,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                validator: _controller.validatePhotoUrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección de imagen',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(PetFormState state) {
    return _FormCard(
      title: 'Información general',
      subtitle: 'Datos que serán visibles en sus paseos.',
      icon: Icons.pets_outlined,
      child: Column(
        children: [
          _PetField(
            controller: _controller.nameController,
            label: 'Nombre',
            hint: 'Nombre de tu mascota',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: _controller.validateName,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _PetField(
            controller: _controller.breedController,
            label: 'Raza',
            hint: 'Ejemplo: Golden Retriever',
            icon: Icons.category_outlined,
            textInputAction: TextInputAction.next,
            validator: _controller.validateBreed,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _PetField(
            controller: _controller.ageController,
            label: 'Edad',
            hint: 'Edad en años',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: _controller.validateAge,
            suffixText: 'años',
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _PetField(
            controller: _controller.weightController,
            label: 'Peso (opcional)',
            hint: 'Ejemplo: 12.5',
            icon: Icons.monitor_weight_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: _controller.validateWeight,
            suffixText: 'kg',
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          DropdownButtonFormField<String>(
            initialValue: state.selectedSize,
            decoration: const InputDecoration(
              labelText: 'Tamaño',
              prefixIcon: Icon(Icons.straighten_rounded),
            ),
            items: PetFormState.availableSizes
                .map((size) {
                  return DropdownMenuItem<String>(
                    value: size,
                    child: Text(size),
                  );
                })
                .toList(growable: false),
            onChanged: state.saving ? null : _controller.setSize,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _PetField(
            controller: _controller.notesController,
            label: 'Notas y cuidados',
            hint: 'Comportamiento, alergias o indicaciones importantes',
            icon: Icons.notes_outlined,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            validator: _controller.validateNotes,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityCard(PetFormState state) {
    return _FormCard(
      title: 'Personalidad y paseo',
      subtitle: 'Ayuda al paseador a saber qué esperar.',
      icon: Icons.psychology_alt_outlined,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: state.selectedSex,
            decoration: const InputDecoration(
              labelText: 'Sexo',
              prefixIcon: Icon(Icons.pets_outlined),
            ),
            items: PetFormState.availableSexes
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: state.saving ? null : _controller.setSex,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _PetField(
            controller: _controller.temperamentController,
            label: 'Temperamento',
            hint: 'Ejemplo: tranquilo, curioso y cariñoso',
            icon: Icons.sentiment_satisfied_alt_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          DropdownButtonFormField<String>(
            initialValue: state.selectedEnergyLevel,
            decoration: const InputDecoration(
              labelText: 'Nivel de energía',
              prefixIcon: Icon(Icons.bolt_rounded),
            ),
            items: PetFormState.availableEnergyLevels
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: state.saving ? null : _controller.setEnergyLevel,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          DropdownButtonFormField<String>(
            initialValue: state.selectedLeashBehavior,
            decoration: const InputDecoration(
              labelText: 'Comportamiento con correa',
              prefixIcon: Icon(Icons.route_outlined),
            ),
            items: PetFormState.availableLeashBehaviors
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: state.saving ? null : _controller.setLeashBehavior,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ThreeWayChoice(
            label: '¿Está esterilizado?',
            value: state.sterilized,
            onChanged: _controller.setSterilized,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard(PetFormState state) {
    return _FormCard(
      title: 'Convivencia',
      subtitle: 'Indica cómo suele relacionarse.',
      icon: Icons.groups_2_outlined,
      child: Column(
        children: [
          _ThreeWayChoice(
            label: 'Convive con otros perros',
            value: state.socialWithDogs,
            onChanged: _controller.setSocialWithDogs,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ThreeWayChoice(
            label: 'Convive con personas',
            value: state.socialWithPeople,
            onChanged: _controller.setSocialWithPeople,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ThreeWayChoice(
            label: 'Convive con niños',
            value: state.socialWithChildren,
            onChanged: _controller.setSocialWithChildren,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(PetFormState state) {
    return _FormCard(
      title: 'Seguridad',
      subtitle: 'Datos importantes antes de salir.',
      icon: Icons.health_and_safety_outlined,
      child: Column(
        children: [
          _ThreeWayChoice(
            label: '¿Puede reaccionar ante algún estímulo?',
            value: state.reactive,
            onChanged: _controller.setReactive,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _ThreeWayChoice(
            label: '¿Tiene riesgo de escapar?',
            value: state.escapeRisk,
            onChanged: _controller.setEscapeRisk,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _PetField(
            controller: _controller.fearsController,
            label: 'Miedos o detonantes',
            hint: 'Ruidos, bicicletas, otros perros...',
            icon: Icons.warning_amber_rounded,
            textInputAction: TextInputAction.next,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _PetField(
            controller: _controller.commandsController,
            label: 'Comandos conocidos',
            hint: 'Sentado, quieto, ven...',
            icon: Icons.record_voice_over_outlined,
            textInputAction: TextInputAction.newline,
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _ThreeWayChoice extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _ThreeWayChoice({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DogGoTheme.body(size: 13.5, weight: FontWeight.w700),
        ),
        const SizedBox(height: DogGoSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Sí'),
              selected: value == true,
              onSelected: (_) => onChanged(true),
            ),
            ChoiceChip(
              label: const Text('No'),
              selected: value == false,
              onSelected: (_) => onChanged(false),
            ),
            ChoiceChip(
              label: const Text('No lo sé'),
              selected: value == null,
              onSelected: (_) => onChanged(null),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _FormCard({
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

class _PetPhoto extends StatelessWidget {
  final File? selectedPhoto;
  final String? currentPhotoUrl;

  const _PetPhoto({required this.selectedPhoto, required this.currentPhotoUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 132,
        height: 132,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DogGoTheme.tealLight,
          borderRadius: BorderRadius.circular(DogGoRadius.large),
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
        errorBuilder: (_, _, _) {
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
    return const Icon(Icons.pets_rounded, color: DogGoTheme.teal, size: 58);
  }
}

class _PetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final String? suffixText;

  const _PetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    this.keyboardType,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
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
        suffixText: suffixText,
        alignLabelWithHint: maxLines > 1,
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
